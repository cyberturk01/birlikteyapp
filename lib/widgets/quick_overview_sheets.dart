import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/task.dart';
import '../providers/family_provider.dart';
import '../providers/item_cloud_provider.dart';
import '../providers/task_cloud_provider.dart';

enum _AssigneeFilter { all, mine, unassigned }

Future<void> showPendingTasksSheet(BuildContext context) async {
  await _showGroupedSheet<Task>(
    context: context,
    titleBuilder: (ctx, list) => 'Pending tasks (${list.length})',
    // kaynak (canlı)
    sourceSelector: (ctx) =>
        context.watch<TaskCloudProvider>().tasks.where((t) => !t.completed),
    // aksiyonlar
    leadingIcon: Icons.radio_button_unchecked,
    onTogglePrimary: (ctx, t) =>
        ctx.read<TaskCloudProvider>().toggleTask(t, true),
    onDelete: (ctx, t) => ctx.read<TaskCloudProvider>().removeTask(t),
    // isimlendirme
    getName: (t) => t.name,
    getAssignedUid: (t) => t.assignedToUid,
    // başlık
    sectionTitle: 'Tasks',
  );
}

Future<void> showToBuyItemsSheet(BuildContext context) async {
  await _showGroupedSheet<Item>(
    context: context,
    titleBuilder: (ctx, list) => 'To buy (${list.length})',
    sourceSelector: (ctx) =>
        context.watch<ItemCloudProvider>().items.where((i) => !i.bought),
    leadingIcon: Icons.radio_button_unchecked,
    onTogglePrimary: (ctx, it) =>
        ctx.read<ItemCloudProvider>().toggleItem(it, true),
    onDelete: (ctx, it) => ctx.read<ItemCloudProvider>().removeItem(it),
    getName: (it) => it.name,
    getAssignedUid: (it) => it.assignedToUid,
    sectionTitle: 'Market',
  );
}

/// Generic grouped bottom sheet used by both Tasks & Items.
/// T = Task | Item
Future<void> _showGroupedSheet<T>({
  required BuildContext context,
  required String Function(BuildContext, List<T>) titleBuilder,
  required Iterable<T> Function(BuildContext) sourceSelector,
  required String Function(T) getName,
  required String? Function(T) getAssignedUid,
  required IconData leadingIcon,

  required void Function(BuildContext, T) onTogglePrimary,
  required void Function(BuildContext, T) onDelete,
  required String sectionTitle,
}) async {
  _AssigneeFilter filter = _AssigneeFilter.all;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final dictStream = context
              .read<FamilyProvider>()
              .watchMemberDirectory();

          // ham liste
          final raw = sourceSelector(ctx).toList()
            ..sort(
              (a, b) =>
                  getName(a).toLowerCase().compareTo(getName(b).toLowerCase()),
            );

          // current user uid (Mine filtresi için)
          final myUid = FirebaseAuth.instance.currentUser?.uid;

          return StreamBuilder<Map<String, String>>(
            stream: dictStream, // {uid: label}
            builder: (_, snap) {
              final dict = snap.data ?? const <String, String>{};
              // filtre
              bool keepByFilter(T e) {
                final uid = (getAssignedUid(e) ?? '').trim();
                switch (filter) {
                  case _AssigneeFilter.all:
                    return true;
                  case _AssigneeFilter.mine:
                    return (myUid != null && uid == myUid);
                  case _AssigneeFilter.unassigned:
                    return uid.isEmpty;
                }
              }

              final filtered = raw.where(keepByFilter).toList();

              // gruplama: anahtar = label ('Unassigned' fallback)
              final Map<String, List<T>> groups = {};
              for (final e in filtered) {
                final uid = (getAssignedUid(e) ?? '').trim();
                final key = uid.isEmpty
                    ? 'Unassigned'
                    : (dict[uid] ?? 'Member');
                (groups[key] ??= []).add(e);
              }
              final groupKeys = groups.keys.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

              // başlık ve action bar
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleBuilder(ctx, raw),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // filtre çipleri
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: filter == _AssigneeFilter.all,
                          onSelected: (_) =>
                              setLocal(() => filter = _AssigneeFilter.all),
                        ),
                        ChoiceChip(
                          label: const Text('Mine'),
                          selected: filter == _AssigneeFilter.mine,
                          onSelected: (_) =>
                              setLocal(() => filter = _AssigneeFilter.mine),
                        ),
                        ChoiceChip(
                          label: const Text('Unassigned'),
                          selected: filter == _AssigneeFilter.unassigned,
                          onSelected: (_) => setLocal(
                            () => filter = _AssigneeFilter.unassigned,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // içerik
                  Expanded(
                    child: (filtered.isEmpty)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                filter == _AssigneeFilter.unassigned
                                    ? 'No $sectionTitle in Unassigned'
                                    : 'Nothing here',
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: groupKeys.length,
                            itemBuilder: (_, idx) {
                              final key = groupKeys[idx];
                              final list = groups[key]!
                                ..sort(
                                  (a, b) => getName(a).toLowerCase().compareTo(
                                    getName(b).toLowerCase(),
                                  ),
                                );

                              return _GroupSection<T>(
                                title: key,
                                count: list.length,
                                leadingChar: key.isNotEmpty
                                    ? key.characters.first.toUpperCase()
                                    : '?',
                                child: Column(
                                  children: list
                                      .map(
                                        (e) => ListTile(
                                          dense: true,
                                          visualDensity: const VisualDensity(
                                            horizontal: -2,
                                            vertical: -2,
                                          ),
                                          leading: IconButton(
                                            tooltip: sectionTitle == 'Market'
                                                ? 'Mark as bought'
                                                : 'Mark as completed',
                                            icon: Icon(leadingIcon),
                                            onPressed: () =>
                                                onTogglePrimary(ctx, e),
                                          ),
                                          title: Text(
                                            getName(e),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: key == 'Unassigned'
                                              ? null
                                              : Text('👤 $key'),
                                          trailing: IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () => onDelete(ctx, e),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _GroupSection<T> extends StatelessWidget {
  final String title;
  final String leadingChar;
  final int count;
  final Widget child;

  const _GroupSection({
    required this.title,
    required this.leadingChar,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Theme(
      data: t.copyWith(
        dividerColor: t.dividerColor.withOpacity(0.08),
        listTileTheme: const ListTileThemeData(minVerticalPadding: 0),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(left: 12, right: 8),
        initiallyExpanded: true,
        leading: CircleAvatar(child: Text(leadingChar)),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$count ${count == 1 ? "item" : "items"}'),
        children: [child, const SizedBox(height: 6)],
      ),
    );
  }
}
