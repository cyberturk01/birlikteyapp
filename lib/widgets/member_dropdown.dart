import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';

class MemberDropdown extends StatelessWidget {
  /// Seçili değer (null = All/Unassigned vb.)
  final String? value;

  /// Değişince tetiklenecek callback ('' geldiğinde null'a çevrilebilir)
  final ValueChanged<String?> onChanged;

  /// Etiket (örn. 'Assign to', 'Member')
  final String label;

  /// 'null' durumu için gösterilecek metin (örn. 'All members' ya da 'No one')
  final String nullLabel;

  const MemberDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Member',
    this.nullLabel = 'All members',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: context.read<FamilyProvider>().watchMemberLabels(),
      builder: (ctx, snap) {
        final labels = (snap.data ?? const <String>[]).toSet().toList();

        // Dropdown 'null' item’ı için '' kullanıyoruz
        final items = <DropdownMenuItem<String>>[
          DropdownMenuItem(value: '', child: Text(nullLabel)),
          ...labels.map((m) => DropdownMenuItem(value: m, child: Text(m))),
        ];

        // value listede yoksa '' göster
        final current = (value != null && labels.contains(value)) ? value! : '';

        return DropdownButtonFormField<String>(
          value: current,
          isExpanded: true,
          items: items,
          onChanged: (v) => onChanged((v == null || v.isEmpty) ? null : v),
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
