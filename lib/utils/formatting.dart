import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
