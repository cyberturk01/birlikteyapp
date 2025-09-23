import 'dart:math';

import 'package:flutter/material.dart';

import '../providers/expense_cloud_provider.dart';

class ExpensesMiniSummary extends StatelessWidget {
  final List<ExpenseDoc> expenses;
  final VoidCallback? onTap; // tıklayınca Expenses sekmesine geçmek istersen
  final EdgeInsets padding;

  const ExpensesMiniSummary({
    super.key,
    required this.expenses,
    this.onTap,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _isSameDay;
    final startOfWeek = now.subtract(
      Duration(days: (now.weekday - DateTime.monday)),
    );
    final startOfMonth = DateTime(now.year, now.month, 1);

    num sumToday = 0;
    num sumWeek = 0;
    num sumMonth = 0;

    // son 14 gün sparkline verisi
    final days = List.generate(
      14,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 13 - i)),
    );
    final Map<DateTime, num> perDay = {
      for (final d in days) DateTime(d.year, d.month, d.day): 0,
    };

    for (final e in expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final amt = (e.amount is num) ? (e.amount as num) : 0;

      if (today(e.date, now)) sumToday += amt;
      if (d.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        sumWeek += amt;
      }
      if (d.isAfter(startOfMonth.subtract(const Duration(days: 1)))) {
        sumMonth += amt;
      }

      final key = DateTime(d.year, d.month, d.day);
      if (perDay.containsKey(key)) perDay[key] = (perDay[key] ?? 0) + amt;
    }

    final values = days
        .map((d) => perDay[DateTime(d.year, d.month, d.day)] ?? 0)
        .toList();

    final theme = Theme.of(context);
    final card = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (_, c) {
            final isTight = c.maxWidth < 360;
            return Row(
              children: [
                // Numbers
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _pill('Today', sumToday),
                      _pill('Week', sumWeek),
                      _pill('Month', sumMonth),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    return onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: card,
          );
  }

  Widget _pill(String label, num value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(15),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: _fmt(value),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmt(num v) {
    // basit format; istersen para birimi sembolü ekleyebilirsin
    if (v >= 1000) return '${v.toStringAsFixed(0)}';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxV = values.reduce(max);
    final minV = values.reduce(min);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    // çizgi
    final line = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1565C0);

    // alan (hafif)
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1565C0).withOpacity(0.15);

    final dx = size.width / (values.length - 1);
    final path = Path();
    final area = Path();

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final norm = (values[i] - minV) / range; // 0..1
      final y = size.height - (norm * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(size.width, size.height);
    area.close();

    // çiz
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
