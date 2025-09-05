// lib/pages/weekly/weekly_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weekly_task.dart';
import '../../providers/family_provider.dart';
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
                ...tasks.map(
                  (t) => ListTile(
                    title: Text(t.task),
                    subtitle: t.assignedTo != null
                        ? Text('👤 ${t.assignedTo}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => weekly.removeTask(t),
                    ),
                  ),
                ),
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
                weekly.addTask(WeeklyTask(day, text, assignedTo: selected));
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
