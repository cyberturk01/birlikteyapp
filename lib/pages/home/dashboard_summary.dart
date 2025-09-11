// lib/pages/home/dashboard_summary.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../models/weekly_task.dart';
import '../../providers/expense_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/weekly_provider.dart';

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
    final tasks = context.watch<TaskProvider>().tasks;
    final items = context.watch<ItemProvider>().items;

    // BUGÜN'e ait weekly sayısı
    final String todayName = _weekdayName(DateTime.now());
    final weeklyProv = Provider.of<WeeklyProvider?>(context, listen: true);
    final List<WeeklyTask> todaysWeekly =
        weeklyProv?.tasksForDay(todayName) ?? const [];

    // (Opsiyonel) Expenses — yoksa 0/boş gösteririz.
    final expProv = Provider.of<ExpenseProvider?>(context, listen: true);
    final expenses = expProv?.all ?? const <Expense>[];
    final last2 = expenses..sort((a, b) => b.date.compareTo(a.date));
    final recent2 = last2.take(2).toList();

    final pendingTasks = tasks.where((t) => !t.completed).length;
    final toBuyItems = items.where((i) => !i.bought).length;

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 720;
        final cards = <Widget>[
          _SummaryCard(
            icon: Icons.task_alt,
            title: 'Tasks',
            value: '$pendingTasks',
            subtitle: 'Pending today',
            onTap: () => onTap(SummaryDest.tasks),
          ),
          _SummaryCard(
            icon: Icons.shopping_cart,
            title: 'Market',
            value: '$toBuyItems',
            subtitle: 'To buy',
            onTap: () => onTap(SummaryDest.items),
          ),
          // Expenses kutusu (opsiyonel). Provider yoksa sayacı 0 gösterelim.
          _SummaryCard(
            icon: Icons.payments,
            title: 'Expenses',
            value: '2',
            subtitle: 'Last records',
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
            // const SizedBox(height: 8),

            // --- Son 2 Harcama mini alanı (opsiyonel) ---
            // Eğer ExpenseProvider yoksa bu bölümü yorumda bırakabilirsiniz.
            // _LastExpensesMini(expenses: recent2),
          ],
        );
      },
    );
  }
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

// (Opsiyonel) mini son harcamalar
// class _LastExpensesMini extends StatelessWidget {
//   final List<Expense> expenses;
//   const _LastExpensesMini({required this.expenses});
//
//   @override
//   Widget build(BuildContext context) {
//     if (expenses.isEmpty) return const SizedBox.shrink();
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Last expenses',
//               style: Theme.of(context).textTheme.titleSmall,
//             ),
//             const SizedBox(height: 8),
//             ...expenses
//                 .take(2)
//                 .map(
//                   (e) => Row(
//                     children: [
//                       const Icon(Icons.receipt_long, size: 16),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: Text(e.title, overflow: TextOverflow.ellipsis),
//                       ),
//                       Text('\$${e.amount.toStringAsFixed(2)}'),
//                     ],
//                   ),
//                 ),
//           ],
//         ),
//       ),
//     );
//   }
// }
