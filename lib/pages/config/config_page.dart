import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/notification_service.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;
    final taskProv = context.read<TaskProvider>();
    final itemProv = context.read<ItemProvider>();

    final t = Theme.of(context);

    String _fmt(TimeOfDay tod) {
      final h = tod.hour.toString().padLeft(2, '0');
      final m = tod.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    final current =
        ui.weeklyDefaultReminder ?? const TimeOfDay(hour: 19, minute: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [
          TextButton(
            onPressed: () => context.read<UiProvider>().resetFilters(),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // === Appearance / Theme ===
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Weekly default reminder time'),
            subtitle: Text(_fmt(current)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: current,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(
                    ctx,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
              if (picked != null) {
                await context.read<UiProvider>().setWeeklyDefaultReminder(
                  picked,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Default weekly reminder time saved'),
                  ),
                );
              }
            },
          ),
          const Divider(height: 24),
          // ... Weekly default reminder time ListTile'ından sonra:
          ListTile(
            leading: const Icon(Icons.alarm_on),
            title: const Text('Enable exact alarms (Android)'),
            subtitle: const Text('Open system setting to allow precise alarms'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              if (!Platform.isAndroid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This setting is Android-only')),
                );
                return;
              }
              try {
                const intent = AndroidIntent(
                  action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
                );
                await intent.launch();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open settings: $e')),
                );
              }
            },
          ),

          const Divider(height: 24),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.phone_android),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {ui.themeMode},
            onSelectionChanged: (s) =>
                context.read<UiProvider>().setThemeMode(s.first),
            showSelectedIcon: false,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Section: Tasks / Market
          Text('Section', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SegmentedButton<HomeSection>(
            segments: const [
              ButtonSegment(
                value: HomeSection.tasks,
                label: Text('Tasks'),
                icon: Icon(Icons.task_alt),
              ),
              ButtonSegment(
                value: HomeSection.items,
                label: Text('Market'),
                icon: Icon(Icons.shopping_cart),
              ),
            ],
            selected: {ui.section},
            onSelectionChanged: (s) =>
                context.read<UiProvider>().setSection(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),

          // Member filter
          Text(
            'Filter by member',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: ui.filterMember,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All members')),
              ...family.map((m) => DropdownMenuItem(value: m, child: Text(m))),
            ],
            onChanged: (v) => context.read<UiProvider>().setMember(v),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // Status filter (Tasks OR Market'a göre)
          if (ui.section == HomeSection.tasks) ...[
            Text('Task status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            SegmentedButton<TaskViewFilter>(
              segments: const [
                ButtonSegment(
                  value: TaskViewFilter.pending,
                  label: Text('Pending'),
                  icon: Icon(Icons.radio_button_unchecked),
                ),
                ButtonSegment(
                  value: TaskViewFilter.completed,
                  label: Text('Completed'),
                  icon: Icon(Icons.check_circle),
                ),
              ],
              selected: {ui.taskFilter},
              onSelectionChanged: (s) =>
                  context.read<UiProvider>().setTaskFilter(s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear completed'),
                onPressed: () =>
                    taskProv.clearCompleted(forMember: ui.filterMember),
              ),
            ),
          ] else ...[
            Text(
              'Market status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            SegmentedButton<ItemViewFilter>(
              segments: const [
                ButtonSegment(
                  value: ItemViewFilter.toBuy,
                  label: Text('To buy'),
                  icon: Icon(Icons.shopping_bag),
                ),
                ButtonSegment(
                  value: ItemViewFilter.bought,
                  label: Text('Bought'),
                  icon: Icon(Icons.check_circle),
                ),
              ],
              selected: {ui.itemFilter},
              onSelectionChanged: (s) =>
                  context.read<UiProvider>().setItemFilter(s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear bought'),
                onPressed: () =>
                    itemProv.clearBought(forMember: ui.filterMember),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Divider(),
          const SizedBox(height: 8),
          Text(
            'Debug / Notifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  await NotificationService.requestPermissions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permission requested (if needed)'),
                    ),
                  );
                },
                child: const Text('Request permission'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await NotificationService.debugTestIn30s();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scheduled: 30s test notification'),
                    ),
                  );
                },
                child: const Text('Test notification (30s)'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await NotificationService.debugWeeklyIn1Minute();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scheduled: weekly debug (≈1 min)'),
                    ),
                  );
                },
                child: const Text('Test weekly (+1 min)'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Apply & Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
