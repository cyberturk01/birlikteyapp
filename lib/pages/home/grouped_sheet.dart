import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';

enum _GroupFilter { all, mine, unassigned }

Future<void> showGroupedByMemberSheet<T>({
  required BuildContext context,
  required String titleAll,
  required String titleMine,
  required String titleUnassigned,
  required Iterable<T> Function(BuildContext) sourceSelector,
  required String Function(T) getName,
  required String Function(T) getAssignedTo,
  required FutureOr<void> Function(BuildContext, T) onTogglePrimary,
  required FutureOr<void> Function(BuildContext, T) onDelete,
  FutureOr<void> Function(BuildContext, T)? onEdit,
  FutureOr<void> Function(BuildContext, T)? onAssign,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final famProv = ctx.read<FamilyProvider>();
          final familyLabels =
              famProv.memberLabelsOrFallback; // "You (xx)" dahil
          final list = sourceSelector(ctx).toList();

          String? meLabel = familyLabels.firstWhere(
            (s) => s.startsWith('You ('),
            orElse: () => '',
          );
          final bareMe = _bareName(meLabel);

          _GroupFilter filter = _GroupFilter.all;

          Future<void> _refreshAfter(FutureOr<void> Function() fn) async {
            await Future.sync(fn);
            if (ctx.mounted) setLocal(() {});
          }

          // --- gruplama
          final byMember = <String, List<T>>{};
          final unassigned = <T>[];

          for (final e in list) {
            final who = getAssignedTo(e).trim();
            if (who.isEmpty) {
              unassigned.add(e);
            } else {
              byMember.putIfAbsent(who, () => []).add(e);
            }
          }

          // --- Sıra: me first + diğer herkes (veridekiler + family labels union)
          final dataKeys = byMember.keys.toSet();
          final labelSet = familyLabels.toSet();
          final union = <String>{...dataKeys, ...labelSet}
            ..remove(''); // '' unassigned

          // “You (X)” ile “X” aynı kişiyse tek başlık kullanabilelim.
          // Öncelik: varsa tam label (You (X)), yoksa çıplak isim.
          String? meHeader;
          if (union.contains(meLabel)) {
            meHeader = meLabel;
          } else if (union.contains(bareMe)) {
            meHeader = bareMe;
          }

          final others = union.where((k) => k != meHeader).toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          final orderedHeaders = <String>[
            if (meHeader != null) meHeader,
            ...others,
          ];

          String _titleFor(_GroupFilter f) {
            switch (f) {
              case _GroupFilter.all:
                return '$titleAll (${list.length})';
              case _GroupFilter.mine:
                final mineCount = list.where((e) {
                  final a = getAssignedTo(e).trim();
                  return _isMine(a, meLabel);
                }).length;
                return '$titleMine ($mineCount)';
              case _GroupFilter.unassigned:
                return '$titleUnassigned (${unassigned.length})';
            }
          }

          List<Widget> _buildSectionFor(String header, List<T> entries) {
            if (entries.isEmpty) return const [];
            return [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        header.isNotEmpty ? header[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      header.isEmpty ? 'Unassigned' : header,
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ...entries.map((e) {
                final who = getAssignedTo(e).trim();
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: -3,
                    vertical: -3,
                  ),
                  minLeadingWidth: 0, // ikon yok
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(getName(e), overflow: TextOverflow.ellipsis),
                  subtitle: who.isEmpty ? null : Text('👤 $who'),
                  onTap: () => _refreshAfter(() => onTogglePrimary(ctx, e)),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      if (onAssign != null)
                        IconButton(
                          tooltip: 'Assign',
                          icon: const Icon(Icons.person_add_alt, size: 20),
                          onPressed: () =>
                              _refreshAfter(() => onAssign(ctx, e)),
                        ),
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _refreshAfter(() => onEdit(ctx, e)),
                        ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _refreshAfter(() => onDelete(ctx, e)),
                      ),
                    ],
                  ),
                );
              }),
            ];
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx2, setTabs) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleFor(filter),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Center(
                      child: SegmentedButton<_GroupFilter>(
                        segments: const [
                          ButtonSegment(
                            value: _GroupFilter.all,
                            icon: Icon(Icons.all_inclusive),
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: _GroupFilter.mine,
                            icon: Icon(Icons.person),
                            label: Text('Mine'),
                          ),
                          ButtonSegment(
                            value: _GroupFilter.unassigned,
                            icon: Icon(Icons.person_off_outlined),
                            label: Text('Unassigned'),
                          ),
                        ],
                        selected: {filter},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setTabs(() => filter = s.first),
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text('No data'),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(
                            bottom: 24,
                          ), // <-- ekstra boşluk
                          children: [
                            if (filter == _GroupFilter.unassigned)
                              ..._buildSectionFor(
                                '',
                                unassigned,
                              ) // sadece unassigned
                            else if (filter == _GroupFilter.mine)
                              ..._buildSectionFor(
                                (meLabel?.isNotEmpty ?? false)
                                    ? meLabel!
                                    : bareMe,
                                [
                                  for (final e in list)
                                    if (_isMine(
                                      getAssignedTo(e).trim(),
                                      meLabel,
                                    ))
                                      e,
                                ],
                              )
                            else
                              ...orderedHeaders.expand((hdr) {
                                final bucket = <T>[
                                  ...?byMember[hdr],
                                  if (hdr == meLabel && bareMe.isNotEmpty)
                                    ...?byMember[bareMe],
                                  if (hdr == bareMe &&
                                      (meLabel?.isNotEmpty ?? false))
                                    ...?byMember[meLabel!],
                                ];
                                return _buildSectionFor(hdr, bucket);
                              }),
                            const SizedBox(
                              height: 40,
                            ), // <-- extra boşluk, alt safe area için
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
    },
  );
}

bool _isMine(String assignedTo, String? meLabel) {
  if (meLabel == null || meLabel.isEmpty) return false;
  final bare = _bareName(meLabel);
  return assignedTo == meLabel || assignedTo == bare;
}

String _bareName(String youLabel) {
  final re = RegExp(r'^You \((.+)\)$');
  final m = re.firstMatch(youLabel);
  return m?.group(1) ?? '';
}

List<String> _orderWithMeFirst(List<String> labels) {
  final idx = labels.indexWhere((s) => s.startsWith('You ('));
  if (idx <= 0) return labels;
  final copy = [...labels];
  final me = copy.removeAt(idx);
  copy.insert(0, me);
  return copy;
}
