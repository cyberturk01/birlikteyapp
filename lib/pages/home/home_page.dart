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

    final allTasks = taskProv.tasks;
    final allItems = itemProv.items;

    // Global görünüm ayarları
    final section = ui.section; // HomeSection.tasks | items
    final filterMember = ui.filterMember; // String? (null = herkes)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Togetherly'),
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
            // 🔸 Üst global toggle — artık UiProvider’ı kontrol ediyor
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

            // Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  int cross = 1;
                  if (c.maxWidth >= 1200) {
                    cross = 4;
                  } else if (c.maxWidth >= 900) {
                    cross = 3;
                  } else if (c.maxWidth >= 600) {
                    cross = 2;
                  }

                  final ratio = (c.maxWidth >= 600) ? 0.95 : 0.9;

                  return GridView.builder(
                    itemCount: family.isEmpty ? 1 : family.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ratio,
                    ),
                    itemBuilder: (context, i) {
                      if (family.isEmpty) {
                        return EmptyFamilyCard(
                          onAdd: () => showFamilyManager(
                            context,
                          ), // ⬅️ Quick Panel değil
                        );
                      }

                      final name = family[i];

                      // Kişi filtresi aktifse, filtreden farklı üyeleri "soluk" göstermek istersen:
                      final bool dim =
                          (filterMember != null && filterMember != name);

                      final memberTasksAll = allTasks
                          .where((t) => t.assignedTo == name)
                          .toList();
                      final memberItemsAll = allItems
                          .where((it) => it.assignedTo == name)
                          .toList();

                      // Task status filter (UiProvider)
                      final filteredTasks =
                          ui.taskFilter == TaskViewFilter.pending
                          ? memberTasksAll.where((t) => !t.completed).toList()
                          : memberTasksAll.where((t) => t.completed).toList();

                      // Item status filter (UiProvider)
                      final filteredItems =
                          ui.itemFilter == ItemViewFilter.toBuy
                          ? memberItemsAll.where((it) => !it.bought).toList()
                          : memberItemsAll.where((it) => it.bought).toList();

                      return Opacity(
                        opacity: dim ? 0.55 : 1.0,
                        child: MemberCard(
                          memberName: name,
                          tasks: memberTasksAll,
                          items: memberItemsAll,
                          section:
                              section, // 🔸 hangi sekme seçiliyse karta geç
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
