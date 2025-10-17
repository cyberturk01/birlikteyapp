import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/cloud_error_handler.dart'; // varsa
import '../services/offline_queue.dart'; // varsa
import '../services/retry.dart'; // varsa

class LocationCloudProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  LocationCloudProvider(this._auth, this._db);

  // ---- state
  String? _familyId;
  StreamSubscription<Position>? _posSub;
  DateTime? _lastWriteAt;
  bool _isSharing = false; // kullanıcı toggle'ı
  bool _permissionGranted = false; // son kontrol sonucu
  Position? _lastPosition;
  Position? _lastWritten;

  // Throttle ayarları
  Duration minInterval = const Duration(seconds: 20);
  double minDistanceMeters = 25; // bu kadar oynamadan yazma

  String? get familyId => _familyId;
  bool get isSharing => _isSharing;
  bool get permissionGranted => _permissionGranted;
  Position? get lastPosition => _lastPosition;
  DateTime? get lastWriteAt => _lastWriteAt;

  // ---- lifecycle
  Future<void> setFamilyId(String? fid) async {
    if (_familyId == fid) return;
    _familyId = fid;
    // family değişirse aktif paylaşımı kesme; sadece doc path değişir.
    notifyListeners();
  }

  Future<void> shareOnce() async {
    if (!await _ensurePermission()) {
      throw StateError('Konum izni yok veya servis kapalı.');
    }
    final uid = _auth.currentUser?.uid;
    final fid = _familyId;

    if (uid == null || fid == null || fid.isEmpty) {
      throw StateError('Not signed in or no family selected');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      ),
    );

    await _upsert(uid: uid, fid: fid, pos: pos);

    _lastWriteAt = DateTime.now();
    _lastPosition = pos;
  }

  Future<void> _upsert({
    required String uid,
    required String fid,
    required Position pos,
  }) async {
    final ref = _db.collection('families/$fid/locations').doc(uid);
    await ref.set({
      'uid': uid,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'speed': pos.speed,
      'heading': pos.heading,
      'updatedAt': FieldValue.serverTimestamp(),
      'isSharing': true,
      'source': 'shareOnce', // ek bilgi
    }, SetOptions(merge: true));
    _lastWriteAt = DateTime.now();
    _lastWritten = pos;
  }

  Future<void> teardown() async {
    await stopSharing();
    _familyId = null;
    _lastPosition = null;
    _lastWriteAt = null;
    _isSharing = false;
    notifyListeners();
  }

  // ---- permission helpers
  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionGranted = false;
      notifyListeners();
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      throw StateError('Location permission is denied');
    }
    final granted =
        perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
    _permissionGranted = granted;
    notifyListeners();
    return granted;
  }

  Future<void> _ensurePermissionOrExplain(BuildContext context) async {
    final t = _t(context);
    if (!await Geolocator.isLocationServiceEnabled()) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(t.locServiceOffTitle),
              content: Text(t.locServiceOffBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(t.actionOpen),
                ),
              ],
            ),
          ) ??
          false;
      if (ok) await Geolocator.openLocationSettings();
      throw StateError('Location services disabled');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(t.locPermTitle),
              content: Text(t.locPermBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(t.actionOpenSettings),
                ),
              ],
            ),
          ) ??
          false;
      if (ok) await ph.openAppSettings();
      throw StateError(t.permissionDeniedForever);
    }
  }

  AppLocalizations _t(BuildContext? ctx) {
    // context aktif mi?
    final alive = (ctx is Element) && ctx.mounted;
    final safeCtx = alive ? ctx : navigatorKey.currentContext;
    // Son çare: İngilizce fallback (kütüphanende varsa)
    return AppLocalizations.of(safeCtx!)!;
  }

  // ---- public API
  Future<void> setSharing(bool value) async {
    if (value == _isSharing) return;
    if (value) {
      await startSharing();
    } else {
      await stopSharing();
    }
  }

  Future<void> startSharing() async {
    if (_isSharing) return;
    if ((_familyId ?? '').isEmpty) {
      CloudErrorHandler.showFromString('Aile seçili değil.');
      return;
    }
    if (_auth.currentUser == null) {
      CloudErrorHandler.showFromString('Oturum yok.');
      return;
    }

    try {
      if (!await _ensurePermission()) {
        CloudErrorHandler.showFromString('Konum izni yok veya servis kapalı.');
        return;
      }

      // Harita 'isSharing:true' filtresine takılmasın diye bayrağı erken yaz.
      await _writeFlagOnly(isSharing: true);

      // 1) Son bilinen konum (genelde hemen gelir)
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        await _maybeWrite(last);
        _lastPosition = last;
      }

      // 2) Güncel konum (kısa timeout)
      try {
        final first = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 10),
          ),
        );
        await _maybeWrite(first);
        _lastPosition = first;
      } on TimeoutException {
        // GPS fix gelmezse akış yine başlar; sorun değil
      }

      // 3) Akış
      final settings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 50,
      );
      await _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        _onPosition,
        onError: (e, st) {
          CloudErrorHandler.showFromException(e);
        },
      );

      _isSharing = true;
      notifyListeners();
    } catch (e, st) {
      _isSharing = false;
      notifyListeners();
      CloudErrorHandler.showFromException(e);
      debugPrint('startSharing failed: $e\n$st'); // asıl hatayı consola yaz
    }
  }

  Future<void> stopSharing() async {
    await _posSub?.cancel();
    _posSub = null;
    _isSharing = false;
    notifyListeners();
    // Firestore'da isSharing=false güncelle (opsiyonel)
    await _writeFlagOnly(isSharing: false);
  }

  // ---- internals
  Future<void> _onPosition(Position pos) async {
    final prevPos = _lastPosition; // önce eskiyi al
    final now = DateTime.now();

    // zaman eşiği
    if (_lastWriteAt != null && now.difference(_lastWriteAt!) < minInterval) {
      return;
    }

    // mesafe eşiği
    if (prevPos != null) {
      final moved = _distanceMeters(prevPos, pos);
      if (moved < minDistanceMeters) return;
    }

    await _maybeWrite(pos);

    // yazımdan sonra güncelle
    _lastPosition = pos;
    _lastWriteAt = DateTime.now();
    notifyListeners();
  }

  double _distanceMeters(Position a, Position b) {
    // basit Haversine
    const earth = 6371000.0;
    final dLat = (b.latitude - a.latitude) * (3.1415926535 / 180.0);
    final dLon = (b.longitude - a.longitude) * (3.1415926535 / 180.0);
    final la1 = a.latitude * (3.1415926535 / 180.0);
    final la2 = b.latitude * (3.1415926535 / 180.0);

    final sinDLat = (dLat / 2).sin;
    final sinDLon = (dLon / 2).sin;
    final h = sinDLat * sinDLat + sinDLon * sinDLon * la1.cos * la2.cos;
    final c = 2 * h.sqrt.asin;
    return earth * c;
  }

  Future<void> startSharingWithUi(BuildContext context) async {
    final t = _t(context);

    try {
      await _ensurePermissionOrExplain(context); // dialogları da içeriyor
    } on StateError catch (e) {
      // kullanıcı iptal ettiyse sessiz geç
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? t.errUnknown)));
      return;
    }

    try {
      await startSharing();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.locSharingStarted)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.errUnknown)));
    }
  }

  Future<void> stopSharingWithUi(BuildContext context) async {
    final t = _t(context);
    try {
      await stopSharing();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.locSharingStopped)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.errUnknown)));
    }
  }
}

extension on double {
  double get sin => MathHelper.sin(this);
  double get cos => MathHelper.cos(this);
  double get sqrt => MathHelper.sqrt(this);
  double get asin => MathHelper.asin(this);
}

/// Küçük trig helper (dart:math sarmalayıcı)
class MathHelper {
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static double sqrt(double x) => math.sqrt(x);
  static double asin(double x) => math.asin(x);
}

extension _Writer on LocationCloudProvider {
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('families/$_familyId/locations');

  String get _uid => _auth.currentUser!.uid;

  Future<void> _maybeWrite(Position pos) async {
    _lastWriteAt = DateTime.now();

    final doc = _col.doc(_uid);
    final data = <String, dynamic>{
      'uid': _uid,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'updatedAt': FieldValue.serverTimestamp(),
      'isSharing': true,
      'source': 'geolocator',
    };

    await (() async {
      try {
        await _db.collection('families/$_familyId/locations_history').add({
          'uid': _uid,
          'lat': pos.latitude,
          'lng': pos.longitude,
          'accuracy': pos.accuracy,
          'createdAt': FieldValue.serverTimestamp(),
          'expireAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
        });
      } catch (e, st) {
        debugPrint('history write failed: $e');
        return null;
      }
    })();

    Future<void> write() async => doc.set(data, SetOptions(merge: true));
    final queueData = Map<String, dynamic>.from(data);
    queueData.remove('updatedAt');
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (e) {
      CloudErrorHandler.showFromException(e);
      debugPrint('[LOC] write failed, queueing: $e');

      final queued = Map<String, dynamic>.from(data);
      queued.remove('updatedAt');

      await OfflineQueue.I.enqueue(
        OfflineOp(
          id: _uuid.v4(),
          path: doc.path,
          type: OpType.set,
          data: queued,
          merge: true,
        ),
      );
    }
  }

  Future<void> _writeFlagOnly({required bool isSharing}) async {
    if ((_familyId ?? '').isEmpty || _auth.currentUser == null) return;
    final doc = _col.doc(_uid);
    await doc.set({'isSharing': isSharing}, SetOptions(merge: true));
  }
}
