import 'package:flutter/material.dart';

class SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final AlignmentGeometry align;
  const SwipeBg({
    super.key,
    required this.color,
    required this.icon,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Icon(icon, color: Colors.white),
    );
  }
}
