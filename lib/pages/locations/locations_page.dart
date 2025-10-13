import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';
import '../../providers/location_cloud_provider.dart';
import '../../utils/marker_icon.dart';

class LocationsPage extends StatefulWidget {
  final String familyId;
  const LocationsPage({super.key, required this.familyId});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final _controller = Completer<GoogleMapController>();
  bool _fitted = false;
  final Map<String, BitmapDescriptor> _iconCache = {};
  final BitmapDescriptor _defaultIcon = BitmapDescriptor.defaultMarker;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Locations'),
        actions: [
          IconButton(
            tooltip: 'Fit all',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () => setState(() => _fitted = false),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('families/${widget.familyId}/locations')
            .snapshots(),
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

                // “eski veri” eşiği – istersen 7 gün yerine 24 saat yap
                final isFresh =
                    ts != null &&
                    DateTime.now().difference(ts) <= const Duration(days: 7);

                // 🔴 eski ve paylaşım kapalı ise hiç gösterme
                if (!isOn && !isFresh) continue;

                final entry = byUid[uid];
                final title = entry?.label ?? uid;
                final photoUrl = entry?.photoUrl;

                // Paylaşım kapalıysa gri; açıksa kullanıcı rengi
                final pal = MarkerIconHelper.paletteFor(uid, dimmed: !isOn);
                final accent = pal.accent; // yazı/avatar kenarı rengi
                final bubble = pal.bubble; // balon arka plan rengi

                if (lat == null || lng == null) continue;
                if (!isFresh && ts == null) continue;

                final pos = LatLng(lat, lng);
                final cacheKey = '$uid|$photoUrl|$title|${accent.value}|$isOn';

                final cached = _iconCache[cacheKey];
                if (cached == null) {
                  MarkerIconHelper.createProfileMarker(
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
                    setState(() {}); // ikon hazır → marker güncellensin
                  });
                }

                markers.add(
                  Marker(
                    markerId: MarkerId(uid),
                    position: pos,
                    icon:
                        cached ??
                        _defaultIcon, // ilk turda default, sonra cache
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: ts == null
                          ? 'last seen: unknown'
                          : 'last seen: ${_lastSeen(ts)}${isOn ? ' (live)' : ''}',
                    ),
                  ),
                );

                bounds = _extend(bounds, pos);
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
                      top: 96,
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
                  // ✅ Üye çipleri (butonun altında)
                  Positioned(
                    top: 72,
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

                            final pal = MarkerIconHelper.paletteFor(
                              uid,
                              dimmed: !isOn,
                            );
                            final chipColor = pal.accent;
                            final bg = pal.bubble;

                            final last = ts == null ? 'never' : _fmtLast(ts);

                            // Üye çipleri (butonun altında) — chip builder içinde:
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  // 1) Koordinatları al
                                  final lat = (data['lat'] as num?)?.toDouble();
                                  final lng = (data['lng'] as num?)?.toDouble();
                                  if (lat == null || lng == null) return;

                                  final target = LatLng(lat, lng);

                                  // 2) Kamera animasyonu
                                  final c = await _controller.future;
                                  await c.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(target: target, zoom: 16),
                                    ),
                                  );

                                  // 3) Marker infoWindow’u aç (plugin destekliyorsa)
                                  // GoogleMapController.showMarkerInfoWindow(MarkerId) mevcutsa çalışır.
                                  Future.delayed(
                                    const Duration(milliseconds: 150),
                                    () {
                                      c.showMarkerInfoWindow(MarkerId(uid));
                                    },
                                  );
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
                  // 🔴 Start/Stop düğmesi
                  Positioned(
                    top: 16,
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
                              isOn ? 'Stop Sharing' : 'Start Sharing',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              try {
                                if (isOn) {
                                  await context
                                      .read<LocationCloudProvider>()
                                      .stopSharing();
                                } else {
                                  await context
                                      .read<LocationCloudProvider>()
                                      .startSharing();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  final msg = e is StateError
                                      ? (e.message ?? '$e')
                                      : '$e';
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(msg)));
                                }
                              }
                            },
                          );
                        },
                      ),
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

  String _lastSeen(DateTime? t) {
    if (t == null) return 'last seen: unknown';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'last seen: just now';
    if (diff.inMinutes < 60) return 'last seen: ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'last seen: ${diff.inHours} h ago';
    return 'last seen: ${diff.inDays} d ago';
  }

  String _fmtLast(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
