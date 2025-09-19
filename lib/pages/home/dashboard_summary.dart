// lib/pages/home/dashboard_summary.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../models/weekly_task.dart';
import '../../providers/expense_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/weekly_provider.dart';
import '../../widgets/quick_overview_sheets.dart';
import '../../widgets/section_lists.dart';

enum SummaryDest { tasks, items, weekly, expenses }

typedef DashboardTap = void Function(SummaryDest dest);

class DashboardSummaryBar extends StatelessWidget {
  final DashboardTap onTap;
  const DashboardSummaryBar({super.key, required this.onTap});

  String _weekdayName(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskCloudProvider>().tasks;
    final items = context.watch<ItemCloudProvider>().items;

    // BUGÜN'e ait weekly sayısı
    final String todayName = _weekdayName(DateTime.now());
    final weeklyProv = Provider.of<WeeklyProvider?>(context, listen: true);
    final List<WeeklyTask> todaysWeekly =
        weeklyProv?.tasksForDay(todayName) ?? const [];

    // (Opsiyonel) Expenses — yoksa 0/boş gösteririz.
    final expProv = Provider.of<ExpenseProvider?>(context, listen: true);
    final expenses = expProv?.all ?? const <Expense>[];

    final pendingTasks = tasks.where((t) => !t.completed).length;
    final toBuyItems = items.where((i) => !i.bought).length;
    final todayExpenses = expenses.length;

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 720;
        final cards = <Widget>[
          _SummaryCard(
            icon: Icons.task_alt,
            title: 'Tasks',
            value: '$pendingTasks',
            subtitle: 'Pending today',
            onTap: () {
              onTap(SummaryDest.tasks);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showPendingTasksDialog(context);
              });
            },
          ),
          _SummaryCard(
            icon: Icons.shopping_cart,
            title: 'Market',
            value: '$toBuyItems',
            subtitle: 'To buy',
            onTap: () {
              onTap(SummaryDest.items);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showToBuyItemsDialog(context);
              });
            },
          ),
          // Expenses kutusu (opsiyonel). Provider yoksa sayacı 0 gösterelim.
          _SummaryCard(
            icon: Icons.payments,
            title: 'Expenses',
            value: '$todayExpenses',
            subtitle: 'Total records',
            onTap: () => onTap(SummaryDest.expenses),
          ),
          _SummaryCard(
            icon: Icons.calendar_today,
            title: 'Weekly',
            value: '${todaysWeekly.length}',
            subtitle: todayName,
            onTap: () => onTap(SummaryDest.weekly),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: isWide
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.start,
              children: cards
                  .map(
                    (w) => SizedBox(
                      width: isWide
                          ? (c.maxWidth - 36) / 4
                          : (c.maxWidth - 12) / 2,
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showPendingTasksDialog(BuildContext context) async {
  // read: dialog builder içinde listen etmeden veri çekiyoruz
  final taskProv = context.read<TaskCloudProvider>();
  final tasks = taskProv.tasks.where((t) => !t.completed).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final pending = taskProv.tasks.where((t) => !t.completed).toList();

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('   All Pending Tasks  📑 '),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 480),
        child: tasks.isEmpty
            ? const Text('No pending tasks')
            : SingleChildScrollView(
                child: TasksSection(
                  tasks: pending,
                  expanded: true,
                  previewCount: 999, // her şeyi göster
                  onToggleTask: (t) => context
                      .read<TaskCloudProvider>()
                      .toggleTask(t, !t.completed),
                  onToggleExpand: null, // “show all” linkini gizlemek için
                  showHeader: false, // başlığı tekrarlamayalım
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          child: const Text('Details'),
          onPressed: () {
            Navigator.pop(context);
            showPendingTasksSheet(context); // alt sheet istersen
          },
        ),
      ],
    ),
  );
}

Future<void> showToBuyItemsDialog(BuildContext context) async {
  final itemProv = context.read<ItemCloudProvider>();
  final items = itemProv.items.where((i) => !i.bought).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final toBuy = itemProv.items.where((i) => !i.bought).toList();

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('   All Items to Buy  🛍️   '),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 480),
        child: items.isEmpty
            ? const Text('No items to buy')
            : SingleChildScrollView(
                child: ItemsSection(
                  items: toBuy,
                  expanded: true,
                  previewCount: 999,
                  onToggleItem: (it) => context
                      .read<ItemCloudProvider>()
                      .toggleItem(it, !it.bought),
                  onToggleExpand: null,
                  showHeader: false,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // mevcut quick add kullan
            showToBuyItemsSheet(context); // alt sheet tercih edersen
          },
          child: const Text('Details'),
        ),
      ],
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
