import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';

const String kAllFilter = '__ALL__';
const String kNoOne = '__NONE__';

/// Top-right quick panel açar
void showQuickPanel(BuildContext context, {String? personFilter}) {
  final size = MediaQuery.of(context).size;
  final double width = (size.width - 24).clamp(280.0, 420.0);
  final double height = (size.height - 24).clamp(360.0, 560.0);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Quick Panel',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, a1, a2) {
      return SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: SizedBox(
                width: width,
                height: height,
                child: Material(
                  type: MaterialType.card,
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: QuickPanelContent(initialFilter: personFilter),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.15, -0.05),
        end: Offset.zero,
      ).animate(anim),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class QuickPanelContent extends StatefulWidget {
  final String? initialFilter; // null => All
  const QuickPanelContent({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<QuickPanelContent> createState() => _QuickPanelContentState();
}

enum _PanelTab { tasks, items }

class _QuickPanelContentState extends State<QuickPanelContent> {
  String? _filterMember; // null => All
  _PanelTab _tab = _PanelTab.tasks;

  @override
  void initState() {
    super.initState();
    _filterMember = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>().familyMembers;

    return Column(
      children: [
        // ÜST BÖLÜM: kişi filtresi
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: DropdownButtonFormField<String>(
            value: _filterMember ?? kAllFilter,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Filter by person',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: kAllFilter, child: Text('All')),
              ...family.map((m) => DropdownMenuItem(value: m, child: Text(m))),
            ],
            onChanged: (val) => setState(
              () => _filterMember = (val == kAllFilter) ? null : val,
            ),
          ),
        ),

        // Toggle: Tasks / Market
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SegmentedButton<_PanelTab>(
            segments: const [
              ButtonSegment(
                value: _PanelTab.tasks,
                icon: Icon(Icons.task),
                label: Text('Tasks'),
              ),
              ButtonSegment(
                value: _PanelTab.items,
                icon: Icon(Icons.shopping_cart),
                label: Text('Market'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
            multiSelectionEnabled: false,
            showSelectedIcon: false,
          ),
        ),

        const Divider(height: 1),

        // İçerik (durum filtresi + quick add + liste, ilgili panel yönetir)
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _tab == _PanelTab.tasks
                ? _TasksMiniPanel(
                    key: const ValueKey('tasks'),
                    filterMember: _filterMember,
                  )
                : _MarketMiniPanel(
                    key: const ValueKey('items'),
                    filterMember: _filterMember,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Panel üstündeki küçük “hızlı ekle” satırı (input + kişi seçimi + Add)
class _QuickAddRow extends StatefulWidget {
  final String hint;
  final List<String> familyMembers;
  final String? presetAssignee; // panel kişi filtresi varsa otomatik atama
  final void Function(String text, String? assignedTo) onSubmit;

  const _QuickAddRow({
    Key? key,
    required this.hint,
    required this.familyMembers,
    required this.onSubmit,
    this.presetAssignee,
  }) : super(key: key);

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
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
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
            ).colorScheme.surfaceVariant.withOpacity(0.35),
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
                          child: const Text('Cancel'),
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
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
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
  const _MarketMiniPanel({Key? key, this.filterMember}) : super(key: key);

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
            ).colorScheme.surfaceVariant.withOpacity(0.35),
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
                          child: const Text('Cancel'),
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
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
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
