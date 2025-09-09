import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';

const String kAllFilter = '__ALL__';
const String kNoOne = '__NONE__';

/// Panel üstündeki küçük “hızlı ekle” satırı (input + kişi seçimi + Add)
class _QuickAddRow extends StatefulWidget {
  final String hint;
  final List<String> familyMembers;
  final String? presetAssignee; // panel kişi filtresi varsa otomatik atama
  final void Function(String text, String? assignedTo) onSubmit;

  const _QuickAddRow({
    required this.hint,
    required this.familyMembers,
    required this.onSubmit,
    this.presetAssignee,
  });

  @override
  State<_QuickAddRow> createState() => _QuickAddRowState();
}

class _QuickAddRowState extends State<_QuickAddRow> {
  final TextEditingController _c = TextEditingController();
  String _selected = kNoOne; // sentinel (null yerine)

  @override
  void initState() {
    super.initState();
    if (widget.presetAssignee != null &&
        widget.presetAssignee!.trim().isNotEmpty) {
      _selected = widget.presetAssignee!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // input
        Expanded(
          child: TextField(
            controller: _c,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.add),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        // assignee
        DropdownButton<String>(
          value: _selected,
          hint: const Text('Assign'),
          items: [
            const DropdownMenuItem(value: kNoOne, child: Text('No one')),
            ...widget.familyMembers.map(
              (m) => DropdownMenuItem(value: m, child: Text(m)),
            ),
          ],
          onChanged: (v) => setState(() => _selected = v ?? kNoOne),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _submit, child: const Text(S.add)),
      ],
    );
  }

  void _submit() {
    final text = _c.text.trim();
    final assigned = (_selected == kNoOne) ? null : _selected;
    if (text.isNotEmpty) {
      widget.onSubmit(text, assigned);
      _c.clear();
      // panel kişi filtresi yoksa, seçim kNoOne'a dönebilir
      if (widget.presetAssignee == null || widget.presetAssignee!.isEmpty) {
        setState(() => _selected = kNoOne);
      }
    }
  }
}

class _TasksMiniPanel extends StatefulWidget {
  final String? filterMember; // null = All
  const _TasksMiniPanel({Key? key, this.filterMember}) : super(key: key);

  @override
  State<_TasksMiniPanel> createState() => _TasksMiniPanelState();
}

enum _TaskStatus { all, pending, completed }

class _TasksMiniPanelState extends State<_TasksMiniPanel> {
  _TaskStatus _status = _TaskStatus.all;

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;

    // Kişi filtresi
    List<Task> base = widget.filterMember == null
        ? taskProv.tasks
        : taskProv.tasks
              .where((t) => (t.assignedTo ?? '') == widget.filterMember)
              .toList();

    // Durum filtresi
    List<Task> list;
    switch (_status) {
      case _TaskStatus.pending:
        list = base.where((t) => !t.completed).toList();
        break;
      case _TaskStatus.completed:
        list = base.where((t) => t.completed).toList();
        break;
      default:
        list = base;
    }

    final pendingCount = base.where((t) => !t.completed).length;
    final completedCount = base.where((t) => t.completed).length;

    return Column(
      children: [
        // DURUM ÇUBUĞU
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SegmentedButton<_TaskStatus>(
            segments: [
              const ButtonSegment(
                value: _TaskStatus.all,
                icon: Icon(Icons.all_inbox),
                label: Text('All'),
              ),
              ButtonSegment(
                value: _TaskStatus.pending,
                icon: const Icon(Icons.radio_button_unchecked),
                label: Text('Pending ($pendingCount)'),
              ),
              ButtonSegment(
                value: _TaskStatus.completed,
                icon: const Icon(Icons.check_circle),
                label: Text('Completed ($completedCount)'),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
            multiSelectionEnabled: false,
            showSelectedIcon: false,
          ),
        ),

        // QUICK ADD — kart içinde net ayrım
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _QuickAddRow(
                hint: widget.filterMember == null
                    ? 'Add task…'
                    : 'Add task for ${widget.filterMember}…',
                familyMembers: family, // sadece mevcut üyeler
                presetAssignee: widget.filterMember,
                onSubmit: (text, assigned) {
                  final t = text.trim();
                  if (t.isEmpty) return;
                  // preset varsa assigned’ı override et
                  final target = widget.filterMember ?? assigned;
                  if (target == null) return; // kimse seçilmediyse ekleme
                  context.read<TaskProvider>().addTask(
                    Task(t, assignedTo: target),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        const Divider(height: 1),

        // CLEAR butonu (yalnız completed görünümünde)
        if (_status == _TaskStatus.completed && list.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear completed'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear completed tasks?'),
                      content: Text(
                        widget.filterMember == null
                            ? 'This will delete all completed tasks.'
                            : 'This will delete completed tasks for ${widget.filterMember}.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(S.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    context.read<TaskProvider>().clearCompleted(
                      forMember: widget.filterMember,
                    );
                  }
                },
              ),
            ),
          ),

        // LİSTE
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No tasks'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final task = list[index];
                    return CheckboxListTile(
                      value: task.completed,
                      onChanged: (v) => context.read<TaskProvider>().toggleTask(
                        task,
                        v ?? false,
                      ),
                      title: Text(
                        task.name +
                            (task.assignedTo != null
                                ? ' (${task.assignedTo})'
                                : ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'assign') {
                            _showAssignTaskSheet(context, task);
                          } else if (val == 'delete') {
                            context.read<TaskProvider>().removeTask(task);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'assign',
                            child: Text('Assign / Change'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text(S.delete)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAssignTaskSheet(BuildContext context, Task task) {
    final family = context.read<FamilyProvider>().familyMembers;
    final prov = context.read<TaskProvider>();
    String? selected = task.assignedTo;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assign to',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selected,
              items: [
                const DropdownMenuItem(value: null, child: Text('No one')),
                ...family.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m)),
                ),
              ],
              onChanged: (v) => selected = v,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                prov.updateAssignment(
                  task,
                  (selected != null && selected!.trim().isNotEmpty)
                      ? selected
                      : null,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketMiniPanel extends StatefulWidget {
  final String? filterMember; // null = All
  const _MarketMiniPanel({super.key, this.filterMember});

  @override
  State<_MarketMiniPanel> createState() => _MarketMiniPanelState();
}

enum _ItemStatus { all, toBuy, bought }

class _MarketMiniPanelState extends State<_MarketMiniPanel> {
  _ItemStatus _status = _ItemStatus.all;

  @override
  Widget build(BuildContext context) {
    final itemProv = context.watch<ItemProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;

    List<Item> base = widget.filterMember == null
        ? itemProv.items
        : itemProv.items
              .where((i) => (i.assignedTo ?? '') == widget.filterMember)
              .toList();

    List<Item> list;
    switch (_status) {
      case _ItemStatus.toBuy:
        list = base.where((i) => !i.bought).toList();
        break;
      case _ItemStatus.bought:
        list = base.where((i) => i.bought).toList();
        break;
      default:
        list = base;
    }

    final toBuyCount = base.where((i) => !i.bought).length;
    final boughtCount = base.where((i) => i.bought).length;

    return Column(
      children: [
        // DURUM ÇUBUĞU
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SegmentedButton<_ItemStatus>(
            segments: [
              const ButtonSegment(
                value: _ItemStatus.all,
                icon: Icon(Icons.all_inbox),
                label: Text('All'),
              ),
              ButtonSegment(
                value: _ItemStatus.toBuy,
                icon: const Icon(Icons.shopping_basket),
                label: Text('To buy ($toBuyCount)'),
              ),
              ButtonSegment(
                value: _ItemStatus.bought,
                icon: const Icon(Icons.check_circle),
                label: Text('Bought ($boughtCount)'),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
            multiSelectionEnabled: false,
            showSelectedIcon: false,
          ),
        ),

        // QUICK ADD — kart içinde
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _QuickAddRow(
                hint: widget.filterMember == null
                    ? 'Add item…'
                    : 'Add item for ${widget.filterMember}…',
                familyMembers: family,
                presetAssignee: widget.filterMember,
                onSubmit: (text, assigned) {
                  if (text.trim().isEmpty) return;
                  context.read<ItemProvider>().addItem(
                    Item(text.trim(), assignedTo: assigned),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        const Divider(height: 1),

        // CLEAR (bought görünümünde)
        if (_status == _ItemStatus.bought && list.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear bought'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear bought items?'),
                      content: Text(
                        widget.filterMember == null
                            ? 'This will delete all bought items.'
                            : 'This will delete bought items for ${widget.filterMember}.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(S.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    context.read<ItemProvider>().clearBought(
                      forMember: widget.filterMember,
                    );
                  }
                },
              ),
            ),
          ),

        // LİSTE
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No items'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final it = list[index];
                    return CheckboxListTile(
                      value: it.bought,
                      onChanged: (v) => context.read<ItemProvider>().toggleItem(
                        it,
                        v ?? false,
                      ),
                      title: Text(
                        it.name +
                            (it.assignedTo != null
                                ? ' (${it.assignedTo})'
                                : ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'assign') {
                            _showAssignItemSheet(context, it);
                          } else if (val == 'delete') {
                            context.read<ItemProvider>().removeItem(it);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'assign',
                            child: Text('Assign / Change'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text(S.delete)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAssignItemSheet(BuildContext context, Item item) {
    final family = context.read<FamilyProvider>().familyMembers;
    final prov = context.read<ItemProvider>();
    String? selected = item.assignedTo;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assign to',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selected,
              items: [
                const DropdownMenuItem(value: null, child: Text('No one')),
                ...family.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m)),
                ),
              ],
              onChanged: (v) => selected = v,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                prov.updateAssignment(
                  item,
                  (selected != null && selected!.trim().isNotEmpty)
                      ? selected
                      : null,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
