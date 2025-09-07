// lib/pages/config/config_page.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ui_provider.dart';
import '../../services/notification_service.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();

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
            onPressed: () async {
              await context.read<UiProvider>().resetSettings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
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
          // === Reminders ===
          Text('Reminders', style: Theme.of(context).textTheme.titleMedium),
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

          // Exact alarm ayarı (Android)
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

          // === Theme ===
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
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

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // === Debug / Notifications ===
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
