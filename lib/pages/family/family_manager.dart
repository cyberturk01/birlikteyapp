import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/family_provider.dart';

class _FamilyManagerSheet extends StatelessWidget {
  const _FamilyManagerSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
              Expanded(
                child: Text(
                  t.menuManageFamily,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
              final t = AppLocalizations.of(context)!;
              final code = await fam.getInviteCode();
              if (code == null) return;
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.inviteCodeCopied(code),
                    ),
                  ),
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
                    return MemberTile(entry: e);
                  },
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  addSemanticIndexes: false,
                  cacheExtent: 800,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MemberTile extends StatelessWidget {
  final FamilyMemberEntry entry;
  const MemberTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final meUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = entry.role == 'owner';
    final isSelf = entry.uid == meUid;
    final hasPhoto = (entry.photoUrl != null && entry.photoUrl!.isNotEmpty);

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: hasPhoto ? NetworkImage(entry.photoUrl!) : null,
        child: hasPhoto
            ? null
            : Text(entry.label.isEmpty ? '?' : entry.label[0].toUpperCase()),
      ),
      title: Text(entry.label, overflow: TextOverflow.ellipsis),
      subtitle: Text(isOwner ? t.ownerLabel : t.memberLabel),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'editLabel') {
            _showEditLabelDialog(context, entry);
            return;
          }

          if (v == 'photo') {
            final picker = ImagePicker();
            final x = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
              maxWidth: 1024,
            );
            if (x == null) return;

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            try {
              await context.read<FamilyProvider>().setMemberPhoto(
                memberUid: entry.uid,
                file: File(x.path),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.photoUpdateFailed('$e'))),
                );
              }
            } finally {
              if (context.mounted) Navigator.pop(context);
            }
            return;
          }

          if (v == 'removePhoto') {
            try {
              await context.read<FamilyProvider>().removeMemberPhoto(entry.uid);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.removeFailed('$e'))));
              }
            }
            return;
          }

          if (v == 'removeUser') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(t.removeMemberTitle),
                content: Text(t.removeMemberBody(entry.label)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(t.remove),
                  ),
                ],
              ),
            );
            if (ok != true) return;

            try {
              await context.read<FamilyProvider>().removeMemberFromFamily(
                entry.uid,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.memberRemoved)));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.removeFailed('$e'))));
              }
            }
            return;
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'editLabel',
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppLocalizations.of(context)!.editMember),
            ),
          ),
          PopupMenuItem(
            value: 'photo',
            child: ListTile(
              leading: const Icon(Icons.photo),
              title: Text(AppLocalizations.of(context)!.changePhoto),
            ),
          ),
          if (hasPhoto)
            PopupMenuItem(
              value: 'removePhoto',
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(AppLocalizations.of(context)!.removePhoto),
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            enabled: !isOwner && !isSelf, // owner veya kendini silme!
            value: 'removeUser',
            child: ListTile(
              leading: Icon(
                Icons.person_remove,
                color: (!isOwner && !isSelf) ? Colors.red : Colors.grey,
              ),
              title: Text(
                AppLocalizations.of(context)!.removeUser,
                style: TextStyle(
                  color: (!isOwner && !isSelf) ? Colors.red : Colors.grey,
                ),
              ),
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
  final t = AppLocalizations.of(context)!;
  bool isActive = true;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('invites')
        .doc(code!)
        .get();
    isActive = (snap.data()?['active'] as bool?) ?? true;
  } catch (_) {}

  await showModalBottomSheet(
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
                  title: Text(t.inviteCode),
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
                        label: Text(t.copyAndShare),
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
    final t = AppLocalizations.of(context)!;
    return ListTile(
      tileColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.qr_code_2),
      title: Text(t.inviteMember),
      subtitle: Text(t.shareInviteCode),
      trailing: FilledButton.icon(
        icon: const Icon(Icons.copy),
        label: Text(t.copyCode),
        onPressed: onTapCopy,
      ),
    );
  }
}

class _EmptyMembersHint extends StatelessWidget {
  const _EmptyMembersHint();
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_2, size: 48),
            const SizedBox(height: 10),
            Text(
              t.noFamilyMembersYet,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(t.useInviteCodeHint, textAlign: TextAlign.center),
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
  final t = AppLocalizations.of(context)!;
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editMemberLabel),
      content: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: t.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final newLabel = c.text.trim();
            if (newLabel.isEmpty) return;
            await fam.updateMemberLabel(e.uid, newLabel);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(t.save),
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
