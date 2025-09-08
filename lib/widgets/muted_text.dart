import 'package:flutter/material.dart';

class MutedText extends StatelessWidget {
  final String text;
  const MutedText(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).hintColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
