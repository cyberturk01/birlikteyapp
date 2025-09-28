import 'package:flutter/material.dart';

class BudgetBadge {
  final Widget? overChip;
  final String? remainingText;
  BudgetBadge({this.overChip, this.remainingText});
}

BudgetBadge buildBudgetBadge({
  required BuildContext context,
  required double spent,
  required double? budget, // null => limit yok
}) {
  if (budget == null) {
    return BudgetBadge(remainingText: null, overChip: null);
  }
  final cs = Theme.of(context).colorScheme;
  final over = spent > budget;
  final remain = (budget - spent);
  final remainingText = remain >= 0
      ? 'remaining: ${_shortMoney(remain)}'
      : 'over by ${_shortMoney(remain.abs())}';

  final overChip = over
      ? Chip(
          label: const Text(
            'OVER',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          avatar: Icon(Icons.circle, size: 12, color: cs.error),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        )
      : null;

  return BudgetBadge(overChip: overChip, remainingText: remainingText);
}

String _shortMoney(double v) {
  final abs = v.abs();
  if (abs >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}
