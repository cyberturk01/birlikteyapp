import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/weekly_task_cloud.dart';
import '../../providers/family_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../widgets/member_dropdown_uid.dart';

enum _WeeklyAction { edit, toggleNotif, setTime, clearTime, delete }

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
        actions: [
          IconButton(
            tooltip: 'Default time',
            icon: const Icon(Icons.schedule),
            onPressed: () => _pickDefaultWeeklyTime(context),
          ),
        ],
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
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        addSemanticIndexes: false,
                        cacheExtent: 800,
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

Future<void> _pickDefaultWeeklyTime(BuildContext context) async {
  final sp = await SharedPreferences.getInstance();
  final h = sp.getInt('weeklyReminderHour') ?? 19;
  final m = sp.getInt('weeklyReminderMinute') ?? 0;

  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: h, minute: m),
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child ?? const SizedBox.shrink(),
    ),
  );
  if (picked == null) return;

  await sp.setInt('weeklyReminderHour', picked.hour);
  await sp.setInt('weeklyReminderMinute', picked.minute);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Default weekly reminder time saved')),
  );
}

/// Tek satır: başlık + kişi + saat, saat seçici & sil
class _WeeklyTaskTile extends StatelessWidget {
  final WeeklyTaskCloud task;
  const _WeeklyTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final weekly = context.read<WeeklyCloudProvider>();
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    return StreamBuilder<Map<String, String>>(
      stream: dictStream, // {uid: label}
      builder: (_, snap) {
        final dict = snap.data ?? const <String, String>{};
        final uid = task.assignedToUid;
        final who = (uid == null || uid.isEmpty) ? '' : (dict[uid] ?? 'Member');

        String? timeText;
        if (task.hour != null && task.minute != null) {
          final h = task.hour!.toString().padLeft(2, '0');
          final m = task.minute!.toString().padLeft(2, '0');
          timeText = '$h:$m';
        }

        final subtitle = [
          if (who.isNotEmpty) '👤 $who',
          if (timeText != null) '⏰ $timeText',
          '🔔 ${task.notifEnabled ? "On" : "Off"}',
        ].join('   •   ');

        return ListTile(
          leading: const Icon(Icons.event_repeat),
          title: Text(task.title),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          onLongPress: () => _showEditWeeklyDialog(context, task), // <-- NEW
          trailing: PopupMenuButton<_WeeklyAction>(
            tooltip: 'More',
            onSelected: (action) async {
              switch (action) {
                case _WeeklyAction.edit:
                  await _showEditWeeklyDialog(context, task);
                  break;

                case _WeeklyAction.toggleNotif:
                  final newVal = !task.notifEnabled;
                  await weekly.updateWeeklyTask(task, notifEnabled: newVal);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Notifications ${newVal ? "enabled" : "disabled"}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  break;

                case _WeeklyAction.setTime:
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
                  break;

                case _WeeklyAction.clearTime:
                  await weekly.updateWeeklyTask(
                    task,
                    timeOfDay: const TimeOfDay(hour: -1, minute: -1),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder time cleared')),
                  );
                  break;

                case _WeeklyAction.delete:
                  await weekly.removeWeeklyTaskById(task.id);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: _WeeklyAction.edit,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: _WeeklyAction.toggleNotif,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    task.notifEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                  ),
                  title: Text(
                    task.notifEnabled
                        ? 'Disable notifications'
                        : 'Enable notifications',
                  ),
                ),
              ),
              const PopupMenuItem(
                value: _WeeklyAction.setTime,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.access_time),
                  title: Text('Set time'),
                ),
              ),
              const PopupMenuItem(
                value: _WeeklyAction.clearTime,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.close),
                  title: Text('Clear time'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _WeeklyAction.delete,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showEditWeeklyDialog(
  BuildContext context,
  WeeklyTaskCloud task,
) async {
  final weekly = context.read<WeeklyCloudProvider>();
  final famDictStream = context.read<FamilyProvider>().watchMemberDirectory();

  final titleC = TextEditingController(text: task.title);
  String day = task.day; // 'Monday'... 'Sunday'
  String? assigned = task.assignedToUid;
  bool notif = task.notifEnabled;
  TimeOfDay? pickedTime = (task.hour != null && task.minute != null)
      ? TimeOfDay(hour: task.hour!, minute: task.minute!)
      : null;

  String _fmtTime(TimeOfDay? t) => t == null
      ? 'Not set'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  final dayOptions = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return AlertDialog(
          title: const Text('Edit weekly task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: dayOptions.contains(day) ? day : 'Monday',
                  items: dayOptions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setLocal(() => day = v ?? 'Monday'),
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Member selector
                StreamBuilder<Map<String, String>>(
                  stream: famDictStream,
                  builder: (_, snap) {
                    final dict = snap.data ?? const <String, String>{};
                    final items = <DropdownMenuItem<String?>>[
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...dict.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ];
                    final value = dict.containsKey(assigned) ? assigned : null;

                    return DropdownButtonFormField<String?>(
                      value: value,
                      isExpanded: true,
                      items: items,
                      onChanged: (v) => setLocal(() => assigned = v),
                      decoration: const InputDecoration(
                        labelText: 'Assign to',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Time + notif
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('Reminder time'),
                        subtitle: Text(_fmtTime(pickedTime)),
                        onTap: () async {
                          final base = TimeOfDay(
                            hour: task.hour ?? 19,
                            minute: task.minute ?? 0,
                          );
                          final t = await showTimePicker(
                            context: context,
                            initialTime: pickedTime ?? base,
                            builder: (ctx, child) => MediaQuery(
                              data: MediaQuery.of(
                                ctx,
                              ).copyWith(alwaysUse24HourFormat: true),
                              child: child ?? const SizedBox.shrink(),
                            ),
                          );
                          if (t != null) setLocal(() => pickedTime = t);
                        },
                        trailing: IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () => setLocal(() => pickedTime = null),
                        ),
                      ),
                    ),
                  ],
                ),

                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: notif,
                  onChanged: (v) => setLocal(() => notif = v),
                  title: const Text('Notifications'),
                  secondary: Icon(
                    notif
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await weekly.updateWeeklyTask(
                  task,
                  title: titleC.text.trim(),
                  day: day,
                  assignedToUid: assigned,
                  timeOfDay:
                      pickedTime ??
                      const TimeOfDay(hour: -1, minute: -1), // null => clear
                  notifEnabled: notif,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Weekly task updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
