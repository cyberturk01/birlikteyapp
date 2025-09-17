import 'package:flutter/material.dart';

import '../../models/view_section.dart';

class MemberCardHeader extends StatelessWidget {
  final String memberName;
  final HomeSection section;
  final int totalTasks;
  final int completedTasks;
  final bool expandTasks;

  const MemberCardHeader({
    super.key,
    required this.memberName,
    required this.section,
    required this.totalTasks,
    required this.completedTasks,
    required this.expandTasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Row(
      children: [
        CircleAvatar(
          child: Text(
            memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (section == HomeSection.tasks &&
                  totalTasks > 0 &&
                  !expandTasks)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${(progress * 100).round()}%'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
