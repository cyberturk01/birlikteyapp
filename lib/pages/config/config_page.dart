// lib/pages/config/config_page.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ui_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/brand_seed.dart';
import '../../widgets/invite_code_card.dart';
import '../templates/templates_page.dart';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Customize theme, reminders, and family filters.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Family Invitation Code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const InviteCodeCard(),
          const SizedBox(height: 8),
          const Divider(height: 24),
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
          const SizedBox(height: 8),
          const Divider(height: 24),

          // === Theme ===
          Text('App color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<BrandSeed>(
            value: context.watch<UiProvider>().brand,
            isExpanded: true,
            items: BrandSeed.values.map((b) {
              return DropdownMenuItem(
                value: b,
                child: Row(
                  children: [
                    b.swatch(size: 20), // küçük renk kutusu
                    const SizedBox(width: 8),
                    Text(b.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (b) {
              if (b != null) {
                context.read<UiProvider>().setBrand(b);
              }
            },
            decoration: const InputDecoration(
              labelText: "App color",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 16),
          Text('Templates', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Templates'),
            subtitle: const Text('One-tap task & market packs'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplatesPage()),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 8),

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
              Tooltip(
                message: 'Open system setting to allow precise alarms',
                child: FilledButton.tonal(
                  onPressed: () async {
                    if (!Platform.isAndroid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This setting is Android-only'),
                        ),
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
                  child: const Text('Enable exact alarms'),
                ),
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

class _BrandSwatch extends StatelessWidget {
  final BrandSeed brand;
  final bool selected;
  final VoidCallback onTap;

  const _BrandSwatch({
    super.key,
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = brand.seed; // BrandSeed extension’dan
    final cs = Theme.of(context).colorScheme;
    final label = brand.label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: cs.surfaceContainerLow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(color: color),
            const SizedBox(width: 8),
            Text(
              brand.name, // enum ismi: teal/coral/deepPurple/forest
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
