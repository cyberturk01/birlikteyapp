import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_template.dart';
import '../../providers/templates_provider.dart';

class TemplateEditorPage extends StatefulWidget {
  final UserTemplate? initial; // null ise yeni oluşturma

  const TemplateEditorPage({super.key, this.initial});

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _taskCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _weeklyTitleCtrl = TextEditingController();
  String _weeklyDay = 'Monday';

  late List<String> _tasks;
  late List<String> _items;
  late List<WeeklyEntry> _weekly;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _name.text = init?.name ?? '';
    _desc.text = init?.description ?? '';
    _tasks = List<String>.from(init?.tasks ?? const []);
    _items = List<String>.from(init?.items ?? const []);
    _weekly = List<WeeklyEntry>.from(init?.weekly ?? const []);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _taskCtrl.dispose();
    _itemCtrl.dispose();
    _weeklyTitleCtrl.dispose();
    super.dispose();
  }

  void _addTask() {
    final t = _taskCtrl.text.trim();
    if (t.isEmpty) return;
    if (!_tasks.any((e) => e.toLowerCase() == t.toLowerCase())) {
      setState(() => _tasks.add(t));
    }
    _taskCtrl.clear();
  }

  void _addItem() {
    final t = _itemCtrl.text.trim();
    if (t.isEmpty) return;
    if (!_items.any((e) => e.toLowerCase() == t.toLowerCase())) {
      setState(() => _items.add(t));
    }
    _itemCtrl.clear();
  }

  void _addWeekly() {
    final title = _weeklyTitleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _weekly.add(WeeklyEntry(_weeklyDay, title)));
    _weeklyTitleCtrl.clear();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final prov = context.read<TemplatesProvider>();
    if (widget.initial == null) {
      await prov.add(
        UserTemplate(
          name: name,
          description: _desc.text.trim(),
          tasks: _tasks,
          items: _items,
          weekly: _weekly,
        ),
      );
    } else {
      await prov.updateTemplate(
        widget.initial!,
        name: name,
        description: _desc.text.trim(),
        tasks: _tasks,
        items: _items,
        weekly: _weekly,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _chipList<T>({
    required List<T> list,
    required String Function(T) label,
    required void Function(int) onDeleteAt,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(list.length, (i) {
        return Chip(
          label: Text(label(list[i])),
          onDeleted: () => setState(() => onDeleteAt(i)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'New Template' : 'Edit Template'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          Text('Tasks', style: t.textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add a task',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _chipList<String>(
            list: _tasks,
            label: (s) => s,
            onDeleteAt: (i) => _tasks.removeAt(i),
          ),

          const SizedBox(height: 16),
          Text('Items', style: t.textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add an item',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _chipList<String>(
            list: _items,
            label: (s) => s,
            onDeleteAt: (i) => _items.removeAt(i),
          ),

          const SizedBox(height: 16),
          Text('Weekly', style: t.textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              DropdownButton<String>(
                value: _weeklyDay,
                items:
                    const [
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday',
                        ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (v) => setState(() => _weeklyDay = v ?? 'Monday'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _weeklyTitleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Weekly task title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addWeekly(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addWeekly,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _chipList<WeeklyEntry>(
            list: _weekly,
            label: (e) => '${e.day}: ${e.title}',
            onDeleteAt: (i) => _weekly.removeAt(i),
          ),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save Template'),
          ),
        ],
      ),
    );
  }
}
