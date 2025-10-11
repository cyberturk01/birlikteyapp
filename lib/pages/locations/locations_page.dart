import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final dictStream = context.watch<FamilyProvider>().watchMemberDirectory();

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
          final markers = <Marker>{};

          return StreamBuilder<Map<String, String>>(
            stream: dictStream,
            builder: (ctx2, dictSnap) {
              final dict = dictSnap.data ?? const <String, String>{};

              LatLngBounds? bounds;
              for (final d in docs) {
                final data = d.data();
                final isSharing = data['isSharing'] as bool? ?? false;
                final updated = (data['updatedAt'] as Timestamp?)?.toDate();
                if (!isSharing && updated == null) continue;

                final lat = (data['lat'] as num?)?.toDouble();
                final lng = (data['lng'] as num?)?.toDouble();
                if (lat == null || lng == null) continue;

                final uid = data['uid'] as String? ?? d.id;
                final ts = (data['updatedAt'] as Timestamp?)?.toDate();
                final title = dict[uid] ?? uid;
                final subtitle = _lastSeen(ts);

                final pos = LatLng(lat, lng);
                markers.add(
                  Marker(
                    markerId: MarkerId(uid),
                    position: pos,
                    icon: _iconCache[uid] ?? _defaultIcon,
                    infoWindow: InfoWindow(title: title, snippet: subtitle),
                  ),
                );
                bounds = _extend(bounds, pos);
                if (!_iconCache.containsKey(uid)) {
                  _getIconFor(uid, title, Colors.green).then((_) {
                    if (!mounted) return;
                    setState(() {
                      // rebuild → markers aynı loop’ta yeniden üretileceği için
                      // _iconCache sayesinde bu sefer custom icon gelecektir.
                    });
                  });
                }
              }

              _fitOnce(bounds, markers.length);

              if (markers.isEmpty) {
                _goToUserIfNoMarkers();
              }

              return Stack(
                children: [
                  FloatingActionButton(
                    child: const Icon(Icons.my_location),
                    onPressed: () async {
                      try {
                        final p = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(
                            accuracy: LocationAccuracy.high,
                          ),
                        );
                        final c = await _controller.future;
                        await c.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(p.latitude, p.longitude),
                            13,
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  Positioned(
                    top: 72, // Start/Stop butonunun altına
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
                            final title = dict[uid] ?? uid;
                            final ts = (data['updatedAt'] as Timestamp?)
                                ?.toDate();
                            final lastSeen = ts == null
                                ? 'never'
                                : _fmtLast(ts);
                            final isOn = data['isSharing'] == true;
                            final color = isOn
                                ? Colors.green.shade600
                                : Colors.grey.shade500;

                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                backgroundColor: color.withOpacity(0.15),
                                avatar: CircleAvatar(
                                  backgroundColor: color,
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
                                  '$title • $lastSeen',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  GoogleMap(
                    initialCameraPosition: _initialCam,
                    markers: markers,
                    zoomControlsEnabled: true, // +/-
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    compassEnabled: true,
                    padding: const EdgeInsets.only(top: 96),
                    onMapCreated: (c) async {
                      if (!_controller.isCompleted) _controller.complete(c);
                      await Future.delayed(
                        const Duration(milliseconds: 60),
                      ); // harita hazır olsun
                      await _fitOnce(bounds, markers.length);
                      if (markers.length == 1) {
                        final p = markers.first.position;
                        (await _controller.future).animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: p, zoom: 13),
                          ),
                        );
                        return;
                      } else if (markers.length > 1) {
                        LatLngBounds? b;
                        for (final m in markers) {
                          b = _extend(b, m.position);
                        }
                        if (b != null) {
                          (await _controller.future).animateCamera(
                            CameraUpdate.newLatLngBounds(
                              b,
                              100,
                            ), // geniş padding
                          );
                          return;
                        }
                      }

                      try {
                        final last = await Geolocator.getLastKnownPosition();
                        if (last != null) {
                          final me = LatLng(last.latitude, last.longitude);
                          (await _controller.future).animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(target: me, zoom: 16),
                            ),
                          );
                        }
                      } catch (_) {
                        // izin yoksa/fail olursa fallback zaten Germany
                      }
                    },
                  ),
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
                                final msg = e is StateError
                                    ? (e.message ?? '$e')
                                    : '$e';
                                if (context.mounted) {
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

  Future<BitmapDescriptor> _getIconFor(
    String uid,
    String title,
    Color color,
  ) async {
    if (_iconCache.containsKey(uid)) return _iconCache[uid]!;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final color = uid == me ? Colors.deepPurple : Colors.green;
    final icon = await MarkerIconHelper.createCustomMarker(
      context,
      title, // chip’te gördüğün label
      color: color,
      logicalWidth: 180, // daha da büyük istersen artır
      logicalHeight: 72,
      fontSize: 20,
    );
    _iconCache[uid] = icon;
    return icon;
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
