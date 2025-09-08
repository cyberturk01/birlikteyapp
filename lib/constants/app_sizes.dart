// lib/constants/app_sizes.dart
import 'package:flutter/material.dart';

class Gaps {
  static const s4 = SizedBox(height: 4, width: 4);
  static const s6 = SizedBox(height: 6, width: 6);
  static const s8 = SizedBox(height: 8, width: 8);
  static const s12 = SizedBox(height: 12, width: 12);
  static const s16 = SizedBox(height: 16, width: 16);
  static const s24 = SizedBox(height: 24, width: 24);
}

class Insets {
  static const screen = EdgeInsets.all(12);
  static const card = EdgeInsets.all(14);
  static const chip = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
}

class Corners {
  static const card = 18.0;
  static const chip = 12.0;
}

class Times {
  static const fast = Duration(milliseconds: 150);
  static const med = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
