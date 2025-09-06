import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/ui_provider.dart'; // ⬅️ yeni
import '../config/config_page.dart';
import '../manage/manage_page.dart';
import '../weekly/weekly_page.dart';
import 'family_manager.dart';
import 'member_card.dart'; // ⬅️ kaldırıldı

class HomePage extends StatefulWidget {
  final String? initialFilterMember;
  const HomePage({Key? key, this.initialFilterMember}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Açılışta landing'den bir üye seçildiyse, UI filtresine uygula
    if (widget.initialFilterMember != null &&
        widget.initialFilterMember!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UiProvider>().setMember(widget.initialFilterMember);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>().familyMembers;
    final taskProv = context.watch<TaskProvider>();
    final itemProv = context.watch<ItemProvider>();
    final ui = context.watch<UiProvider>();

    final active = ui.resolveActive(family);

    final allTasks = taskProv.tasks;
    final allItems = itemProv.items;

    // Global görünüm ayarları
    final section = ui.section; // HomeSection.tasks | items
    final filterMember = ui.filterMember; // String? (null = herkes)
    if (active == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Togetherly'),
          actions: [
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              onPressed: () => showFamilyManager(context),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: EmptyFamilyCard(
            onAdd: () => showFamilyManager(context),
          ), // kendi helperınla değiştir
        ),
      );
    }

    // aktif üyenin tam listeleri (status filtresi yok, kart içinde süzülecek)
    final activeTasks = allTasks.where((t) => t.assignedTo == active).toList();
    final activeItems = allItems.where((i) => i.assignedTo == active).toList();

    // diğer üyeler küçük kutucuklar
    final others = family.where((n) => n != active).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $active'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Manage Family',
            onPressed: () => showFamilyManager(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Weekly Plan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Add (Tasks & Items)',
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
        child: Column(
          children: [
            // 🔸 Üst global toggle (Tasks / Market)
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
              selected: {section},
              onSelectionChanged: (s) =>
                  context.read<UiProvider>().setSection(s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),

            // 🔹 FEATURED: aktif üyenin büyük kartı (ekranın çoğunu kaplasın)
            Expanded(
              child: MemberCard(
                memberName: active,
                tasks: activeTasks,
                items: activeItems,
                section: section,
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 OTHERS: küçük dikdörtgen kutucuklar (scroll gerektirmeden görünür)
            if (others.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other members',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      // küçük kartların genişliğini ayarla
                      final double tileW = c.maxWidth >= 900
                          ? 220
                          : (c.maxWidth >= 600 ? 180 : 150);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: others.map((name) {
                          return _MiniMemberTile(
                            name: name,
                            width: tileW,
                            onTap: () => context
                                .read<UiProvider>()
                                .setActiveMember(name),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Küçük dikdörtgen member kutusu:
class _MiniMemberTile extends StatelessWidget {
  final String name;
  final double width;
  final VoidCallback onTap;
  const _MiniMemberTile({
    Key? key,
    required this.name,
    required this.width,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
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
      ),
    );
  }
}
