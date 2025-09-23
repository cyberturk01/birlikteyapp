import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weekly_task_cloud.dart';
import '../../providers/family_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../widgets/member_dropdown_uid.dart';

class WeeklyPage extends StatefulWidget {
  const WeeklyPage({super.key});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  // 1=Mon ... 7=Sun  -> DateTime.weekday ile uyumlu tutuyoruz
  int _selectedWeekday = DateTime.now().weekday;

  static const _labels = <int, String>{
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    final weekly = context.watch<WeeklyCloudProvider>();
    final todayWd = DateTime.now().weekday;

    // Seçili gün için weekly listesi
    final selectedDayName = _weekdayIntToCanonical(_selectedWeekday);
    final tasks = weekly.tasksForDay(selectedDayName);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Task Plan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Plan weekly routines and assign them to your family.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text('Add to ${_labels[_selectedWeekday]}'),
        onPressed: () =>
            _openAddDialog(context: context, weekday: _selectedWeekday),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ===== Hafta Şeridi (7 chip) – tüm günler ekranda =====
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final wd = i + 1; // 1..7
                      final sel = wd == _selectedWeekday;
                      final isToday = wd == todayWd;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          selected: sel,
                          label: Text(
                            _labels[wd]!,
                            style: TextStyle(
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          avatar: isToday
                              ? const Icon(Icons.today, size: 16)
                              : null,
                          onSelected: (_) =>
                              setState(() => _selectedWeekday = wd),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== Seçili günün listesi (kaydırma sadece öğe sayısına göre) =====
            Expanded(
              child: Card(
                elevation: 2,
                child: tasks.isEmpty
                    ? const Center(child: Text('No tasks yet'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _WeeklyTaskTile(task: tasks[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  String _weekdayIntToCanonical(int wd) {
    switch (wd) {
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
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  Future<void> _openAddDialog({
    required BuildContext context,
    required int weekday,
  }) async {
    final weekly = context.read<WeeklyCloudProvider>();
    final taskProv = context.read<TaskCloudProvider>();
    final dayName = _weekdayIntToCanonical(weekday);

    final c = TextEditingController();
    String? assign;

    // --- SUGGESTIONS ---
    const defaultWeeklySuggestions = AppLists.defaultTasks;

    final frequent = taskProv.suggestedTasks; // varsa top5
    final existingWeekly = weekly.tasks
        .map((w) => w.title)
        .toList(); // weekly’de olanlar
    final suggestions = {
      ...defaultWeeklySuggestions,
      ...frequent,
      ...existingWeekly,
    }.where((s) => s.trim().isNotEmpty).toList();

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add task for $dayName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c,
                decoration: const InputDecoration(
                  hintText: 'Enter task…',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => Navigator.of(context).pop('submit'),
              ),
              const SizedBox(height: 20),
              MemberDropdownUid(
                value: assign, // null olabilir
                onChanged: (v) => assign = v, // v null => Unassigned
                label: 'Assign to (optional)',
                nullLabel: 'Unassigned',
              ),
              const SizedBox(height: 12),

              if (suggestions.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggestions',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions.map((name) {
                        return ActionChip(
                          label: Text(name),
                          onPressed: () async {
                            await weekly.addWeeklyTask(
                              WeeklyTaskCloud(
                                dayName,
                                name,
                                assignedToUid: assign,
                              ),
                            );
                            if (weekday == DateTime.now().weekday) {
                              await weekly.syncTodayToTasks(taskProv);
                            }
                            if (context.mounted) Navigator.pop(context, 'done');
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('Add'),
            onPressed: () => Navigator.pop(context, 'submit'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'submit') {
      final text = c.text.trim();
      if (text.isEmpty) return;

      await weekly.addWeeklyTask(
        WeeklyTaskCloud(dayName, text, assignedToUid: assign),
      );
      if (weekday == DateTime.now().weekday) {
        await weekly.syncTodayToTasks(taskProv);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added to $dayName${weekday == DateTime.now().weekday ? " and synced to Tasks" : ""}',
          ),
        ),
      );
    } else if (result == 'done') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added to $dayName${weekday == DateTime.now().weekday ? " and synced to Tasks" : ""}',
          ),
        ),
      );
    }
  }
}

/// Tek satır: başlık + kişi + saat, saat seçici & sil
class _WeeklyTaskTile extends StatelessWidget {
  final WeeklyTaskCloud task;
  const _WeeklyTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final weekly = context.read<WeeklyCloudProvider>();

    String? timeText;
    if (task.hour != null && task.minute != null) {
      final h = task.hour!.toString().padLeft(2, '0');
      final m = task.minute!.toString().padLeft(2, '0');
      timeText = '$h:$m';
    }

    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    final subtitle = [
      if ((task.assignedToUid ?? '').isNotEmpty) '👤 ${task.assignedToUid}',
      if (timeText != null) '⏰ $timeText',
    ].join('   •   ');

    return StreamBuilder<Map<String, String>>(
      stream: dictStream, // {uid: label}
      builder: (_, snap) {
        final dict = snap.data ?? const <String, String>{};
        final label =
            (task.assignedToUid == null || task.assignedToUid!.trim().isEmpty)
            ? null
            : (dict[task.assignedToUid] ?? 'Member'); // UID -> Label

        final subtitle = [
          if (label != null) '👤 $label',
          if (timeText != null) '⏰ $timeText',
        ].join('   •   ');
        return ListTile(
          leading: const Icon(Icons.event_repeat),
          title: Text(task.title),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          trailing: Wrap(
            spacing: 2,
            children: [
              IconButton(
                tooltip: 'Reminder time',
                icon: const Icon(Icons.access_time),
                onPressed: () async {
                  final initial = TimeOfDay(
                    hour: task.hour ?? 19,
                    minute: task.minute ?? 0,
                  );
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: initial,
                    builder: (ctx, child) => MediaQuery(
                      data: MediaQuery.of(
                        ctx,
                      ).copyWith(alwaysUse24HourFormat: true),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  if (picked != null) {
                    await weekly.updateWeeklyTask(task, timeOfDay: picked);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder updated')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => weekly.removeWeeklyTaskById(task.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
