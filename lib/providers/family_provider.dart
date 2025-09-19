import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FamilyProvider extends ChangeNotifier {
  final _familyBox = Hive.box<String>('familyBox');
  String? _familyId;
  String? get familyId => _familyId;

  List<String> _labelsCache = const [];
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
          await _persistActive(cloud, ownerUid: uid);
          return;
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
    await _persistActive(famId, ownerUid: uid);
  }

  Stream<List<String>> watchMemberDisplayNames() {
    final famId = _familyId;
    if (famId == null || famId.isEmpty) return Stream.value(const []);

    final me = FirebaseAuth.instance.currentUser;

    // family doc değiştikçe uid listesi çıkar → users sorgularına zincirle
    return FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .snapshots()
        .asyncMap((snap) async {
          if (!snap.exists) {
            _familyId = null;
            await _familyBox.delete(_kActiveFamilyKey);
            notifyListeners();
            return <String>[];
          }
          final data = snap.data() ?? {};
          final membersMap = (data['members'] as Map<String, dynamic>? ?? {});
          final uids = membersMap.keys.map((e) => e.toString()).toList();
          if (uids.isEmpty) return <String>[];

          // 10'arlı parça
          final chunks = <List<String>>[];
          for (var i = 0; i < uids.length; i += 10) {
            chunks.add(uids.sublist(i, (i + 10).clamp(0, uids.length)));
          }

          // her chunk için users whereIn
          final db = FirebaseFirestore.instance;
          final futures = chunks.map((part) {
            return db
                .collection('users')
                .where(FieldPath.documentId, whereIn: part)
                .get();
          }).toList();
          final results = await Future.wait(futures);

          // uid -> displayName haritası
          final Map<String, String> names = {};
          for (final qs in results) {
            for (final d in qs.docs) {
              final dn = (d.data()['displayName'] as String?)?.trim();
              names[d.id] = (dn == null || dn.isEmpty)
                  ? (d.data()['email'] as String?)?.split('@').first ?? d.id
                  : dn;
            }
          }
          // listedeki sırayı bozmamak için uids üzerinden yürü
          final labels = <String>[];
          for (final uid in uids) {
            final base = names[uid] ?? 'Member';
            if (uid == me?.uid) {
              labels.add('You ($base)');
            } else {
              labels.add(base);
            }
          }

          _labelsCache = labels;
          notifyListeners();
          return labels;
        });
  }

  Stream<List<String>> watchMemberLabels() {
    final famId = _familyId;
    if (famId == null || famId.isEmpty) return Stream.value(const <String>[]);

    final me = FirebaseAuth.instance.currentUser;
    final myLabel = 'You (${(me?.email ?? 'me').split('@').first})';

    return FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            // family silinmiş → local temizle (ama burada notify etme)
            _familyId = null;
            _familyBox.delete(_kActiveFamilyKey);
            return <String>[];
          }

          final data = doc.data() ?? {};
          final members = (data['members'] as Map<String, dynamic>? ?? {});
          final namesMap = (data['memberNames'] as Map<String, dynamic>? ?? {});

          // UID’leri tekilleştir + sıralı
          final uids = members.keys.toSet().toList()..sort();

          // Etiketleri üret
          final labels = <String>[];
          for (final uid in uids) {
            final nm = (namesMap[uid] as String?)?.trim();
            final base = (nm != null && nm.isNotEmpty)
                ? nm
                : 'Member • ${uid.substring(0, 6)}';

            if (uid == me?.uid) {
              labels.add('You ($base)'); // <- artık memberNames’e bağlı
            } else {
              labels.add(base);
            }
          }

          // Cache’i sessiz güncelle
          _labelsCache = labels;
          return labels;
        })
        // Aynı liste tekrar gelirse StreamBuilder’ı boşuna tetikleme
        .distinct((a, b) {
          if (a.length != b.length) return false;
          for (var i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
          }
          return true;
        });
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
            list.add(FamilyMemberEntry(uid: uid, label: label, role: role));
          }
          return list;
        });
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

class FamilyMemberEntry {
  final String uid;
  final String
  label; // ekranda görünen (You (..), ya da memberNames[uid] / fallback)
  final String role; // 'owner' / 'editor' vs.
  const FamilyMemberEntry({
    required this.uid,
    required this.label,
    required this.role,
  });
}
