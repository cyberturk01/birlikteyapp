// lib/widgets/task_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_cloud_provider.dart';

Future<void> showTaskEditDialog(BuildContext context, Task t) async {
  DateTime? due = t.dueAt;
  DateTime? reminder = t.reminderAt;

  Future<void> pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d == null) return;
    // opsiyonel saat
    final tm = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(due ?? now),
    );
    due = (tm == null)
        ? DateTime(d.year, d.month, d.day)
        : DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
  }

  Future<void> pickReminder() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: reminder ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (d == null) return;
    final tm = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        reminder ?? now.add(const Duration(hours: 1)),
      ),
    );
    reminder = (tm == null)
        ? DateTime(d.year, d.month, d.day)
        : DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
  }

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setLocal) {
        String _fmt(DateTime? x) => x == null
            ? 'Not set'
            : '${x.day}.${x.month}.${x.year}  ${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';

        return AlertDialog(
          title: const Text('Edit task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Due date'),
                subtitle: Text(_fmt(due)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setLocal(() => due = null),
                    ),
                    IconButton(
                      tooltip: 'Pick',
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () async {
                        await pickDue();
                        setLocal(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm),
                title: const Text('Reminder'),
                subtitle: Text(_fmt(reminder)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setLocal(() => reminder = null),
                    ),
                    IconButton(
                      tooltip: 'Pick',
                      icon: const Icon(Icons.add_alert),
                      onPressed: () async {
                        await pickReminder();
                        setLocal(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final prov = ctx.read<TaskCloudProvider>();
                await prov.updateDueDate(t, due);
                await prov.updateReminder(t, reminder);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
