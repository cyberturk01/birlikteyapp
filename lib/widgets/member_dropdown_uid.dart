import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_provider.dart';

class MemberDropdownUid extends StatelessWidget {
  final String? value; // null = All / Unassigned
  final ValueChanged<String?> onChanged; // null dönebilir
  final String label;
  final String nullLabel;

  const MemberDropdownUid({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Member',
    this.nullLabel = 'All members',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyMemberEntry>>(
      stream: context.read<FamilyProvider>().watchMemberEntries(),
      builder: (ctx, snap) {
        final entries = (snap.data ?? const <FamilyMemberEntry>[]);

        // 🔒 Tekilleştir (aynı uid bir kez)
        final byUid = <String, FamilyMemberEntry>{};
        for (final e in entries) {
          byUid[e.uid] = e;
        }
        final uniq = byUid.values.toList();

        // Mevcut value listede yoksa null’a indir (assert fix)
        final uids = uniq.map((e) => e.uid).toSet();
        final normalizedValue = (value != null && !uids.contains(value))
            ? null
            : value;

        final items = <DropdownMenuItem<String?>>[
          DropdownMenuItem(value: null, child: Text(nullLabel)),
          ...uniq.map(
            (e) => DropdownMenuItem(value: e.uid, child: Text(e.label)),
          ),
        ];

        return DropdownButtonFormField<String?>(
          value: normalizedValue, // ✅ normalize
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
    );
  }
}
