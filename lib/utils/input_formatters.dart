import 'package:flutter/services.dart';

/// Yalnızca rakam + tek ondalık ayırıcı ('.' veya ',') izin verir.
/// Başına '-' yazılmasını engeller (negatif yok).
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Boş olabilir
    if (text.isEmpty) return newValue;

    // Sadece 0-9 ve . , izin ver
    final allowed = RegExp(r'^[0-9\.,]*$');
    if (!allowed.hasMatch(text)) return oldValue;

    // En fazla 1 ondalık ayırıcı
    final dots = '.'.allMatches(text).length;
    final commas = ','.allMatches(text).length;
    if (dots + commas > 1) return oldValue;

    // Ayırıcı tek başına veya başta ".,": iptal
    if (text == '.' ||
        text == ',' ||
        text.startsWith('.,') ||
        text.startsWith(',.')) {
      return oldValue;
    }

    return newValue;
  }
}

/// Kullanıcı girdisini double’a çevirir.
/// Virgülü noktaya normalleştirir; boş/invalid → null.
double? parseAmountFlexible(String raw) {
  final t = raw.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
