import 'package:flutter/material.dart';

/// Uygulamanın marka renklerini temsil eden enum

enum BrandSeed {
  amber(Colors.amber, 'Amber'),
  blue(Colors.blue, 'Blue'),
  blueGrey(Colors.blueGrey, 'BlueGrey'),
  cyan(Colors.cyan, 'Cyan'),
  green(Colors.green, 'Green'),
  indigo(Colors.indigo, 'Indigo'),
  orange(Colors.orange, 'Orange'),
  pink(Colors.pink, 'Pink'),
  purple(Colors.purple, 'Purple'),
  teal(Colors.teal, 'Teal'),
  yellow(Colors.yellow, 'Yellow');

  final Color seed;
  final String label;
  const BrandSeed(this.seed, this.label);
}

extension BrandSeedX on BrandSeed {
  /// Her seed color için MaterialColor döndürür
  Color get seed {
    switch (this) {
      case BrandSeed.amber:
        return Colors.amber.shade50;
      case BrandSeed.blue:
        return Colors.blue;
      case BrandSeed.blueGrey:
        return Colors.blueGrey;
      case BrandSeed.cyan:
        return Colors.cyanAccent;
      case BrandSeed.green:
        return Colors.green;
      case BrandSeed.indigo:
        return Colors.indigo;
      case BrandSeed.orange:
        return Colors.deepOrange;
      case BrandSeed.pink:
        return Colors.pink;
      case BrandSeed.purple:
        return Colors.deepPurple;
      case BrandSeed.teal:
        return Colors.teal;
      case BrandSeed.yellow:
        return Colors.yellow.shade50;
    }
  }

  String get label {
    switch (this) {
      case BrandSeed.amber:
        return "Amber";
      case BrandSeed.blue:
        return 'Blue';
      case BrandSeed.blueGrey:
        return "Blue Grey";
      case BrandSeed.cyan:
        return 'Cyan';
      case BrandSeed.green:
        return 'Green';
      case BrandSeed.indigo:
        return "Indigo";
      case BrandSeed.orange:
        return 'Orange';
      case BrandSeed.pink:
        return 'Pink';
      case BrandSeed.purple:
        return 'Purple';
      case BrandSeed.teal:
        return 'Teal';
      case BrandSeed.yellow:
        return 'Yellow';
    }
  }

  /// Küçük renk kutusu için widget
  Widget swatch({double size = 28}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: seed,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12, width: 1),
      ),
    );
  }
}
