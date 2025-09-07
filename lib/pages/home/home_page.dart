import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/task.dart';
import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../config/config_page.dart';
import '../manage/manage_page.dart';
import '../weekly/weekly_page.dart';
import 'family_manager.dart';
import 'member_card.dart';

class HomePage extends StatefulWidget {
  final String? initialFilterMember;
  const HomePage({Key? key, this.initialFilterMember}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeSection _section = HomeSection.tasks;

  String? _activeMember;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final family = context.watch<FamilyProvider>().familyMembers;
    // İlk kez: aktif yoksa ilk kişiyi seç
    _activeMember ??= family.isNotEmpty ? family.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>().familyMembers;
    final tasks = context.watch<TaskProvider>().tasks;
    final items = context.watch<ItemProvider>().items;

    final active = _activeMember;
    final activeTasks = (active == null)
        ? <Task>[]
        : tasks.where((t) => t.assignedTo == active).toList();
    final activeItems = (active == null)
        ? <Item>[]
        : items.where((i) => i.assignedTo == active).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.family_restroom),
            SizedBox(width: 8),
            Text('Togetherly'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Manage family',
            icon: const Icon(Icons.group),
            onPressed: () => showFamilyManager(context),
          ),
          IconButton(
            tooltip: 'Weekly plan',
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Add Center',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Configuration',
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigurationPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: family.isEmpty
            ? Center(
                child: EmptyFamilyCard(onAdd: () => showFamilyManager(context)),
              )
            : Column(
                children: [
                  // Global toggle
                  SegmentedButton<HomeSection>(
                    segments: const [
                      ButtonSegment(
                        value: HomeSection.tasks,
                        icon: Icon(Icons.task, size: 16),
                        label: Text('Tasks', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: HomeSection.items,
                        icon: Icon(Icons.shopping_cart, size: 16),
                        label: Text('Market', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_section},
                    onSelectionChanged: (s) =>
                        setState(() => _section = s.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 12),
                  // ANA ÜYE KARTI
                  if (active != null)
                    Expanded(
                      child: MemberCard(
                        memberName: active,
                        tasks: activeTasks,
                        items: activeItems,
                        section: _section,
                      ),
                    )
                  else
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          // responsive columns
                          int cross = 1;
                          if (c.maxWidth >= 1200)
                            cross = 4;
                          else if (c.maxWidth >= 900)
                            cross = 3;
                          else if (c.maxWidth >= 600)
                            cross = 2;

                          // responsive aspect ratio (daha dar ekranda daha küçük oran → kart daha uzun olur)
                          final ratio = (c.maxWidth < 380)
                              ? 0.70
                              : (c.maxWidth < 480)
                              ? 0.78
                              : (c.maxWidth < 600)
                              ? 0.88
                              : 0.95;

                          return GridView.builder(
                            itemCount: family.isEmpty ? 1 : family.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: ratio,
                                ),
                            itemBuilder: (context, i) {
                              if (family.isEmpty) {
                                return EmptyFamilyCard(
                                  onAdd: () => showFamilyManager(context),
                                );
                              }
                              final name = family[i];
                              final t = tasks
                                  .where((x) => x.assignedTo == name)
                                  .toList();
                              final it = items
                                  .where((x) => x.assignedTo == name)
                                  .toList();

                              return MemberCard(
                                memberName: name,
                                tasks: t,
                                items: it,
                                section: _section,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),

                  // MİNİ ÜYE BAR (diğerleri)
                  MiniMembersBar(
                    names: family,
                    active: active ?? '',
                    onPick: (name) {
                      setState(() => _activeMember = name);
                    },
                  ),
                  const SizedBox(height: 36),
                ],
              ),
      ),
    );
  }
}

// Küçük dikdörtgen member kutusu:
class _MiniMemberTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _MiniMemberTile({Key? key, required this.name, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(radius: 16, child: Text(initial)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ana kartın altında mini üyeleri gösteren responsive bar.
/// - Telefon: 2 sütun
/// - Orta ekran: 3 sütun
/// - Geniş: 4 sütun
class MiniMembersBar extends StatelessWidget {
  final List<String> names;
  final String active; // şu an seçili olan (ana kart)
  final ValueChanged<String> onPick;

  const MiniMembersBar({
    Key? key,
    required this.names,
    required this.active,
    required this.onPick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // aktif olanı listeden çıkar, sadece "diğerleri" görünsün
    final others = names.where((n) => n != active).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        int cols;
        if (w >= 1100)
          cols = 4;
        else if (w >= 800)
          cols = 3;
        else
          cols = 2;

        const spacing = 12.0;
        // sabit kutu genişliği: wrap ortalansın diye
        final tileWidth = (w - (cols - 1) * spacing) / cols;

        return Wrap(
          alignment: WrapAlignment.center, // soldan-sağdan eşit boşluk
          spacing: spacing,
          runSpacing: spacing,
          children: others.map((name) {
            return SizedBox(
              width: tileWidth,
              child: _MiniMemberTile(name: name, onTap: () => onPick(name)),
            );
          }).toList(),
        );
      },
    );
  }
}
