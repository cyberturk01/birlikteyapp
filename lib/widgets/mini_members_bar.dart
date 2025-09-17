import 'package:flutter/material.dart';

class MiniMembersBar extends StatelessWidget {
  final List<String> names;
  final int activeIndex;
  final ValueChanged<int> onPickIndex;

  const MiniMembersBar({
    super.key,
    required this.names,
    required this.activeIndex,
    required this.onPickIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 1 üye ise göstermeyelim
    if (names.length <= 1) return const SizedBox.shrink();

    // 2..6 arasını destekliyoruz (fazlası gelirse ilk 6’yı kullan)
    final list = names.take(6).toList();

    // Rule-set’e göre satır/sütun dağılımını hesapla
    final layout = _computeLayout(list.length); // örn. [3,2] gibi

    // Yükseklik: satıra göre
    final rowCount = layout.length;
    final height = rowCount == 1 ? 56.0 : 104.0;

    // Satırlara böl
    final rows = <List<_MemberChipData>>[];
    var cursor = 0;
    for (final slots in layout) {
      final slice = list
          .skip(cursor)
          .take(slots)
          .toList()
          .asMap()
          .entries
          .map(
            (e) => _MemberChipData(
              globalIndex: cursor + e.key,
              label: _shortLabel(list[cursor + e.key]),
              fullLabel: list[cursor + e.key],
            ),
          )
          .toList();
      rows.add(slice);
      cursor += slots;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rows.map((row) {
              return Row(
                children: row.map((d) {
                  // Eşit bölünsün
                  final isActive = d.globalIndex == activeIndex;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: _MemberChip(
                        label: d.label,
                        tooltip: d.fullLabel,
                        active: isActive,
                        onTap: () => onPickIndex(d.globalIndex),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// 2=>[2], 3=>[3], 4=>[2,2], 5=>[3,2], 6=>[3,3]
  List<int> _computeLayout(int n) {
    switch (n) {
      case 2:
        return [2];
      case 3:
        return [3];
      case 4:
        return [2, 2];
      case 5:
        return [3, 2];
      default: // 6 ve üzeri (ilk 6)
        return [3, 3];
    }
  }

  static String _shortLabel(String s) {
    // "You (xxx)" görünüyorsa sadece "You"
    final lower = s.toLowerCase();
    if (lower.startsWith('you (')) return 'You';

    // 6–7 karaktere kırp + …
    const max = 7;
    final trimmed = s.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max)}…';
  }
}

class _MemberChipData {
  final int globalIndex;
  final String label;
  final String fullLabel;
  _MemberChipData({
    required this.globalIndex,
    required this.label,
    required this.fullLabel,
  });
}

class _MemberChip extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _MemberChip({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = active
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.surfaceVariant;
    final fg = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withOpacity(0.35)
                  : theme.dividerColor.withOpacity(0.4),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// class MiniMembersBar extends StatelessWidget {
//   final List<String> names; // Gösterilecek etiketler
//   final int activeIndex; // Hangi üye aktif
//   final ValueChanged<int> onPickIndex;
//
//   const MiniMembersBar({
//     super.key,
//     required this.names,
//     required this.activeIndex,
//     required this.onPickIndex,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (names.isEmpty) return const SizedBox.shrink();
//
//     return SizedBox(
//       height: 50,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: names.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 12),
//         itemBuilder: (ctx, i) {
//           final sel = i == activeIndex;
//           final label = names[i];
//
//           return GestureDetector(
//             onTap: () => onPickIndex(i),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 150),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               decoration: BoxDecoration(
//                 color: sel
//                     ? Theme.of(context).colorScheme.primaryContainer
//                     : Theme.of(context).colorScheme.surfaceVariant,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: sel
//                       ? Theme.of(context).colorScheme.primary
//                       : Theme.of(context).dividerColor.withOpacity(.4),
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircleAvatar(
//                     radius: 14,
//                     child: Text(
//                       label.isNotEmpty ? label[0].toUpperCase() : '?',
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ConstrainedBox(
//                     constraints: const BoxConstraints(maxWidth: 140),
//                     child: Text(
//                       label,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
