import 'package:flutter/material.dart';

import 'brand_seed.dart'; // BrandSeed + extension

class AppTheme {
  static ThemeData light(BrandSeed brand) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand.seed,
      brightness: Brightness.light,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData dark(BrandSeed brand) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand.seed,
      brightness: Brightness.dark,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}
