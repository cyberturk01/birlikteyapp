import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    final card = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (_, c) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520), // opsiyonel
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  alignment: WrapAlignment.center, // yatayda ortala
                  runAlignment: WrapAlignment.center, // satırlar arası ortala
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _pill(context, 'Today', sumToday),
                    _pill(context, 'Week', sumWeek),
                    _pill(context, 'Month', sumMonth),
                  ],
                ),
              ),
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

  Widget _pill(BuildContext context, String label, num value) {
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
              text: _fmtMoney(context, value),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

String _fmtMoney(BuildContext context, num amount, {String currency = 'EUR'}) {
  final format = NumberFormat.currency(
    locale: Localizations.localeOf(context).toString(),
    symbol: '€', // currency parametresine göre değiştirilebilir
    decimalDigits: 0, // istersen 2 yap
  );
  return format.format(amount);
}
