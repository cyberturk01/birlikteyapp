// lib/utils/marker_icon.dart
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconHelper {
  static const int _maxEntries = 64;

  // Erişimde sona taşımak için LinkedHashMap
  static final LinkedHashMap<String, BitmapDescriptor> _cache =
      LinkedHashMap<String, BitmapDescriptor>();
  static final Map<String, Future<BitmapDescriptor>> _pending = {};

  static String _key({
    required String uid,
    required String label,
    String? photoUrl,
    required Color color,
    required Color bubbleBg,
    required double logicalWidth,
    required double logicalHeight,
    required double fontSize,
  }) {
    return '$uid|${photoUrl ?? ""}|$label|${color.value}|${bubbleBg.value}|$logicalWidth|$logicalHeight|$fontSize';
  }

  static Future<BitmapDescriptor> getOrCreate({
    required String uid,
    required String label,
    String? photoUrl,
    Color color = Colors.blue,
    Color bubbleBg = Colors.white,
    double logicalWidth = 200,
    double logicalHeight = 90,
    double fontSize = 16,
  }) {
    final key = _key(
      uid: uid,
      label: label,
      photoUrl: photoUrl,
      color: color,
      bubbleBg: bubbleBg,
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
      fontSize: fontSize,
    );

    // LRU: hit → sona taşı
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return Future.value(hit);
    }

    final pend = _pending[key];
    if (pend != null) return pend;

    final fut =
        createProfileMarker(
              uid: uid,
              label: label,
              photoUrl: photoUrl,
              color: color,
              bubbleBg: bubbleBg,
              logicalWidth: logicalWidth,
              logicalHeight: logicalHeight,
              fontSize: fontSize,
            )
            .then((bmp) {
              _insertLru(key, bmp);
              _pending.remove(key);
              return bmp;
            })
            .catchError((e) {
              _pending.remove(key);
              throw e;
            });

    _pending[key] = fut;
    return fut;
  }

  static void _insertLru(String key, BitmapDescriptor bmp) {
    _cache[key] = bmp;
    if (_cache.length > _maxEntries) {
      // ilk eklenen (en az kullanılan) → remove
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  static Future<BitmapDescriptor> createProfileMarker({
    required String uid,
    required String label,
    String? photoUrl,
    Color color = Colors.blue,
    Color bubbleBg = Colors.white,
    double logicalWidth = 200,
    double logicalHeight = 90,
    double fontSize = 16,
  }) async {
    final key = _key(
      uid: uid,
      label: label,
      photoUrl: photoUrl,
      color: color,
      bubbleBg: bubbleBg,
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
      fontSize: fontSize,
    );
    final cached = _cache.remove(key);
    if (cached != null) {
      // LRU: hit → sona taşı
      _cache[key] = cached;
      return cached;
    }

    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);

    final paint = Paint()..isAntiAlias = true;
    final w = logicalWidth;
    final h = logicalHeight;
    const avatarSize = 48.0;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h - 10),
      const Radius.circular(16),
    );
    paint.color = bubbleBg;
    canvas.drawRRect(bgRect, paint);

    final tip = Path()
      ..moveTo(w / 2 - 8, h - 10)
      ..lineTo(w / 2 + 8, h - 10)
      ..lineTo(w / 2, h)
      ..close();
    canvas.drawPath(tip, paint);

    final avatarRect = const Rect.fromLTWH(8, 8, avatarSize, avatarSize);
    paint.color = color;
    canvas.drawCircle(avatarRect.center, avatarSize / 2, paint);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(photoUrl);
        final bundle = NetworkAssetBundle(uri);
        final bytes = await bundle.load(uri.toString());
        final img = await decodeImageFromList(bytes.buffer.asUint8List());
        final clip = Path()..addOval(avatarRect);
        canvas.save();
        canvas.clipPath(clip);
        final src = Rect.fromLTWH(
          0,
          0,
          img.width.toDouble(),
          img.height.toDouble(),
        );
        canvas.drawImageRect(img, src, avatarRect, Paint());
        canvas.restore();
      } catch (_) {
        _drawInitial(canvas, avatarRect, label);
      }
    } else {
      _drawInitial(canvas, avatarRect, label);
    }

    final name = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    )..layout(maxWidth: w - avatarSize - 24);
    name.paint(
      canvas,
      Offset(avatarRect.right + 12, (h - name.height) / 2 - 6),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage((w * dpr).toInt(), (h * dpr).toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final bmp = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());

    _insertLru(key, bmp);
    return bmp;
  }

  static void _drawInitial(Canvas canvas, Rect avatarRect, String label) {
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    )..layout();
    tp.paint(
      canvas,
      Offset(
        avatarRect.center.dx - tp.width / 2,
        avatarRect.center.dy - tp.height / 2,
      ),
    );
  }

  static const List<Color> _basePalette = [
    Color(0xFF1F77B4), // mavi
    Color(0xFFFF7F0E), // turuncu
    Color(0xFF2CA02C), // yeşil
    Color(0xFFD62728), // kırmızı
    Color(0xFF9467BD), // mor
    Color(0xFF8C564B), // kahverengi
    Color(0xFFE377C2), // pembe
    Color(0xFF7F7F7F), // gri
    Color(0xFFBCBD22), // zeytin
    Color(0xFF17BECF), // camgöbeği
    Color(0xFF00ACC1), // mavi-yeşil
    Color(0xFF5E35B1), // lacivert-mor
  ];

  static Color colorFromUid(String uid) {
    // Tutarlı index: uid hash → palette index
    final idx = uid.hashCode.abs() % _basePalette.length;
    return _basePalette[idx];
  }

  // Kullanıcıdan tutarlı iki renk üret (canlı + yumuşak ton)
  static ({Color accent, Color bubble}) paletteFor(
    String uid, {
    bool dimmed = false,
  }) {
    final base = colorFromUid(uid);
    final hsl = HSLColor.fromColor(base);

    final accent = hsl
        .withSaturation(dimmed ? 0.25 : 0.70)
        .withLightness(dimmed ? 0.60 : 0.45)
        .toColor();
    // bubble: açık arka plan
    final bubble = hsl
        .withSaturation(dimmed ? 0.20 : 0.30)
        .withLightness(dimmed ? 0.90 : 0.80)
        .toColor();
    return (accent: accent, bubble: bubble);
  }
}
