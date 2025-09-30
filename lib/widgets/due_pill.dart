// lib/widgets/due_pill.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _DueStatus { overdue, today, upcoming, none }

class DuePill extends StatelessWidget {
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabelOverride;

  const DuePill({
    super.key,
    required this.dueAt,
    this.reminderAt,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.semanticsLabelOverride,
  });

  _DueStatus _status(DateTime now, DateTime? due) {
    if (due == null) return _DueStatus.none;
    final d = DateTime(due.year, due.month, due.day);
    final n = DateTime(now.year, now.month, now.day);
    if (d.isBefore(n)) return _DueStatus.overdue;
    if (d.isAtSameMomentAs(n)) return _DueStatus.today;
    return _DueStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = _status(now, dueAt);
    if (status == _DueStatus.none) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat.MMMd(); // ör. 30 Eyl
    final text = fmt.format(dueAt!);

    late final Color fg, bg;
    late final IconData icon;
    switch (status) {
      case _DueStatus.overdue:
        fg = cs.onErrorContainer;
        bg = cs.errorContainer;
        icon = Icons.error_outline;
        break;
      case _DueStatus.today:
        fg = cs.onTertiaryContainer;
        bg = cs.tertiaryContainer;
        icon = Icons.today_outlined;
        break;
      case _DueStatus.upcoming:
        fg = cs.onSurfaceVariant;
        bg = cs.surfaceVariant;
        icon = Icons.event_outlined;
        break;
      case _DueStatus.none:
        fg = cs.onSurfaceVariant;
        bg = cs.surfaceVariant;
        icon = Icons.event_outlined;
        break;
    }

    return Semantics(
      label: semanticsLabelOverride ?? 'Son tarih: $text',
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            if (reminderAt != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.schedule, size: 12, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}
