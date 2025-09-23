import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../providers/family_provider.dart';

class _FamilyManagerSheet extends StatelessWidget {
  const _FamilyManagerSheet();

  @override
  Widget build(BuildContext context) {
    final fam = context.read<FamilyProvider>();

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

          // Davet kodu kartı
          _InviteCodeTile(
            onTapCopy: () async {
              final code = await fam.getInviteCode();
              if (code == null) return;
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invite code copied: $code')),
                );
              }
            },
          ),

          const SizedBox(height: 12),

          // ÜYE LİSTESİ (Firestore)
          Flexible(
            child: StreamBuilder<List<FamilyMemberEntry>>(
              stream: fam.watchMemberEntries(),
              builder: (ctx, snap) {
                final entries = snap.data ?? const <FamilyMemberEntry>[];
                if (snap.connectionState == ConnectionState.waiting &&
                    entries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (entries.isEmpty) {
                  return const _EmptyMembersHint();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final isOwner = e.role == 'owner';
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          e.label.isNotEmpty ? e.label[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(e.label, overflow: TextOverflow.ellipsis),
                      subtitle: Text(isOwner ? 'Owner' : 'Member'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit label (this family only)',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditLabelDialog(context, e),
                          ),
                          IconButton(
                            tooltip: S.delete,
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                            ),
                            onPressed: isOwner
                                ? null
                                : () async {
                                    try {
                                      await fam.removeMemberFromFamily(e.uid);
                                    } catch (err) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(err.toString())),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showInviteSheet(BuildContext context) async {
  final fam = context.read<FamilyProvider>();
  String? code = await fam.ensureInviteCode();
  bool isActive = true;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('invites')
        .doc(code!)
        .get();
    isActive = (snap.data()?['active'] as bool?) ?? true;
  } catch (_) {}

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                ListTile(
                  title: const Text('Invite code'),
                  subtitle: Text(code ?? '—'),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (v) async {
                      await fam.setInviteActive(v);
                      setLocal(() => isActive = v);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy & Share'),
                        onPressed: () async => fam.shareInvite(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _InviteCodeTile extends StatelessWidget {
  final VoidCallback onTapCopy;
  const _InviteCodeTile({required this.onTapCopy});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.qr_code_2),
      title: const Text('Invite a member'),
      subtitle: const Text('Share your family’s invite code'),
      trailing: FilledButton.icon(
        icon: const Icon(Icons.copy),
        label: const Text('Copy code'),
        onPressed: onTapCopy,
      ),
    );
  }
}

class _EmptyMembersHint extends StatelessWidget {
  const _EmptyMembersHint();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_2, size: 48),
            const SizedBox(height: 10),
            Text(
              'No family members yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the invite code above to add members.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _showEditLabelDialog(BuildContext context, FamilyMemberEntry e) async {
  final fam = context.read<FamilyProvider>();
  final initial = await fam.getRawLabelFor(e.uid); // <<< ham değer
  if (!context.mounted) return;

  final c = TextEditingController(text: initial);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit member label'),
      content: TextField(
        controller: c,
        decoration: const InputDecoration(
          labelText: 'Label',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final newLabel = c.text.trim();
            if (newLabel.isEmpty) return;
            await fam.updateMemberLabel(e.uid, newLabel);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

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
