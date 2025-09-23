import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/item.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../widgets/swipe_bg.dart';
import '../member_assign_sheet.dart';

class ItemListView extends StatelessWidget {
  const ItemListView({super.key});

  @override
  Widget build(BuildContext context) {
    final itemProv = context.watch<ItemCloudProvider>();
    final items = itemProv.items;

    if (items.isEmpty) {
      return const Text('No items yet');
    }
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final it = items[i];
        return Dismissible(
          key: ValueKey('item-${it.key ?? it.name}-${it.hashCode}'),
          background: const SwipeBg(
            color: Colors.green,
            icon: Icons.check,
            align: Alignment.centerLeft,
          ),
          secondaryBackground: const SwipeBg(
            color: Colors.red,
            icon: Icons.delete,
            align: Alignment.centerRight,
          ),
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              context.read<ItemCloudProvider>().toggleItem(it, !it.bought);
              return false;
            } else {
              final copy = Item(
                it.name,
                bought: it.bought,
                assignedToUid: it.assignedToUid,
              );
              context.read<ItemCloudProvider>().removeItem(it);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Item deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () =>
                        context.read<ItemCloudProvider>().addItem(copy),
                  ),
                ),
              );
              return true;
            }
          },
          child: StreamBuilder<Map<String, String>>(
            stream: dictStream,
            builder: (_, snap) {
              final dict = snap.data ?? const <String, String>{};
              final uid = it.assignedToUid;
              final display = (uid == null || uid.isEmpty)
                  ? 'Unassigned'
                  : (dict[uid] ?? 'Member');
              return ListTile(
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -2,
                ),
                leading: Checkbox(
                  value: it.bought,
                  onChanged: (v) => context
                      .read<ItemCloudProvider>()
                      .toggleItem(it, v ?? false),
                ),
                title: Text(
                  it.name,
                  overflow: TextOverflow.ellipsis,
                  style: it.bought
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: (display == 'Unassigned')
                    ? null
                    : Text('👤 $display'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Assign',
                      icon: const Icon(Icons.person_add_alt),
                      onPressed: () => _showAssignItemSheet(context, it),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showRenameItemDialog(context, it),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: S.delete,
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () =>
                          context.read<ItemCloudProvider>().removeItem(it),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRenameItemDialog(BuildContext context, Item item) {
    final ctrl = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Item name',
            isDense: true,
          ),
          onSubmitted: (_) {
            context.read<ItemCloudProvider>().renameItem(item, ctrl.text);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<ItemCloudProvider>().renameItem(item, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAssignItemSheet(BuildContext context, Item item) {
    MemberAssignSheet.show(
      context,
      title: 'Assign item',
      nullLabel: 'No one',
      initial: item.assignedToUid,
      onSave: (picked) {
        context.read<ItemCloudProvider>().updateAssignment(item, picked);
      },
    );
  }
}
