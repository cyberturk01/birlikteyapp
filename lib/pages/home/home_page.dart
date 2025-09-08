import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  late final PageController _pageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeIndex);

    // initialFilterMember geldiyse index’e çevir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final family = context.read<FamilyProvider>().familyMembers;
      final target = widget.initialFilterMember;
      if (target != null && target.isNotEmpty) {
        final idx = family.indexOf(target);
        if (idx >= 0) {
          _activeIndex = idx;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(idx);
          }
          setState(() {}); // aktif index’i yansıt
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

    // Liste değişmişse index sınırını koru
    if (_activeIndex >= family.length) {
      _activeIndex = family.isEmpty ? 0 : family.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_activeIndex);
        }
      });
    }

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

                        return PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) =>
                              setState(() => _activeIndex = i),

                          itemCount: family.length,
                          itemBuilder: (context, i) {
                            final name = family[i];
                            final memberTasks = tasks
                                .where((t) => t.assignedTo == name)
                                .toList();
                            final memberItems = items
                                .where((it) => it.assignedTo == name)
                                .toList();
                            return KeyedSubtree(
                              key: ValueKey('member-page-$i'),
                              child: MemberCard(
                                memberName: name,
                                tasks: memberTasks,
                                items: memberItems,
                                section: _section,
                              ),
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
                    activeIndex: _activeIndex,
                    onPickIndex: (i) {
                      setState(() => _activeIndex = i);
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
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

class MiniMembersBar extends StatelessWidget {
  final List<String> names;
  final int activeIndex;
  final ValueChanged<int> onPickIndex;

  const MiniMembersBar({
    Key? key,
    required this.names,
    required this.activeIndex,
    required this.onPickIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Liste 0 veya 1 ise bar göstermeye gerek yok
    // if (names.length <= 1) {
    //   return const SizedBox(height: 0);
    // }
    if (names.length <= 1) return const SizedBox.shrink();

    // Aktif dışındakiler (index bazlı)
    final others = <(int, String)>[];
    for (var i = 0; i < names.length; i++) {
      if (i == activeIndex) continue;
      others.add((i, names[i]));
    }

    return SafeArea(
      // alt çentik / nav bar ile çakışmayı önler
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final cols = w >= 1100
                ? 4
                : w >= 800
                ? 3
                : 2;
            const spacing = 12.0;
            final tileWidth = (w - (cols - 1) * spacing) / cols;

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: others.map((e) {
                return SizedBox(
                  width: tileWidth,
                  child: KeyedSubtree(
                    key: ValueKey('mini-${e.$1}'),
                    child: _MiniMemberTile(
                      name: e.$2,
                      onTap: () => onPickIndex(e.$1),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
