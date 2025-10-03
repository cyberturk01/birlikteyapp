import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/ui_provider.dart';
import '../../widgets/muted_text.dart';
import '../../widgets/swipe_bg.dart';

class TasksSubsection extends StatelessWidget {
  final List<Task> tasksFiltered;
  final bool expanded;
  final int previewCount;
  final VoidCallback onToggleExpand;
  final void Function(Task) onToggleTask;
  final void Function(Task task)? onEditTask;
  final bool showMeta;

  const TasksSubsection({
    super.key,
    required this.tasksFiltered,
    required this.expanded,
    required this.previewCount,
    required this.onToggleExpand,
    required this.onToggleTask,
    this.onEditTask,
    this.showMeta = true,
  });

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final total = tasksFiltered.length;
    final showAll = expanded || total <= previewCount;
    final visible = showAll
        ? tasksFiltered
        : tasksFiltered.take(previewCount).toList();
    final hiddenCount = showAll ? 0 : (total - previewCount);

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.tasks,
          style: th.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (tasksFiltered.isEmpty)
          MutedText(t.noTasks)
        else
          ...visible.map((task) {
            final isDone = task.completed;
            final now = DateTime.now();
            final hasDue = task.dueAt != null;
            final hasRem = task.reminderAt != null;
            final isOverdue = hasDue && !isDone && task.dueAt!.isBefore(now);
            return Dismissible(
              direction: DismissDirection.horizontal,
              key: ValueKey(
                task.remoteId ??
                    '${task.name}|${task.assignedToUid ?? //
                        ""}',
              ),
              background: const SwipeBg(
                color: Colors.green,
                icon: Icons.check,
                align: Alignment.centerLeft,
              ),
              secondaryBackground: const SwipeBg(
                color: Colors.red,
                icon: Icons.delete,
                align: Alignment.centerRight,
              ),
              confirmDismiss: (dir) async {
                if (dir == DismissDirection.startToEnd) {
                  await _handleToggleTask(
                    context,
                    task,
                    withCelebrate: !task.completed,
                  );
                  return false; // tile listeden düşmesin
                } else {
                  final removed = task;
                  await context.read<TaskCloudProvider>().removeTask(task);

                  // Undo SnackBar
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.taskDeleted),
                      action: SnackBarAction(
                        label: t.undo,
                        onPressed: () {
                          context.read<TaskCloudProvider>().addTask(removed);
                        },
                      ),
                    ),
                  );
                  return true;
                }
              },
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -2,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onLongPress: onEditTask == null
                    ? null
                    : () => onEditTask!(task),
                leading: Checkbox(
                  value: isDone,
                  onChanged: (v) async {
                    final willComplete = v == true && !task.completed;
                    await _handleToggleTask(
                      context,
                      task,
                      withCelebrate: v == true,
                    );
                    if (willComplete && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.taskCompletedToast),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),

                title: Text(
                  task.name,
                  overflow: TextOverflow.ellipsis,
                  style: isDone
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDue) _DueDot(date: task.dueAt!, overdue: isOverdue),

                    //TODO düzelt burayi
                    if (hasRem)
                      _DueDot(date: task.reminderAt!, overdue: isOverdue),
                    const SizedBox(width: 8),

                    // mevcut menü
                    PopupMenuButton<String>(
                      tooltip: t.more,
                      onSelected: (v) async {
                        if (v == 'edit' && onEditTask != null) {
                          onEditTask!(task);
                        } else if (v == 'delete') {
                          final removed = task;
                          await context.read<TaskCloudProvider>().removeTask(
                            task,
                          );
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(t.taskDeleted),
                                action: SnackBarAction(
                                  label: t.undo,
                                  onPressed: () {
                                    context.read<TaskCloudProvider>().addTask(
                                      removed,
                                    );
                                  },
                                ),
                              ),
                            );
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.edit),
                            title: Text(t.edit),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            title: Text(t.delete),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                onTap: () => _handleToggleTask(context, task),
              ),
            );
          }),
        if (hiddenCount > 0 || expanded)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToggleExpand,
              child: Text(showAll ? t.showLess : t.showAllCount(hiddenCount)),
            ),
          ),
      ],
    );
  }
}

class _DueDot extends StatelessWidget {
  final DateTime date;
  final bool overdue;
  const _DueDot({required this.date, required this.overdue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = overdue
        ? Colors.red
        : scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final fg = overdue ? Colors.white : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            _fmtDueShort(date), // 12/03 ya da 12/03 14:30 gibi kısa
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDueShort(DateTime d) {
  final now = DateTime.now();
  final isToday =
      d.year == now.year && d.month == now.month && d.day == now.day;
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  if (isToday) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mi';
  }
  return '$dd/$mm';
}

// ---- toggle handlers keep auto-switch behavior via UiProvider ----
Future<void> _handleToggleTask(
  BuildContext context,
  Task tk, {
  bool withCelebrate = false,
}) async {
  final ui = context.read<UiProvider>();
  final willComplete = !tk.completed;
  final t = AppLocalizations.of(context)!;

  await context.read<TaskCloudProvider>().toggleTask(tk, willComplete);

  if (withCelebrate && willComplete) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.of(context);
      m.clearSnackBars();
      m.showSnackBar(
        SnackBar(
          content: Text(t.taskCompletedToast),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  if (withCelebrate && willComplete) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.pointsAwarded(10)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  if (willComplete && ui.taskFilter == TaskViewFilter.pending) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.completed);
  } else if (!willComplete && ui.taskFilter == TaskViewFilter.completed) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.pending);
  }
}
