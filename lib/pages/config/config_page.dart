// lib/pages/config/config_page.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:birlikteyapp/widgets/manage/section_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.configTitle, // "Configuration"
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              t.configSubtitle, // "Customize theme, reminders, and family filters."
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
          // === Family Invite ===
          SectionTitle(t.familyInviteCode),
          const SizedBox(height: 8),
          const InviteCodeCard(),
          const SizedBox(height: 8),
          const Divider(height: 24),

          // === Appearance ===
          SectionTitle(t.appearance),
          const SizedBox(height: 6),
          // Tema modu
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(t.themeSystem), // "System"
                icon: const Icon(Icons.phone_android),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(t.themeLight), // "Light"
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(t.themeDark), // "Dark"
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {ui.themeMode},
            onSelectionChanged: (s) =>
                context.read<UiProvider>().setThemeMode(s.first),
            showSelectedIcon: false,
          ),

          const SizedBox(height: 8),
          const Divider(height: 24),
          // Dil seçici
          DropdownButtonFormField<Locale>(
            value: ui.locale ?? Localizations.localeOf(context),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('tr'), child: Text('Türkçe')),
              DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
            ],
            onChanged: (loc) {
              if (loc != null) {
                context.read<UiProvider>().setLocale(loc);
              }
            },
            decoration: InputDecoration(
              labelText: t.language, // "Language"
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 24),

          // === App color ===
          const SizedBox(height: 8),
          DropdownButtonFormField<BrandSeed>(
            value: ui.brand,
            isExpanded: true,
            items: BrandSeed.values.map((b) {
              return DropdownMenuItem(
                value: b,
                child: Row(
                  children: [
                    b.swatch(size: 20),
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
            decoration: InputDecoration(
              labelText: t.appColor,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 24),
          const SizedBox(height: 6),
          // === Templates ===
          SectionTitle(t.templates),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: Text(t.templates), // "Templates"
            subtitle: Text(
              t.templatesSubtitle,
            ), // "One-tap task & market packs"
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

          // === Notifications ===
          SectionTitle(t.notifications),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  await NotificationService.requestPermissions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.permissionRequested,
                      ), // "Permission requested (if needed)"
                    ),
                  );
                },
                child: Text(t.requestPermission),
              ),
              Tooltip(
                message: t
                    .preciseAlarmsTooltip, // "Open system setting to allow precise alarms"
                child: FilledButton.tonal(
                  onPressed: () async {
                    if (!Platform.isAndroid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t.androidOnly,
                          ), // "This setting is Android-only"
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
                        SnackBar(
                          content: Text('${t.couldNotOpenSettings}: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(t.enableExactAlarms),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(t.menuPrivacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/privacy'),
                // veya: onTap: openPrivacyInBrowser,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
