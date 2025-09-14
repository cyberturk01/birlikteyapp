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
  Future<void> createFamily(String name) async {
    if ((_familyId ?? '').isNotEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    final famRef = db.collection('families').doc();
    final userRef = db.collection('users').doc(uid);
    final inviteRef = db.collection('invites').doc(); // eğer kullanıyorsan

    final code = _randomCode(length: 8);

    final batch = db.batch();
    batch.set(famRef, {
      'name': name,
      'nameLower': name.trim().toLowerCase(),
      'ownerUid': uid,
      'members': {uid: 'owner'},
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));

    batch.set(userRef, {
      'families': FieldValue.arrayUnion([famRef.id]),
      'activeFamilyId': famRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Eğer app bir yere gerçekten yazıyorsa (stack'te invites/H6SP9YCK görünüyor)
    batch.set(inviteRef, {
      'code': code,
      'familyId': famRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _persistActive(famRef.id, ownerUid: uid);
  }

  Future<bool> joinWithCode(String raw) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = raw.trim().toUpperCase();
    final db = FirebaseFirestore.instance;

    // invites koleksiyonunu gerçekten kullanıyorsan:
    final inviteSnap = await db
        .collection('invites')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    DocumentReference<Map<String, dynamic>> famRef;

    if (inviteSnap.docs.isNotEmpty) {
      // invite dokümanından familyId al
      final data = inviteSnap.docs.first.data();
      final famId = data['familyId'] as String?;
      if (famId == null || famId.isEmpty) return false;
      famRef = db.collection('families').doc(famId);
    } else {
      // eski mantık: families içinde inviteCode alanı
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
    // üyelik rolü merge
    batch.set(famRef, {
      'members': {uid: 'editor'},
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

  // Bunu çağıran yardımcı:
  Future<void> adoptActiveFromCloud(String famId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _persistActive(famId, ownerUid: uid);
  }
  // FamilyProvider içine ekle

  /// Aile üyelerinin GÖRÜNÜR isimlerini döner (users/{uid}.displayName).
  /// Kendi kullanıcını "You (displayName)" olarak etiketler.
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

  // FamilyProvider
  Stream<List<String>> watchMemberLabels() {
    final famId = _familyId;
    if (famId == null || famId.isEmpty) return Stream.value(const []);
    final me = FirebaseAuth.instance.currentUser;
    final myLabel = 'You (${(me?.email ?? 'me').split('@').first})';

    return FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            _familyId = null;
            _familyBox.delete(_kActiveFamilyKey);
            notifyListeners();
            return <String>[];
          }
          final data = doc.data() ?? {};
          final members = (data['members'] as Map<String, dynamic>? ?? {});
          final uids = members.keys.toList();
          final labels = uids.map((uid) {
            if (uid == me?.uid) return myLabel;
            return 'Member • ${uid.substring(0, 6)}';
          }).toList();

          _labelsCache = labels;
          return labels;
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

  Future<bool> isFamilyNameTaken(String name) async {
    final q = await FirebaseFirestore.instance
        .collection('families')
        .where('nameLower', isEqualTo: name.trim().toLowerCase())
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
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
}
