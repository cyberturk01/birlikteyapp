import 'package:birlikteyapp/pages/templates/template_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_templates.dart';
import '../../models/user_template.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/templates_provider.dart';
import '../../providers/weekly_cloud_provider.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  String? _assignToUid; // opsiyonel atama
  bool _skipDuplicates = true; // tasks/items için

  @override
  Widget build(BuildContext context) {
    final userTemplates = context.watch<TemplatesProvider>().all;
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: LayoutBuilder(
        builder: (context, c) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;

                  // Ekrana göre dropdown hedef genişliği
                  final double ddWidth = (maxW < 400)
                      ? maxW // çok dar telefon: tam genişlik
                      : (maxW < 800)
                      ? 220 // orta ekran
                      : 300; // geniş ekran

                  return Align(
                    alignment: Alignment.centerLeft, // satırı sola sabitle
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ready Templates',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: ddWidth),
                          child: StreamBuilder<Map<String, String>>(
                            stream: dictStream,
                            builder: (_, snap) {
                              final dict =
                                  snap.data ?? const <String, String>{};
                              final items = <DropdownMenuItem<String?>>[
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Select ...'),
                                ),
                                ...dict.entries.map(
                                  (e) => DropdownMenuItem<String?>(
                                    value: e.key, // <-- UID
                                    child: Text(e.value), // <-- label
                                  ),
                                ),
                              ];

                              // seçili UID dict’te yoksa null’a düş
                              final value = dict.containsKey(_assignToUid)
                                  ? _assignToUid
                                  : null;

                              return ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: ddWidth),
                                child: DropdownButtonFormField<String?>(
                                  value: value,
                                  isExpanded: true,
                                  items: items,
                                  onChanged: (v) =>
                                      setState(() => _assignToUid = v),
                                  decoration: const InputDecoration(
                                    labelText: 'Assign to (optional)',
                                    border: OutlineInputBorder(gapPadding: 2),
                                    isDense: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _skipDuplicates = !_skipDuplicates,
                          ),
                          icon: Icon(
                            _skipDuplicates
                                ? Icons.check_box_outline_blank
                                : Icons.check_box,
                          ),
                          label: const Text('Skip duplicates'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'My Templates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TemplateEditorPage(),
                        ),
                      );
                      // Geri gelince provider notify ediyor, o yüzden setState gerek yok
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Create Template',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              if (userTemplates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'You don’t have any templates yet.\nTap “Create Template” to create one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: userTemplates
                      .map(
                        (utpl) => _buildUserCard(context, utpl),
                      ) // <-- EDIT/DELETE burada
                      .toList(),
                ),

              const SizedBox(height: 8),

              // Library sekmesi:
              Text(
                'Ready Templates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppTemplates.all
                    .map((tpl) => _buildLibraryCard(context, tpl))
                    .toList(),
              ),
              // --- Kartlar (Wrap: overflow yok) ---
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // WeeklyEntry ↔︎ record (String,String) yardımcıları
  List<WeeklyEntry> recordsToWeeklyEntries(List<(String, String)> records) {
    return records.map((r) => WeeklyEntry(r.$1, r.$2)).toList();
  }

  List<(String, String)> weeklyEntriesToRecords(List<WeeklyEntry> entries) {
    return entries.map<(String, String)>((e) => (e.day, e.title)).toList();
  }

  void _applyUserTemplate(BuildContext context, UserTemplate utpl) async {
    final taskProv = context.read<TaskCloudProvider>();
    final itemProv = context.read<ItemCloudProvider>();
    final weeklyProv = context.read<WeeklyCloudProvider>();

    // Bunlar senin var olan bulk metodlarınla eşleştirilmeli.
    final createdTasks = await taskProv.addTasksBulkCloud(
      utpl.tasks,
      assignedToUid: _assignToUid,
    );

    final createdItems = await itemProv.addItemsBulkCloud(
      utpl.items,
      assignedToUid: _assignToUid,
    );

    final createdWeekly = await weeklyProv.addWeeklyBulk(
      // WeeklyEntry → (day,title) record
      weeklyEntriesToRecords(utpl.weekly),
      assignedToUid: _assignToUid,
    );

    final total =
        createdTasks.length + createdItems.length + createdWeekly.length;

    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to add (duplicates or empty)')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $total from "${utpl.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            taskProv.removeManyTasks(createdTasks);
            itemProv.removeManyItems(createdItems);
            weeklyProv.removeManyWeekly(await createdWeekly);
          },
        ),
      ),
    );
  }

  void _previewUserTemplate(BuildContext context, UserTemplate utpl) {
    showDialog(
      context: context,
      builder: (_) {
        final t = Theme.of(context);

        Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            text,
            style: t.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );

        Widget chipWrap(List<Widget> chips) =>
            Wrap(spacing: 6, runSpacing: 6, children: chips);

        final taskChips = utpl.tasks
            .map(
              (s) => Chip(label: Text(s), visualDensity: VisualDensity.compact),
            )
            .toList();

        final itemChips = utpl.items
            .map(
              (s) => Chip(label: Text(s), visualDensity: VisualDensity.compact),
            )
            .toList();

        // Weekly'yi "Mon — Take out trash" gibi göster
        final weeklyChips = utpl.weekly
            .map(
              (e) => Chip(
                label: Text('${e.day} — ${e.title}'),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList();

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.view_compact),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  utpl.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (utpl.description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        utpl.description,
                        style: t.textTheme.bodyMedium,
                      ),
                    ),

                  // Tasks
                  sectionTitle('Tasks (${utpl.tasks.length})'),
                  if (utpl.tasks.isEmpty)
                    Text('No tasks', style: t.textTheme.bodySmall)
                  else
                    chipWrap(taskChips),

                  // Items
                  sectionTitle('Items (${utpl.items.length})'),
                  if (utpl.items.isEmpty)
                    Text('No items', style: t.textTheme.bodySmall)
                  else
                    chipWrap(itemChips),

                  // Weekly
                  sectionTitle('Weekly (${utpl.weekly.length})'),
                  if (utpl.weekly.isEmpty)
                    Text('No weekly entries', style: t.textTheme.bodySmall)
                  else
                    chipWrap(weeklyChips),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // My Templates (kullanıcı) kartı — UserTemplate
  Widget _buildUserCard(BuildContext context, UserTemplate utpl) {
    final tCount = utpl.tasks.length;
    final iCount = utpl.items.length;
    final wCount = utpl.weekly.length;

    return SizedBox(
      width: 400,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                utpl.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                utpl.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  if (tCount > 0) ...[
                    const Icon(Icons.task_alt, size: 16),
                    const SizedBox(width: 4),
                    Text('$tCount tasks'),
                  ],
                  if (tCount > 0 && iCount > 0) const SizedBox(width: 10),
                  if (iCount > 0) ...[
                    const Icon(Icons.shopping_cart, size: 16),
                    const SizedBox(width: 4),
                    Text('$iCount items'),
                  ],
                  if ((tCount + iCount) > 0 && wCount > 0)
                    const SizedBox(width: 10),
                  if (wCount > 0) ...[
                    const Icon(Icons.calendar_month, size: 16),
                    const SizedBox(width: 4),
                    Text('$wCount weekly'),
                  ],
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        _applyUserTemplate(context, utpl), // <-- UserTemplate
                    child: const Text('Apply'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TemplateEditorPage(
                            initial: utpl,
                          ), // <-- UserTemplate
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      final prov = context.read<TemplatesProvider>();
                      final removedTasks = utpl.tasks.toList();
                      final removedItems = utpl.items.toList();
                      final removedWeekly = utpl.weekly
                          .map((e) => WeeklyEntry(e.day, e.title))
                          .toList();
                      await prov.remove(utpl); // <-- UserTemplate

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Template "${utpl.name}" deleted'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              await prov.add(
                                UserTemplate(
                                  name: utpl.name,
                                  description: utpl.description,
                                  tasks: removedTasks,
                                  items: removedItems,
                                  weekly: removedWeekly, // WeeklyEntry listesi
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Preview',
                    onPressed: () =>
                        _previewUserTemplate(context, utpl), // <-- UserTemplate
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Library (hazır sabitler) kartı — TemplatePack
  Widget _buildLibraryCard(BuildContext context, TemplatePack tpl) {
    final tCount = tpl.tasks.length;
    final iCount = tpl.items.length;
    final wCount = tpl.weekly.length;

    return SizedBox(
      width: 400,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tpl.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tpl.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  if (tCount > 0) ...[
                    const Icon(Icons.task_alt, size: 16),
                    const SizedBox(width: 4),
                    Text('$tCount tasks'),
                  ],
                  if (tCount > 0 && iCount > 0) const SizedBox(width: 10),
                  if (iCount > 0) ...[
                    const Icon(Icons.shopping_cart, size: 16),
                    const SizedBox(width: 4),
                    Text('$iCount items'),
                  ],
                  if ((tCount + iCount) > 0 && wCount > 0)
                    const SizedBox(width: 10),
                  if (wCount > 0) ...[
                    const Icon(Icons.calendar_month, size: 16),
                    const SizedBox(width: 4),
                    Text('$wCount weekly'),
                  ],
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        _applyAll(context, tpl), // <-- TemplatePack
                    child: const Text('Apply'),
                  ),
                  const SizedBox(width: 8),
                  if (wCount > 0)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _applyWeeklyOnly(context, tpl), // <-- TemplatePack
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Weekly only'),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Preview',
                    onPressed: () =>
                        _previewTemplate(context, tpl), // <-- TemplatePack
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyAll(BuildContext context, TemplatePack tpl) async {
    final taskProv = context.read<TaskCloudProvider>();
    final itemProv = context.read<ItemCloudProvider>();
    final weeklyProv = context.read<WeeklyCloudProvider>();

    final createdTasks = await taskProv.addTasksBulkCloud(
      tpl.tasks,
      assignedToUid: _assignToUid,
    );
    final createdItems = await itemProv.addItemsBulkCloud(
      tpl.items,
      assignedToUid: _assignToUid,
    );
    final createdWeekly = await weeklyProv.addWeeklyBulk(
      tpl.weekly,
      assignedToUid: _assignToUid,
    );

    final total =
        createdTasks.length + createdItems.length + createdWeekly.length;
    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to add (all duplicates or empty)'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $total from "${tpl.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            taskProv.removeManyTasks(createdTasks);
            itemProv.removeManyItems(createdItems);
            weeklyProv.removeManyWeekly(createdWeekly);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _applyWeeklyOnly(BuildContext context, TemplatePack tpl) async {
    final weeklyProv = context.read<WeeklyCloudProvider>();

    // Future<List<...>> -> await
    final createdWeekly = await weeklyProv.addWeeklyBulk(
      tpl.weekly,
      assignedToUid: _assignToUid,
    );

    if (createdWeekly.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No weekly entries to add')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${createdWeekly.length} weekly entries'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => weeklyProv.removeManyWeekly(createdWeekly),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Küçük önizleme (opsiyonel)
  void _previewTemplate(BuildContext context, TemplatePack tpl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tpl.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tpl.tasks.isNotEmpty) ...[
                const Text(
                  'Tasks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...tpl.tasks.map((e) => Text('• $e')),
                const SizedBox(height: 10),
              ],
              if (tpl.items.isNotEmpty) ...[
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...tpl.items.map((e) => Text('• $e')),
                const SizedBox(height: 10),
              ],
              if (tpl.weekly.isNotEmpty) ...[
                const Text(
                  'Weekly',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...tpl.weekly.map((e) => Text('• ${e.$1}: ${e.$2}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
