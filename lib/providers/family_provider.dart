import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

class FamilyProvider extends ChangeNotifier {
  final _familyBox = Hive.box<String>('familyBox');
  String? _familyId;
  String? get familyId => _familyId;

  final List<String> _labelsCache = const [];
  List<String> get familyMembers => _labelsCache;
  static const _kActiveFamilyKey = 'activeFamilyId';
  static const _kOwnerUidKey = 'activeFamilyOwnerUid';

  FamilyProvider() {
    FirebaseAuth.instance.authStateChanges().listen((u) async {
      // Kullanıcı tamamen çıktıysa temizle
      if (u == null) {
        _familyId = null;
        await _familyBox.delete(_kActiveFamilyKey);
        await _familyBox.delete(_kOwnerUidKey);
        notifyListeners();
      } else {
        // Hesap değiştiyse yerel kayıt başka kullanıcıya ait olabilir
        final localOwner = _familyBox.get(_kOwnerUidKey);
        if (localOwner != u.uid) {
          await _familyBox.delete(_kActiveFamilyKey);
          await _familyBox.put(_kOwnerUidKey, u.uid);
          _familyId = null;
          notifyListeners();
        }
      }
    });
  }
  // Güvenli getter (UI “assign” dropdown’ları için pratik)
  List<String> get memberLabelsOrFallback {
    if (_labelsCache.isNotEmpty) return _labelsCache;
    final me = FirebaseAuth.instance.currentUser;
    final my = 'You (${(me?.email ?? 'me').split('@').first})';
    return [my];
  }

  /// UID -> Label sözlüğü yayar.
  /// Örn: { "uid123": "You (Gökhan)", "uid456": "Ayşe" }
  Stream<Map<String, String>> watchMemberDirectory() {
    final famId = _familyId;
    if (famId == null || famId.isEmpty) {
      return Stream.value(const <String, String>{});
    }

    final me = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            // family silindiyse local temizleyebilirsin ama burada notify etme
            return <String, String>{};
          }

          final data = doc.data() ?? {};
          final members = (data['members'] as Map<String, dynamic>? ?? {});
          final namesMap = (data['memberNames'] as Map<String, dynamic>? ?? {});
          final uids = members.keys.toList()..sort();

          final map = <String, String>{};
          for (final uid in uids) {
            final nm = (namesMap[uid] as String?)?.trim();
            final base = (nm != null && nm.isNotEmpty)
                ? nm
                : 'Member • ${uid.substring(0, 6)}';

            if (uid == me?.uid) {
              map[uid] = 'You ($base)';
            } else {
              map[uid] = base;
            }
          }
          return map;
        })
        // gereksiz rebuild'leri engelle
        .distinct((a, b) {
          if (a.length != b.length) return false;
          for (final k in a.keys) {
            if (!b.containsKey(k) || b[k] != a[k]) return false;
          }
          return true;
        });
  }

  Future<String?> ensureInviteCode() async {
    final id = _familyId;
    if (id == null) return null;

    // var olan kodu oku
    final doc = await FirebaseFirestore.instance
        .collection('families')
        .doc(id)
        .get();
    var code = (doc.data()?['inviteCode'] as String?)?.trim();

    // yoksa yeni üret ve yaz
    if (code == null || code.isEmpty) {
      code = _randomCode(length: 8);
      await FirebaseFirestore.instance.collection('invites').doc(code).set({
        'familyId': id,
        'ownerUid': FirebaseAuth.instance.currentUser!.uid,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('families').doc(id).set({
        'inviteCode': code,
      }, SetOptions(merge: true));
    }
    return code;
  }

  Future<void> shareInvite(BuildContext context) async {
    final code = await ensureInviteCode();
    if (code == null) return;
    final text = 'Join our Togetherly family with code: $code';
    await Clipboard.setData(ClipboardData(text: code));
    await Share.share(text, subject: 'Togetherly invite');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied to clipboard: $code')));
  }

  Future<void> setInviteActive(bool active) async {
    final fid = _familyId;
    if (fid == null) return;
    final famDoc = await FirebaseFirestore.instance
        .collection('families')
        .doc(fid)
        .get();
    final code = (famDoc.data()?['inviteCode'] as String?)?.trim();
    if (code == null || code.isEmpty) return;
    await FirebaseFirestore.instance.collection('invites').doc(code).set({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> loadActiveFamily() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _familyId = null;
        notifyListeners();
        return;
      }

      // 1) Yerelde ve aynı kullanıcıya aitse kullan
      final localOwner = _familyBox.get(_kOwnerUidKey);
      final localFam = _familyBox.get(_kActiveFamilyKey);
      if (localOwner == uid && (localFam != null && localFam.isNotEmpty)) {
        _familyId = localFam;
        notifyListeners();
        return;
      }

      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // 2) SERVER
      try {
        final s = await usersRef.get(const GetOptions(source: Source.server));
        final cloud = (s.data()?['activeFamilyId'] as String?)?.trim();
        if (cloud != null && cloud.isNotEmpty) {
          if (await _amIMemberOf(cloud)) {
            await _persistActive(cloud, ownerUid: uid);
            return;
          } else {
            // Ben üye değilim → temizle
            await _familyBox.delete(_kActiveFamilyKey);
          }
        }
      } catch (_) {}

      // 3) CACHE
      try {
        final c = await usersRef.get(const GetOptions(source: Source.cache));
        final cloud = (c.data()?['activeFamilyId'] as String?)?.trim();
        if (cloud != null && cloud.isNotEmpty) {
          await _persistActive(cloud, ownerUid: uid);
          return;
        }
      } catch (_) {}

      // aktif aile yok → onboarding aksın
      _familyId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('loadActiveFamily error: $e');
      _familyId = null;
      notifyListeners();
    }
  }

  // FamilyProvider.createFamily
  // FamilyProvider.createFamily (YENİ)
  Future<void> createFamily(String name) async {
    if ((_familyId ?? '').isNotEmpty) return;

    final u = FirebaseAuth.instance.currentUser!;
    final uid = u.uid;
    final db = FirebaseFirestore.instance;
    final display = await _preferredDisplayName();

    final nameLower = name.trim().toLowerCase();
    final famRef = db.collection('families').doc(); // yeni familyId
    final userRef = db.collection('users').doc(uid);
    final code = _randomCode(length: 8);

    // 🔹 1) İsmi rezerve et (AYRI yazım, batch/txn içinde DEĞİL)
    final reserveRef = db.doc('family_names/$nameLower');
    await reserveRef.set({
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      // 🔹 2) Asıl yazımlar (tek batch)
      final batch = db.batch();

      // families/{fid}
      batch.set(famRef, {
        'name': name.trim(),
        'nameLower': nameLower,
        'ownerUid': uid,
        'members': {uid: 'owner'},
        'memberNames': {uid: display},
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      // users/{uid}
      batch.set(userRef, {
        'families': FieldValue.arrayUnion([famRef.id]),
        'activeFamilyId': famRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // invites/{CODE}  👉 doc id = code (kurallarda GET ile bakacağız)
      final inviteRef = db.collection('invites').doc(code);
      batch.set(inviteRef, {
        'familyId': famRef.id,
        'ownerUid': uid,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      await batch.commit();

      // 🔹 3) Lokal persist
      await _persistActive(famRef.id, ownerUid: uid);
    } catch (e) {
      // 🔹 4) Rollback (rezervasyonu sil)
      await reserveRef.delete().catchError((_) {});
      rethrow;
    }
  }

  // FamilyProvider.joinWithCode (YENİ)
  Future<bool> joinWithCode(String raw) async {
    final u = FirebaseAuth.instance.currentUser!;
    final uid = u.uid;
    final db = FirebaseFirestore.instance;
    final display = await _preferredDisplayName();

    final code = raw.trim().toUpperCase();
    final inviteRef = db.collection('invites').doc(code);
    final inviteSnap = await inviteRef.get();

    DocumentReference<Map<String, dynamic>>? famRef;

    if (inviteSnap.exists) {
      final data = inviteSnap.data()!;
      final famId = data['familyId'] as String?;
      final active = data['active'] as bool? ?? true;
      if (!active || famId == null || famId.isEmpty) return false;
      famRef = db.collection('families').doc(famId);
    } else {
      // (Geridönük uyumluluk) Eski mantık: families içinde inviteCode alanı
      final q = await db
          .collection('families')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return false;
      famRef = q.docs.first.reference;
    }

    final userRef = db.collection('users').doc(uid);

    final batch = db.batch();
    batch.set(famRef, {
      'members': {uid: 'editor'},
      'memberNames': {uid: display},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'families': FieldValue.arrayUnion([famRef.id]),
      'activeFamilyId': famRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    await _persistActive(famRef.id, ownerUid: uid);
    return true;
  }

  void clearActive() {
    _familyId = null;
    // varsa lokal cache/stream temizlikleri
    notifyListeners();
  }

  Future<void> _persistActive(String id, {required String ownerUid}) async {
    // ❗ aynı id ise hiçbir şey yapma
    if (_familyId == id &&
        _familyBox.get(_kActiveFamilyKey) == id &&
        _familyBox.get(_kOwnerUidKey) == ownerUid) {
      return;
    }

    _familyId = id;
    await _familyBox.put(_kActiveFamilyKey, id);
    await _familyBox.put(_kOwnerUidKey, ownerUid);
    debugPrint('persistActive: $id');
    notifyListeners();
  }

  Future<void> adoptActiveFromCloud(String famId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!await _amIMemberOf(famId)) return;
    await _persistActive(famId, ownerUid: uid);
  }

  Future<bool> amIOwner() async {
    final fid = _familyId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (fid == null || uid == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('families')
        .doc(fid)
        .get();
    return (doc.data()?['ownerUid'] == uid);
  }

  Future<bool> _amIMemberOf(String famId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('families')
          .doc(famId)
          .get();
      if (!snap.exists) return false;
      final m = (snap.data()?['members'] as Map<String, dynamic>? ?? {});
      return m.containsKey(uid);
    } catch (e) {
      return false;
    }
  }

  Stream<List<String>> watchMemberNames() {
    final famId = _familyId;
    if (famId == null || famId.isEmpty) {
      // familyId gelene kadar boş liste akıt
      return Stream.value(const <String>[]);
    }

    return FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) return <String>[];
          // Firestore’daki yapı: members: { uid: "owner" | "editor" ... }
          // Şimdilik isim olarak UID’leri gösterelim (ileride profile isimleri ekleriz).
          final membersMap = (data['members'] as Map<String, dynamic>? ?? {});
          final uids = membersMap.keys.map((e) => e.toString()).toList();
          uids.sort();
          return uids;
        });
  }

  String _randomCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rng;
    try {
      rng = Random.secure();
    } catch (_) {
      rng = Random();
    }
    return List.generate(
      length,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }

  /// Ham label: families.memberNames[uid] varsa onu döner.
  /// Yoksa users/{uid}.displayName -> email local-part -> 'Member • xxxxxx'
  Future<String> getRawLabelFor(String uid) async {
    final famId = _familyId;
    if (famId == null) return '';
    final db = FirebaseFirestore.instance;

    // family
    final fam = await db.collection('families').doc(famId).get();
    final names = (fam.data()?['memberNames'] as Map<String, dynamic>? ?? {});
    final fromFam = (names[uid] as String?)?.trim();
    if (fromFam != null && fromFam.isNotEmpty) return fromFam;

    // users
    final u = await db.collection('users').doc(uid).get();
    final dn = (u.data()?['displayName'] as String?)?.trim();
    if (dn != null && dn.isNotEmpty) return dn;

    final email = (u.data()?['email'] as String?) ?? '';
    if (email.contains('@')) return email.split('@').first;

    return 'Member • ${uid.substring(0, 6)}';
  }

  Future<bool> isFamilyNameTaken(String raw) async {
    final nameLower = raw.trim().toLowerCase();
    final doc = await FirebaseFirestore.instance
        .doc('family_names/$nameLower')
        .get();
    return doc.exists;
  }

  Future<List<String>> suggestFamilyNames(String base, {int limit = 5}) async {
    final tried = <String>{};
    final out = <String>[];
    String clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

    final root = clean(base);
    final candidates = <String>[
      root,
      '$root Family',
      '$root House',
      '$root Home',
      '$root ${DateTime.now().year}',
      '$root 👨‍👩‍👧‍👦',
      '$root 🏡',
      // sayısal kuyruklar:
      ...List.generate(50, (i) => '$root ${i + 1}'),
    ];

    for (final cand in candidates) {
      if (tried.contains(cand.toLowerCase())) continue;
      tried.add(cand.toLowerCase());
      if (!await isFamilyNameTaken(cand)) {
        out.add(cand);
        if (out.length >= limit) break;
      }
    }
    // her ihtimale karşı; hiç boş kalmasın
    if (out.isEmpty) {
      out.addAll([
        root,
        '$root ${DateTime.now().millisecondsSinceEpoch % 1000}',
      ]);
    }
    return out;
  }

  Future<String?> getInviteCode() async {
    final id = _familyId;
    if (id == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('families')
        .doc(id)
        .get();
    return (doc.data()?['inviteCode'] as String?)?.trim();
  }

  Future<String> _preferredDisplayName() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return 'Member';
    // 1) Auth displayName
    final dn = (u.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    // 2) users/{uid}.displayName
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get(const GetOptions(source: Source.server));
      final fromUsers = (doc.data()?['displayName'] as String?)?.trim();
      if (fromUsers != null && fromUsers.isNotEmpty) return fromUsers;
    } catch (_) {}

    // 3) email local-part
    final emailLocal = (u.email ?? '').split('@').first;
    return emailLocal.isNotEmpty ? emailLocal : 'Member';
  }

  // (opsiyonel) local isim listesi eski kalabilir, şimdilik bırakıyorum:
  void addMember(String name) {
    _familyBox.add(name);
    notifyListeners();
  }

  void removeMember(int index) {
    _familyBox.deleteAt(index);
    notifyListeners();
  }

  void renameMember({required int index, required String newName}) {
    _familyBox.putAt(index, newName);
    notifyListeners();
  }

  Stream<List<FamilyMemberEntry>> watchMemberEntries() {
    final famId = _familyId;
    if (famId == null || famId.isEmpty) {
      return Stream.value(const <FamilyMemberEntry>[]);
    }

    final me = FirebaseAuth.instance.currentUser;
    final myLabel = 'You (${(me?.email ?? 'me').split('@').first})';

    return FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <FamilyMemberEntry>[];
          final data = doc.data() ?? {};
          final members = (data['members'] as Map<String, dynamic>? ?? {});
          final names = (data['memberNames'] as Map<String, dynamic>? ?? {});
          final photos = (data['memberPhotos'] as Map<String, dynamic>? ?? {});
          final uids = members.keys.toList()..sort();

          final list = <FamilyMemberEntry>[];
          for (final uid in uids) {
            final role = (members[uid] as String?) ?? 'editor';
            String label;
            if (uid == me?.uid) {
              label = myLabel;
            } else {
              final nm = (names[uid] as String?)?.trim();
              label = (nm != null && nm.isNotEmpty)
                  ? nm
                  : 'Member • ${uid.substring(0, 6)}';
            }
            final photoUrl = (photos[uid] as String?)?.trim();
            list.add(
              FamilyMemberEntry(
                uid: uid,
                label: label,
                role: role,
                photoUrl: photoUrl,
              ),
            );
          }
          return list;
        });
  }

  Future<String> setMemberPhoto({
    required String memberUid,
    required File file,
  }) async {
    final fid = _familyId;
    if (fid == null) throw StateError('No active family');

    final ref = FirebaseStorage.instance.ref(
      'families/$fid/members/$memberUid.jpg',
    );

    // İstersen kaliteyi düşürülmüş/yeniden boyutlandırılmış dosya verebilirsin
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('families').doc(fid).set({
      'memberPhotos': {memberUid: url},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    notifyListeners(); // UI hızlıca güncellensin
    return url;
  }

  /// İsteğe bağlı: foto kaldır
  Future<void> removeMemberPhoto(String memberUid) async {
    final fid = _familyId;
    if (fid == null) return;
    // Storage'tan da silmek istersen:
    try {
      await FirebaseStorage.instance
          .ref('families/$fid/members/$memberUid.jpg')
          .delete();
    } catch (_) {}
    await FirebaseFirestore.instance.collection('families').doc(fid).set({
      'memberPhotos': {memberUid: FieldValue.delete()},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    notifyListeners();
  }

  /// Sadece bu ailede görünen etiketi değiştirir (memberNames[uid])
  Future<void> updateMemberLabel(String uid, String newLabel) async {
    final famId = _familyId;
    if (famId == null) return;
    await FirebaseFirestore.instance.collection('families').doc(famId).set({
      'memberNames': {uid: newLabel.trim()},
    }, SetOptions(merge: true));
  }

  /// Üyeyi aileden çıkar (sahip kendini ya da owner’ı silemesin)
  Future<void> removeMemberFromFamily(String uid) async {
    final famId = _familyId;
    if (famId == null) return;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final ref = FirebaseFirestore.instance.collection('families').doc(famId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final ownerUid = data['ownerUid'] as String?;
    if (uid == ownerUid) {
      throw StateError('Owner cannot be removed');
    }
    if (uid == me) {
      throw StateError('You cannot remove yourself');
    }

    await ref.set({
      'members': {uid: FieldValue.delete()},
      'memberNames': {uid: FieldValue.delete()},
    }, SetOptions(merge: true));
  }

  /// (İsteğe bağlı) davet kodunu gösterip kopyalamak için zaten getInviteCode() var.
}

Future<void> removeMemberFromFamilyAndFixAssignments({
  required String familyId,
  required String memberUid,
  required String memberLabelText, // "nuran" ya da "You (nuran)"
  ReassignStrategy strategy = ReassignStrategy.leaveAsText,
  String? reassignToLabel, // "You (gokhan)" gibi
}) async {
  final db = FirebaseFirestore.instance;

  // 1) Aile dokümanında üyeyi ve görünen adını sil
  final famRef = db.doc('families/$familyId');
  final famSnap = await famRef.get();
  if (!famSnap.exists) return;

  final batch1 = db.batch();
  batch1.update(famRef, {
    'members.$memberUid': FieldValue.delete(),
    'memberNames.$memberUid': FieldValue.delete(), // <-- memberLabels değil
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await batch1.commit();

  // 2) Kullanıcının user dokümanı: families array’inden bu aileyi çıkar,
  //    activeFamilyId bu aile ise temizle (koşullu).
  final userRef = db.doc('users/$memberUid');
  await db.runTransaction((txn) async {
    final uSnap = await txn.get(userRef);
    if (!uSnap.exists) return;
    final data = uSnap.data() as Map<String, dynamic>;
    final active = (data['activeFamilyId'] as String?) ?? '';
    final updates = <String, dynamic>{
      'families': FieldValue.arrayRemove([familyId]),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (active == familyId) {
      // temizle; istersen null da verebilirsin
      updates['activeFamilyId'] = FieldValue.delete();
    }
    txn.set(userRef, updates, SetOptions(merge: true));
  });

  // 3) (Opsiyonel) görev & market atamalarını düzelt
  if (strategy != ReassignStrategy.leaveAsText) {
    bool matchesLabel(String s) {
      if (s == memberLabelText) return true;
      // "You (xxx)" <-> "xxx" simetrik eşleşme
      final re = RegExp(r'^You \((.+)\)$');
      final m1 = re.firstMatch(s);
      final m2 = re.firstMatch(memberLabelText);
      if (m1 != null && m1.group(1) == memberLabelText) return true;
      if (m2 != null && m2.group(1) == s) return true;
      return false;
    }

    // küçük batch’lerle yaz (500 limitini aşmamak için)
    Future<void> _fixCol(String col, String field) async {
      final snap = await db.collection('families/$familyId/$col').get();
      var writes = db.batch();
      var count = 0;
      for (final d in snap.docs) {
        final m = d.data();
        final at = (m[field] as String?)?.trim() ?? '';
        if (at.isEmpty) continue;
        if (!matchesLabel(at)) continue;

        String? newVal;
        switch (strategy) {
          case ReassignStrategy.unassign:
            newVal = null;
            break;
          case ReassignStrategy.reassignTo:
            newVal = reassignToLabel; // "You (gokhan)" gibi
            break;
          case ReassignStrategy.leaveAsText:
            newVal = at;
            break;
        }
        writes.update(d.reference, {field: newVal});
        count++;
        if (count % 400 == 0) {
          // güvenli sınır
          await writes.commit();
          writes = db.batch();
        }
      }
      await writes.commit();
    }

    await _fixCol('tasks', 'assignedTo');
    await _fixCol('items', 'assignedTo');
  }
}

enum ReassignStrategy { unassign, reassignTo, leaveAsText }

class FamilyMemberEntry {
  final String uid;
  final String label;
  final String role; // 'owner' / 'editor' vs.
  final String? photoUrl;
  const FamilyMemberEntry({
    required this.uid,
    required this.label,
    required this.role,
    this.photoUrl,
  });
}
