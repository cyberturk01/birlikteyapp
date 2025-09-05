import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../weekly/weekly_page.dart';
import 'family_manager.dart'; // birazdan ekleyeceğiz
import 'member_card.dart';
import 'quick_panel.dart';

class HomePage extends StatefulWidget {
  final String? initialFilterMember; // ✅ opsiyonel
  const HomePage({Key? key, this.initialFilterMember}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // İlk frame sonrası Quick Panel’i, varsa kişi filtresiyle aç
    if (widget.initialFilterMember != null &&
        widget.initialFilterMember!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // showQuickPanel senin mevcut fonksiyonundu; kişi filtresi alıyordu.
        showQuickPanel(context, personFilter: widget.initialFilterMember);
      });
    }
  }

  HomeSection _section = HomeSection.tasks; // 🔸 default: Tasks

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>().familyMembers;
    final tasks = context.watch<TaskProvider>().tasks;
    final items = context.watch<ItemProvider>().items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Togetherly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => showFamilyManager(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.launch),
            onPressed: () => showQuickPanel(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔸 Üst global toggle
            SegmentedButton<HomeSection>(
              segments: const [
                ButtonSegment(
                  value: HomeSection.tasks,
                  icon: Icon(Icons.task),
                  label: Text('Tasks'),
                ),
                ButtonSegment(
                  value: HomeSection.items,
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Market'),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (s) => setState(() => _section = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),

            // Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  int cross = 1;
                  if (c.maxWidth >= 1200)
                    cross = 4;
                  else if (c.maxWidth >= 900)
                    cross = 3;
                  else if (c.maxWidth >= 600)
                    cross = 2;

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
                          onAdd: () => showQuickPanel(context),
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
                        section: _section, // 🔸 hangi sekme seçiliyse karta geç
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
