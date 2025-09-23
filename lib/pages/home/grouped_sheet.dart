import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
  required String? Function(T) getAssignedUid,
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
          final list = sourceSelector(ctx).toList();

          final dictStream = ctx.read<FamilyProvider>().watchMemberDirectory();
          final myUid = FirebaseAuth.instance.currentUser?.uid;

          final famProv = ctx.read<FamilyProvider>();

          final familyLabels =
              famProv.memberLabelsOrFallback; // "You (xx)" dahil
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

          return StreamBuilder<Map<String, String>>(
            stream: dictStream, // {uid: label}
            builder: (_, snap) {
              final dict = snap.data ?? const <String, String>{};

              // --- gruplama
              final byMember = <String, List<T>>{};
              final unassigned = <T>[];

              String labelOfUid(String? uid) {
                final u = (uid ?? '').trim();
                if (u.isEmpty) return '';
                return dict[u] ?? 'Member';
              }

              for (final e in list) {
                final uid = (getAssignedUid(e) ?? '').trim();
                if (uid.isEmpty) {
                  unassigned.add(e);
                } else {
                  final label = labelOfUid(uid);
                  byMember.putIfAbsent(label, () => []).add(e);
                }
              }

              // --- Sıra: me first + diğer herkes (veridekiler + family labels union)
              final dataKeys = byMember.keys.toSet();
              final labelSet = familyLabels.toSet();
              final union = <String>{...dataKeys, ...labelSet}
                ..remove(''); // '' unassigned

              final orderedHeaders = byMember.keys.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

              String _titleFor(_GroupFilter f) {
                switch (f) {
                  case _GroupFilter.all:
                    return '$titleAll (${list.length})';
                  case _GroupFilter.mine:
                    final mineCount = list.where((e) {
                      final uid = (getAssignedUid(e) ?? '').trim();
                      return myUid != null && uid == myUid;
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
                    final uid = (getAssignedUid(e) ?? '').trim();
                    final who = labelOfUid(uid);
                    return ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -3,
                        vertical: -3,
                      ),
                      minLeadingWidth: 0, // ikon yok
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(getName(e), overflow: TextOverflow.ellipsis),
                      subtitle: uid.isEmpty ? null : Text('👤 $who'),
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
                              onPressed: () =>
                                  _refreshAfter(() => onEdit(ctx, e)),
                            ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () =>
                                _refreshAfter(() => onDelete(ctx, e)),
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
                                  ..._buildSectionFor(labelOfUid(myUid), [
                                    for (final e in list)
                                      if (myUid != null &&
                                          (getAssignedUid(e) ?? '').trim() ==
                                              myUid)
                                        e,
                                  ])
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
    },
  );
}

String _bareName(String youLabel) {
  final re = RegExp(r'^You \((.+)\)$');
  final m = re.firstMatch(youLabel);
  return m?.group(1) ?? '';
}
