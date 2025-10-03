import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

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
            tooltip: t.defaultTime,
            icon: const Icon(Icons.schedule),
            onPressed: () => _pickDefaultWeeklyTime(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(
          t.addToDayShort(_weekdayLongLabel(context, _selectedWeekday)),
        ),
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
                            _weekdayShortLabel(context, wd),
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
                    ? Center(child: Text(t.noTasks))
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
  String _weekdayShortLabel(BuildContext context, int wd) {
    final t = AppLocalizations.of(context)!;
    switch (wd) {
      case DateTime.monday:
        return t.weekdayShortMon;
      case DateTime.tuesday:
        return t.weekdayShortTue;
      case DateTime.wednesday:
        return t.weekdayShortWed;
      case DateTime.thursday:
        return t.weekdayShortThu;
      case DateTime.friday:
        return t.weekdayShortFri;
      case DateTime.saturday:
        return t.weekdayShortSat;
      case DateTime.sunday:
        return t.weekdayShortSun;
      default:
        return t.weekdayShortMon;
    }
  }

  String _weekdayIntToCanonical(int wd) {
    final t = AppLocalizations.of(context)!;
    switch (wd) {
      case DateTime.monday:
        return t.weekdayMonday;
      case DateTime.tuesday:
        return t.weekdayTuesday;
      case DateTime.wednesday:
        return t.weekdayWednesday;
      case DateTime.thursday:
        return t.weekdayThursday;
      case DateTime.friday:
        return t.weekdayFriday;
      case DateTime.saturday:
        return t.weekdaySaturday;
      case DateTime.sunday:
        return t.weekdaySunday;
      default:
        return t.weekdayMonday;
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
    final t = AppLocalizations.of(context)!;
    // --- SUGGESTIONS ---
    final defaultWeeklySuggestions = AppLists.defaultTasks(context);

    final frequent = taskProv.suggestedTasks; // varsa top5
    final existingWeekly = weekly.tasks
        .map((w) => w.title)
        .toList(); // weekly’de olanlar
    final suggestions = {
      ...defaultWeeklySuggestions,
      ...frequent,
      ...existingWeekly,
    }.where((s) => s.trim().isNotEmpty).toList();
    final dayLabel = _weekdayLongLabel(context, weekday);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.addTaskForDay(dayLabel)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c,
                decoration: InputDecoration(
                  hintText: t.enterTaskHint,
                  prefixIcon: const Icon(Icons.assignment),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => Navigator.of(context).pop('submit'),
              ),
              const SizedBox(height: 20),
              MemberDropdownUid(
                value: assign, // null olabilir
                onChanged: (v) => assign = v, // v null => Unassigned
                label: t.assignToOptional,
                nullLabel: t.unassigned,
              ),
              const SizedBox(height: 12),

              if (suggestions.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.suggestionsTitle,
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
      final synced = (weekday == DateTime.now().weekday);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced ? t.addedToDayAndSynced(dayLabel) : t.addedToDay(dayLabel),
          ),
        ),
      );
    } else if (result == 'done') {
      if (!mounted) return;
      final synced = (weekday == DateTime.now().weekday);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced ? t.addedToDayAndSynced(dayLabel) : t.addedToDay(dayLabel),
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
  final t = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(t.defaultWeeklyReminderSaved)));
}

/// Tek satır: başlık + kişi + saat, saat seçici & sil
class _WeeklyTaskTile extends StatelessWidget {
  final WeeklyTaskCloud task;
  const _WeeklyTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final weekly = context.read<WeeklyCloudProvider>();
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<Map<String, String>>(
      stream: dictStream, // {uid: label}
      builder: (_, snap) {
        final dict = snap.data ?? const <String, String>{};
        final uid = task.assignedToUid;
        final who = (uid == null || uid.isEmpty)
            ? ''
            : (dict[uid] ?? t.memberLabel);

        String? timeText;
        if (task.hour != null && task.minute != null) {
          final h = task.hour!.toString().padLeft(2, '0');
          final m = task.minute!.toString().padLeft(2, '0');
          timeText = '$h:$m';
        }

        final subtitle = [
          if (who.isNotEmpty) '👤 $who',
          if (timeText != null) '⏰ $timeText',
          '🔔 ${task.notifEnabled ? t.onLabel : t.offLabel}',
        ].join('   •   ');

        return ListTile(
          leading: const Icon(Icons.event_repeat),
          title: Text(task.title),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          onLongPress: () => _showEditWeeklyDialog(context, task), // <-- NEW
          trailing: PopupMenuButton<_WeeklyAction>(
            tooltip: t.more,
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
                        newVal
                            ? t.notificationsEnabled
                            : t.notificationsDisabled,
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t.reminderUpdated)));
                  }
                  break;

                case _WeeklyAction.clearTime:
                  await weekly.updateWeeklyTask(
                    task,
                    timeOfDay: const TimeOfDay(hour: -1, minute: -1),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.reminderTimeCleared)),
                  );
                  break;

                case _WeeklyAction.delete:
                  await weekly.removeWeeklyTaskById(task.id);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: _WeeklyAction.edit,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.edit),
                  title: Text(t.edit),
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
                        ? t.disableNotifications
                        : t.enableNotifications,
                  ),
                ),
              ),
              PopupMenuItem(
                value: _WeeklyAction.setTime,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.access_time),
                  title: Text(t.setTime),
                ),
              ),
              PopupMenuItem(
                value: _WeeklyAction.clearTime,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.close),
                  title: Text(t.clearTime),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _WeeklyAction.delete,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(t.delete),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _weekdayLongLabel(BuildContext context, int wd) {
  final t = AppLocalizations.of(context)!;
  switch (wd) {
    case DateTime.monday:
      return t.weekdayMonday;
    case DateTime.tuesday:
      return t.weekdayTuesday;
    case DateTime.wednesday:
      return t.weekdayWednesday;
    case DateTime.thursday:
      return t.weekdayThursday;
    case DateTime.friday:
      return t.weekdayFriday;
    case DateTime.saturday:
      return t.weekdaySaturday;
    case DateTime.sunday:
      return t.weekdaySunday;
    default:
      return t.weekdayMonday;
  }
}

String _weekdayLongLabelFromString(BuildContext context, String day) {
  final t = AppLocalizations.of(context)!;
  switch (day.toLowerCase()) {
    case 'monday':
      return t.weekdayMonday;
    case 'tuesday':
      return t.weekdayTuesday;
    case 'wednesday':
      return t.weekdayWednesday;
    case 'thursday':
      return t.weekdayThursday;
    case 'friday':
      return t.weekdayFriday;
    case 'saturday':
      return t.weekdaySaturday;
    case 'sunday':
      return t.weekdaySunday;
    default:
      return t.weekdayMonday;
  }
}

Future<void> _showEditWeeklyDialog(
  BuildContext context,
  WeeklyTaskCloud task,
) async {
  final weekly = context.read<WeeklyCloudProvider>();
  final famDictStream = context.read<FamilyProvider>().watchMemberDirectory();
  final t = AppLocalizations.of(context)!;
  final titleC = TextEditingController(text: task.title);
  String day = task.day; // 'Monday'... 'Sunday'
  String? assigned = task.assignedToUid;
  bool notif = task.notifEnabled;
  TimeOfDay? pickedTime = (task.hour != null && task.minute != null)
      ? TimeOfDay(hour: task.hour!, minute: task.minute!)
      : null;

  String _fmtTime(TimeOfDay? tt) => tt == null
      ? t.notSet
      : '${tt.hour.toString().padLeft(2, '0')}:${tt.minute.toString().padLeft(2, '0')}';

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
          title: Text(t.editWeeklyTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: t.titleLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: dayOptions.contains(day) ? day : 'Monday',
                  items: dayOptions.map((d) {
                    return DropdownMenuItem(
                      value: d, // provider için EN string
                      child: Text(
                        _weekdayLongLabelFromString(context, d),
                      ), // UI için localized
                    );
                  }).toList(),
                  onChanged: (v) => setLocal(() => day = v ?? 'Monday'),
                  decoration: InputDecoration(
                    labelText: t.dayLabel, // "Day" -> lokalize
                    border: const OutlineInputBorder(),
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
                      DropdownMenuItem(value: null, child: Text(t.unassigned)),
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
                      decoration: InputDecoration(
                        labelText: t.assignTo,
                        border: const OutlineInputBorder(),
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
                        title: Text(t.reminderTime),
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
                          tooltip: t.clear,
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
                  title: Text(t.notifications),
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
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await weekly.updateWeeklyTask(
                  task,
                  title: titleC.text.trim(),
                  day: day,
                  assignedToUid: assigned,
                  timeOfDay:
                      pickedTime ?? const TimeOfDay(hour: -1, minute: -1),
                  notifEnabled: notif,
                );
                final todayWd = DateTime.now().weekday;
                final changedDayWd = _weekdayStringToInt(day); // helper aşağıda
                if (changedDayWd == todayWd) {
                  final taskProv = ctx.read<TaskCloudProvider>();
                  await weekly.syncTodayToTasks(taskProv);
                }

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(t.weeklyTaskUpdated)));
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    ),
  );
}

int _weekdayStringToInt(String day) {
  switch (day.toLowerCase()) {
    case 'monday':
      return DateTime.monday;
    case 'tuesday':
      return DateTime.tuesday;
    case 'wednesday':
      return DateTime.wednesday;
    case 'thursday':
      return DateTime.thursday;
    case 'friday':
      return DateTime.friday;
    case 'saturday':
      return DateTime.saturday;
    case 'sunday':
      return DateTime.sunday;
    default:
      return DateTime.monday;
  }
}
