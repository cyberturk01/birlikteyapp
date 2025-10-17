import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_cloud_provider.dart';
import '../../utils/marker_icon.dart';
import '../../widgets/debug_menu.dart';

enum BannerKind { none, perm, live, autoOff, stale, stopped }

class LocationsPage extends StatefulWidget {
  final String familyId;
  const LocationsPage({super.key, required this.familyId});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  String? _filteredUid;
  final _controller = Completer<GoogleMapController>();
  BannerKind _currentBanner = BannerKind.none;
  bool _fitted = false;
  final Map<String, BitmapDescriptor> _iconCache = {};
  final BitmapDescriptor _defaultIcon = BitmapDescriptor.defaultMarker;
  MarkerId _mkId(String uid) => MarkerId('${widget.familyId}::$uid');
  final Set<String> _lastMarkerIds = {};

  CameraPosition _initialCam = const CameraPosition(
    target: LatLng(51.1657, 10.4515), // Germany fallback
    zoom: 6,
  );

  @override
  void initState() {
    super.initState();
    _primeInitialCamera();

    // Start/Stop butonunun doğru çalışması için provider'a familyId verelim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LocationCloudProvider>().setFamilyId(widget.familyId);
    });
  }

  Future<void> _primeInitialCamera() async {
    try {
      // 1) Son bilinen konum (genelde hemen gelir)
      final last = await Geolocator.getLastKnownPosition();
      if (mounted && last != null) {
        setState(() {
          _initialCam = CameraPosition(
            target: LatLng(last.latitude, last.longitude),
            zoom: 15,
          );
        });
      }

      // 2) Daha iyi fix için timeout'lu current
      final cur = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted && cur != null) {
        setState(() {
          _initialCam = CameraPosition(
            target: LatLng(cur.latitude, cur.longitude),
            zoom: 16,
          );
        });
      }
    } catch (_) {
      // izin yoksa / timeout olduysa fallback'te kal
    }
  }

  Future<void> _goToUserIfNoMarkers() async {
    if (!_controller.isCompleted) return;
    try {
      // izinleri zaten paylaşım tarafında istemiştin; burada da güvenli tarafta kalalım
      final c = await _controller.future;
      // konum servisi açık/izin verilmişse al
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13),
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.menuMapTab),
        actions: [
          IconButton(
            tooltip: t.actionFitAll,
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () => setState(() => _fitted = false),
          ),
          const DebugMenu(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('families/${widget.familyId}/locations')
            .snapshots(includeMetadataChanges: true),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? const [];

          final entriesStream = context
              .watch<FamilyProvider>()
              .watchMemberEntries();
          return StreamBuilder<List<FamilyMemberEntry>>(
            stream: entriesStream,
            builder: (ctx2, entriesSnap) {
              final entries = entriesSnap.data ?? const <FamilyMemberEntry>[];
              final byUid = {for (final e in entries) e.uid: e};

              LatLngBounds? bounds;
              final markers = <Marker>{};

              for (final d in docs) {
                final data = d.data();
                final uid = (data['uid'] as String?) ?? d.id;

                final lat = (data['lat'] as num?)?.toDouble();
                final lng = (data['lng'] as num?)?.toDouble();
                if (lat == null || lng == null) continue;

                final ts = (data['updatedAt'] as Timestamp?)?.toDate();
                final isOn = data['isSharing'] == true;

                // 15 dk canlı eşiği
                final isLive =
                    isOn &&
                    ts != null &&
                    DateTime.now().difference(ts) <=
                        const Duration(minutes: 15);

                // “eski veri” eşiği – istersen 7 gün yerine 24 saat yap
                final isFresh =
                    ts != null &&
                    DateTime.now().difference(ts) <= const Duration(days: 7);

                if (!isLive && !isFresh) {
                  continue;
                }

                final entry = byUid[uid];
                final title = entry?.label ?? uid;
                final photoUrl = entry?.photoUrl;

                final pal = MarkerIconHelper.paletteFor(uid, dimmed: !isLive);
                final accent = pal.accent; // yazı/avatar kenarı rengi
                final bubble = pal.bubble; // balon arka plan rengi

                if (!isFresh && ts == null) continue;

                final pos = LatLng(lat, lng);
                final cacheKey =
                    '$uid|$photoUrl|$title|${accent.value}|${bubble.value}|$isLive';

                final cached = _iconCache[cacheKey];

                markers.add(
                  Marker(
                    markerId: _mkId(uid),
                    position: pos,
                    icon: cached ?? _defaultIcon,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: ts == null
                          ? t.lastSeenUnknown
                          : '${_lastSeenL10n(t, ts)}${isLive ? ' • (live)' : ''}',
                    ),
                  ),
                );

                MarkerIconHelper.getOrCreate(
                  uid: uid,
                  label: title,
                  photoUrl: photoUrl,
                  color: accent,
                  bubbleBg: bubble,
                  logicalWidth: 180,
                  logicalHeight: 72,
                  fontSize: 16,
                ).then((bmp) {
                  if (!mounted) return;
                  _iconCache[cacheKey] = bmp;
                  setState(() {});
                });

                bounds = _extend(bounds, pos);
              }
              _lastMarkerIds
                ..clear()
                ..addAll(markers.map((m) => m.markerId.value));
              final meUid = FirebaseAuth.instance.currentUser?.uid;
              Map<String, dynamic>? myLoc; // benim kaydımın data'sı
              if (meUid != null) {
                for (final d in docs) {
                  final data = d.data();
                  final uid = (data['uid'] as String?) ?? d.id;
                  if (_filteredUid != null && _filteredUid != uid) continue;
                  if (uid == meUid) {
                    myLoc = data;
                    break;
                  }
                }

                // build sırasında show/hide banner çağrısı için post-frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (myLoc == null) return;
                  _maybeShowStatusBanner(context, myLoc);
                });
              }
              _fitOnce(bounds, markers.length);
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCam,
                    markers: markers,
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                    padding: const EdgeInsets.only(
                      top: 76,
                    ), // üstteki buton için boşluk
                    onMapCreated: (c) async {
                      if (!_controller.isCompleted) _controller.complete(c);
                      await Future.delayed(const Duration(milliseconds: 60));
                      await _fitOnce(bounds, markers.length);

                      if (markers.length == 1) {
                        final p = markers.first.position;
                        (await _controller.future).animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: p, zoom: 16),
                          ),
                        );
                      }
                      if (markers.isEmpty) {
                        await _goToUserIfNoMarkers();
                      }
                    },
                  ),
                  // 🔴 Start/Stop düğmesi
                  Positioned(
                    top: 26,
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      child: Consumer<LocationCloudProvider>(
                        builder: (context, loc, _) {
                          final isOn = loc.isSharing;
                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOn
                                  ? Colors.red.shade400
                                  : Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: Icon(isOn ? Icons.stop : Icons.play_arrow),
                            label: Text(
                              isOn ? t.actionStopSharing : t.actionStartSharing,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              final loc = context.read<LocationCloudProvider>();
                              try {
                                if (isOn) {
                                  await loc.stopSharingWithUi(context);
                                } else {
                                  await loc.startSharingWithUi(context);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                final t =
                                    AppLocalizations.of(context) ??
                                    AppLocalizations.of(
                                      navigatorKey.currentContext!,
                                    )!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.errUnknown)),
                                );
                              }
                            },
                            onLongPress: () async {
                              // Uzun bas: tek seferlik paylaşım
                              final loc = context.read<LocationCloudProvider>();
                              try {
                                await loc.shareOnce();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.sharedOnceOk)),
                                );
                              } on StateError catch (e) {
                                if (!context.mounted) return;
                                final msg = e.message ?? t.errUnknown;
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.sharedOnceFail)),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    top: 84,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: docs.map((d) {
                            final data = d.data();
                            final uid = data['uid'] ?? d.id;
                            final title = byUid[uid]?.label ?? uid;
                            final ts = (data['updatedAt'] as Timestamp?)
                                ?.toDate();
                            final isOn = data['isSharing'] == true;
                            final isLiveForChip =
                                isOn &&
                                ts != null &&
                                DateTime.now().difference(ts) <=
                                    const Duration(minutes: 15);

                            final pal = MarkerIconHelper.paletteFor(
                              uid,
                              dimmed: !isLiveForChip,
                            );
                            final chipColor = pal.accent;
                            final bg = pal.bubble;

                            final last = ts == null ? 'never' : _fmtLast(t, ts);

                            // Üye çipleri (butonun altında) — chip builder içinde:
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final lat = (data['lat'] as num?)?.toDouble();
                                  final lng = (data['lng'] as num?)?.toDouble();
                                  if (lat == null || lng == null) return;

                                  final target = LatLng(lat, lng);
                                  final c = await _controller.future;

                                  await c.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(target: target, zoom: 16),
                                    ),
                                  );

                                  await _safeShowInfo(uid);
                                  final markerId = _mkId(uid);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) async {
                                    try {
                                      await Future.delayed(
                                        const Duration(milliseconds: 50),
                                      );
                                      (await _controller.future)
                                          .showMarkerInfoWindow(markerId);
                                    } catch (_) {
                                      // marker o an yoksa sessiz geç
                                    }
                                  });
                                },
                                onLongPress: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (_filteredUid == uid) {
                                      _filteredUid = null;
                                    } else {
                                      _filteredUid = uid;
                                      _fitted = false;
                                    }
                                  });
                                },

                                child: Chip(
                                  backgroundColor: bg,
                                  avatar: CircleAvatar(
                                    backgroundColor: chipColor,
                                    child: Text(
                                      title.isNotEmpty
                                          ? title[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  label: Text(
                                    '$title • $last',
                                    style: TextStyle(
                                      color: chipColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 26,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'centerMeBtn',
                      backgroundColor: Colors.blue.shade600,
                      onPressed:
                          _goToUserIfNoMarkers, // zaten var olan fonksiyon
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _safeShowInfo(String uid) async {
    if (!_controller.isCompleted) return;

    final fullId = _mkId(uid).value;
    if (!_lastMarkerIds.contains(fullId)) return;

    final c = await _controller.future;

    // build’ler tamamlansın
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    if (!_lastMarkerIds.contains(fullId)) return;

    try {
      c.showMarkerInfoWindow(_mkId(uid));
    } catch (_) {
      // sessizce yut
    }
  }

  Future<void> _fitOnce(LatLngBounds? b, int markerCount) async {
    if (_fitted || !_controller.isCompleted) return;
    final c = await _controller.future;
    try {
      if (b != null && markerCount >= 2) {
        await c.animateCamera(CameraUpdate.newLatLngBounds(b, 60));
      } else if (b != null && markerCount == 1) {
        // tek marker: çok fazla zoom yapma, 12 civarı iyi
        final center = LatLng(
          (b.northeast.latitude + b.southwest.latitude) / 2,
          (b.northeast.longitude + b.southwest.longitude) / 2,
        );
        await c.animateCamera(CameraUpdate.newLatLngZoom(center, 16));
      }
      _fitted = true;
    } catch (_) {}
  }

  LatLngBounds _extend(LatLngBounds? b, LatLng p) {
    if (b == null) return LatLngBounds(southwest: p, northeast: p);
    final sw = LatLng(
      b.southwest.latitude < p.latitude ? b.southwest.latitude : p.latitude,
      b.southwest.longitude < p.longitude ? b.southwest.longitude : p.longitude,
    );
    final ne = LatLng(
      b.northeast.latitude > p.latitude ? b.northeast.latitude : p.latitude,
      b.northeast.longitude > p.longitude ? b.northeast.longitude : p.longitude,
    );
    return LatLngBounds(southwest: sw, northeast: ne);
  }

  String _lastSeenL10n(AppLocalizations t, DateTime? t0) {
    if (t0 == null) return t.lastSeenUnknown;
    final d = DateTime.now().difference(t0);
    if (d.inSeconds < 60) return t.lastSeenJustNow;
    if (d.inMinutes < 60) return t.lastSeenMinutes(d.inMinutes);
    if (d.inHours < 24) return t.lastSeenHours(d.inHours);
    return t.lastSeenDays(d.inDays);
  }

  void _showBannerOnce(
    ScaffoldMessengerState messenger,
    BannerKind kind,
    MaterialBanner banner,
  ) {
    if (_currentBanner == kind) return; // aynıysa tekrar göstermeyelim
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(banner);
    _currentBanner = kind;
  }

  String _fmtLast(AppLocalizations t, DateTime t0) {
    final d = DateTime.now().difference(t0);
    if (d.inMinutes < 1) return t.chipAgoNow;
    if (d.inHours < 1) return t.chipAgoMinutes(d.inMinutes);
    if (d.inHours < 24) return t.chipAgoHours(d.inHours);
    return t.chipAgoDays(d.inDays);
  }

  void _maybeShowStatusBanner(
    BuildContext context,
    Map<String, dynamic>? myLoc,
  ) {
    final t =
        AppLocalizations.of(context) ??
        AppLocalizations.of(navigatorKey.currentContext!)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner(); // önce mevcut varsa kapat

    final locProv = context.read<LocationCloudProvider>();

    // 1) İzin yoksa
    if (!locProv.permissionGranted) {
      _showBannerOnce(
        messenger,
        BannerKind.perm,
        MaterialBanner(
          backgroundColor: Colors.orange.shade700,
          content: Text(
            t.bannerPermNeededBody,
            style: const TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.location_off, color: Colors.white),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _currentBanner = BannerKind.none;
              },
              child: Text(
                t.actionDismiss,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                await locProv.startSharingWithUi(context);
                messenger.hideCurrentMaterialBanner();
                _currentBanner = BannerKind.none;
              },
              child: Text(
                t.actionEnable,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2) Kendi konum kaydına göre durumlar
    final ts = (myLoc?['updatedAt'] as Timestamp?)?.toDate();
    final isSharing = myLoc?['isSharing'] == true;
    final now = DateTime.now();

    // helper
    bool olderThan(Duration d) => ts != null && now.difference(ts) > d;
    bool within(Duration d) => ts != null && now.difference(ts) <= d;

    if (olderThan(const Duration(minutes: 15)) &&
        (ts != null && now.difference(ts) <= const Duration(days: 7))) {
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: Colors.blueGrey.shade700,
          content: Text(
            t.bannerAutoOffBody,
            style: const TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.timer_off, color: Colors.white),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: Text(
                t.actionDismiss,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => locProv.startSharingWithUi(context),
              child: Text(
                t.actionTurnOn,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // c) Çok eski (7 günü geçmiş) → gizlenmiş olabilir / “stale”
    if (olderThan(const Duration(days: 7))) {
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: Colors.grey.shade800,
          content: Text(
            t.bannerStaleBody,
            style: const TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.history, color: Colors.white),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: Text(
                t.actionDismiss,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => locProv.startSharingWithUi(context),
              child: Text(
                t.actionShareNow,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }
  }
}
