import 'package:flutter/material.dart';

class AvatarWithRing extends StatelessWidget {
  final String text;
  const AvatarWithRing({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    final initial = text.isNotEmpty ? text[0].toUpperCase() : '?';
    final ring = Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: CircleAvatar(radius: 20, child: Text(initial)),
    );
  }
}
