import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';

Future<void> showFamilyManager(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _FamilyManagerSheet(),
  );
}

class _FamilyManagerSheet extends StatefulWidget {
  const _FamilyManagerSheet({Key? key}) : super(key: key);

  @override
  State<_FamilyManagerSheet> createState() => _FamilyManagerSheetState();
}

class _FamilyManagerSheetState extends State<_FamilyManagerSheet> {
  final TextEditingController _memberCtrl = TextEditingController();

  @override
  void dispose() {
    _memberCtrl.dispose();
    super.dispose();
  }

  void _addMember(BuildContext context) {
    final familyProv = context.read<FamilyProvider>();
    final name = _memberCtrl.text.trim();
    if (name.isEmpty) return;

    final exists = familyProv.familyMembers.any(
      (m) => m.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This name already exists')));
      return;
    }

    familyProv.addMember(name); // void ise await yok
    _memberCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final familyProv = context.watch<FamilyProvider>();
    final members = familyProv.familyMembers;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Manage family',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Üye varsa: üstte tek satır hızlı ekleme
          if (members.isNotEmpty) ...[
            _AddMemberRow(
              controller: _memberCtrl,
              onAdd: () => _addMember(context),
            ),
            const SizedBox(height: 12),
          ],

          // Liste / Boş durum
          Flexible(
            child: members.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.groups_2, size: 48),
                            const SizedBox(height: 10),
                            Text(
                              'No family members yet',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Boşken sadece burada tek satır ekleme göster
                            _AddMemberRow(
                              controller: _memberCtrl,
                              onAdd: () => _addMember(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final name = members[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => familyProv.removeMember(i),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddMemberRow({Key? key, required this.controller, required this.onAdd})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter member name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add'),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
