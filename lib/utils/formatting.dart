import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/expense_cloud_provider.dart';

NumberFormat _currencyFmtFor(BuildContext context, {String currency = 'EUR'}) {
  final locale = Localizations.localeOf(
    context,
  ).toString(); // örn. tr_TR, de_DE
  // simpleCurrency: sembol + doğru ayırıcılar
  return NumberFormat.simpleCurrency(locale: locale, name: currency);
}

/// Örn: €1.234,56 (de_DE) veya 1.234,56 ₺ (tr_TR, currency='TRY')
String fmtMoney(
  BuildContext context,
  double amount, {
  String currency = 'EUR',
}) {
  return _currencyFmtFor(context, currency: currency).format(amount);
}

String fmtDateYmd(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

String monthTitle(ExpenseDateFilter f, DateTime now) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (f == ExpenseDateFilter.thisMonth) {
    return 'This month • ${months[now.month - 1]} ${now.year}';
  }
  if (f == ExpenseDateFilter.lastMonth) {
    final prev = DateTime(now.year, now.month - 1, 1);
    return 'Last month • ${months[prev.month - 1]} ${prev.year}';
  }
  return 'All time';
}
