import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconHelper {
  // basit cache: label|color|dpr -> icon
  static final Map<String, BitmapDescriptor> _cache = {};

  /// DPI-aware, kuyruklu, gölgeli marker
  static Future<BitmapDescriptor> createCustomMarker(
    BuildContext context,
    String label, {
    Color color = Colors.blue,
    double logicalWidth = 160, // mantıksal ölçü (dp)
    double logicalHeight = 64, // dp
    double fontSize = 18, // dp
  }) async {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheKey =
        '${label}_${color.value}_${dpr}_${logicalWidth}x$logicalHeight';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    // Mantıksal ölçüler → fiziksel piksel
    final widthPx = (logicalWidth * dpr).round();
    final heightPx = (logicalHeight * dpr).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Mantıksal birimlerle çizebilmek için ölçekle
    canvas.scale(dpr);

    // Boyutlar (mantıksal)
    final w = logicalWidth;
    final h = logicalHeight;
    final radius = 14.0;
    final tailH = 14.0; // alt kuyruk yüksekliği
    final totalH = h + tailH;

    // Gölge
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(radius),
    );
    final shadowPath = Path()
      ..addRRect(rrect)
      ..moveTo(w / 2 - 10, h) // kuyruk
      ..lineTo(w / 2, h + tailH)
      ..lineTo(w / 2 + 10, h)
      ..close();
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.5), 6.0, true);

    // Gövde
    final bubblePaint = Paint()..color = color;
    canvas.drawRRect(rrect, bubblePaint);

    // Kuyruk
    final tailPath = Path()
      ..moveTo(w / 2 - 10, h)
      ..lineTo(w / 2, h + tailH)
      ..lineTo(w / 2 + 10, h)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);

    // Metin (ellipsis + tek satır)
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          shadows: const [
            Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(0, 0)),
          ],
        ),
      ),
    );
    // solda küçük padding
    const padH = 14.0;
    const padV = 12.0;
    tp.layout(maxWidth: w - padH * 2);
    tp.paint(canvas, const Offset(padH, padV));

    // Bitir
    final picture = recorder.endRecording();
    // totalH mantıksal → fiziksel px
    final img = await picture.toImage(widthPx, (totalH * dpr).round());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());

    _cache[cacheKey] = icon;
    return icon;
  }
}

// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// class MarkerIconHelper {
//   static final Map<String, BitmapDescriptor> _cache = {};
//
//   static Future<BitmapDescriptor> createCustomMarker(
//     String label, {
//     Color color = Colors.blue,
//   }) async {
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     final paint = Paint()..color = color;
//     const w = 120.0, h = 50.0, r = 12.0;
//
//     final rect = RRect.fromRectAndRadius(
//       Rect.fromLTWH(0, 0, w, h),
//       const Radius.circular(r),
//     );
//     canvas.drawRRect(rect, paint);
//
//     final textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//       text: TextSpan(
//         text: label,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//     textPainter.layout(maxWidth: w - 20);
//     textPainter.paint(canvas, const Offset(10, 12));
//
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(w.toInt(), h.toInt());
//     final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
//     return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
//   }
// }
