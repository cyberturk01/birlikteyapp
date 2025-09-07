// lib/pages/weekly/weekly_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weekly_task.dart';
import '../../providers/family_provider.dart';
import '../../providers/ui_provider.dart'; // default reminder için
import '../../providers/weekly_provider.dart';

class WeeklyPage extends StatelessWidget {
  const WeeklyPage({Key? key}) : super(key: key);

  static const days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  @override
  Widget build(BuildContext context) {
    final weekly = context.watch<WeeklyProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Plan')),
      body: ListView.builder(
        itemCount: days.length,
        itemBuilder: (_, index) {
          final day = days[index];
          final tasks = weekly.tasksForDay(day);
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(
                day,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                if (tasks.isEmpty) const ListTile(title: Text('No tasks yet')),
                ...tasks.map((t) => _WeeklyTaskTile(task: t)).toList(),
                TextButton.icon(
                  onPressed: () => _addWeeklyTaskDialog(context, day, family),
                  icon: const Icon(Icons.add),
                  label: const Text('Add task'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addWeeklyTaskDialog(
    BuildContext context,
    String day,
    List<String> familyMembers,
  ) {
    final weekly = context.read<WeeklyProvider>();
    final c = TextEditingController();
    String? selected;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Task for $day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              decoration: const InputDecoration(hintText: 'Enter task'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Assign to (Optional)',
              ),
              value: selected,
              items: familyMembers
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => selected = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = c.text.trim();
              if (text.isNotEmpty) {
                weekly.addTask(WeeklyTask(text, day, assignedTo: selected));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Tek satır: görev başlığı, kişi, saat bilgisi + saat seçici & silme
class _WeeklyTaskTile extends StatelessWidget {
  final WeeklyTask task;
  const _WeeklyTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final weekly = context.read<WeeklyProvider>();
    final ui = context.watch<UiProvider>();

    String? timeText;
    if (task.hour != null && task.minute != null) {
      final h = task.hour!.toString().padLeft(2, '0');
      final m = task.minute!.toString().padLeft(2, '0');
      timeText = '$h:$m';
    }

    final subtitle = [
      if (task.assignedTo != null && task.assignedTo!.trim().isNotEmpty)
        '👤 ${task.assignedTo}',
      if (timeText != null) '⏰ $timeText',
    ].join('   •   ');

    return ListTile(
      leading: const Icon(Icons.event_repeat),
      title: Text(task.title), // Eğer sende `task.task` ise burayı değiştir
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Reminder time',
            icon: const Icon(Icons.access_time),
            onPressed: () async {
              // Başlangıç saati: görev saati → yoksa config default → 19:00
              final initial = (task.hour != null && task.minute != null)
                  ? TimeOfDay(hour: task.hour!, minute: task.minute!)
                  : (ui.weeklyDefaultReminder ??
                        const TimeOfDay(hour: 19, minute: 0));

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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder time updated')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => weekly.removeTask(task),
          ),
        ],
      ),
    );
  }
}
