import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/ui_provider.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;
    final taskProv = context.read<TaskProvider>();
    final itemProv = context.read<ItemProvider>();

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
