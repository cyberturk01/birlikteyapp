import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/view_section.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../utils/assignee.dart';
import '../../widgets/expenses_mini_summary.dart';
import '../../widgets/mini_members_bar.dart';
import '../config/config_page.dart';
import '../expenses/expenses_card.dart';
import '../family/family_manager.dart';
import '../manage/manage_page.dart';
import '../weekly/weekly_page.dart';
import 'dashboard_summary.dart';
import 'member_card.dart';

class HomePage extends StatefulWidget {
  final String? initialFilterMember;
  const HomePage({super.key, this.initialFilterMember});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeSection _section = HomeSection.tasks;
  late final PageController _pageController;
  int _activeIndex = 0;
  bool _appliedInitial = false;
  bool _cloudBound = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      // viewportFraction: 0.92, // yanlardan küçük boşluk
      initialPage: _activeIndex,
    );
    // initialFilterMember geldiyse index’e çevir
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final weekly = context.read<WeeklyCloudProvider>();
      final taskProv = context.read<TaskCloudProvider>();
      await weekly.ensureTodaySynced(taskProv);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpTo(HomeSection s) {
    if (_section == s) return;
    setState(() => _section = s);
  }

  @override
  Widget build(BuildContext context) {
    final famProv = context.watch<FamilyProvider>();
    final familyId = famProv.familyId;
    debugPrint('[HomePage] familyId=$familyId');

    final taskError = context.select<TaskCloudProvider, String?>(
      (p) => p.lastError,
    );
    final itemError = context.select<ItemCloudProvider, String?>(
      (p) => p.lastError,
    );
    final weeklyError = context.select<WeeklyCloudProvider, String?>(
      (p) => p.lastError,
    );
    final expenseError = context.select<ExpenseCloudProvider, String?>(
      (p) => p.lastError,
    );

    final errors = [
      taskError,
      itemError,
      weeklyError,
      expenseError,
    ].whereType<String>().toList();

    if (familyId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_cloudBound) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TaskCloudProvider>().setFamilyId(familyId);
        context.read<ItemCloudProvider>().setFamilyId(familyId);
        context.read<WeeklyCloudProvider>().setFamilyId(familyId);
        context.read<ExpenseCloudProvider>().setFamilyId(familyId);
      });
      _cloudBound = true;
    }

    return StreamBuilder<List<FamilyMemberEntry>>(
      stream: famProv.watchMemberEntries(),
      builder: (context, snap) {
        final entries = snap.data ?? const <FamilyMemberEntry>[];
        final labels = entries.map((e) => e.label).toList();
        final uids = entries.map((e) => e.uid).toList();

        final names = labels.isEmpty
            ? context.read<FamilyProvider>().memberLabelsOrFallback
            : labels;

        if (snap.connectionState == ConnectionState.waiting && labels.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ❷ Giriş yapanı en başa taşı (aşağıda kod var)
        final idxMe = labels.indexWhere((s) => s.startsWith('You ('));
        final orderedLabels = [...labels];
        final orderedUids = [...uids];
        if (idxMe > 0) {
          final meLabel = orderedLabels.removeAt(idxMe);
          final meUid = orderedUids.removeAt(idxMe);
          orderedLabels.insert(0, meLabel);
          orderedUids.insert(0, meUid);
        }
        // ❸ sadece ilk kez aktif index’i set et
        if (!_appliedInitial) {
          _activeIndex = 0; // me first
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) _pageController.jumpToPage(0);
            setState(() {});
          });
          _appliedInitial = true;
        }

        if (_activeIndex >= names.length) {
          _activeIndex = names.length - 1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_activeIndex);
            }
            setState(() {});
          });
        }

        final tasks = context.watch<TaskCloudProvider>().tasks;
        final items = context.watch<ItemCloudProvider>().items;
        final h = MediaQuery.of(context).size.height;
        final isShort = h < 640;
        debugPrint('Home labels=$labels');
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: const [
                Icon(Icons.family_restroom),
                SizedBox(width: 4),
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
                    MaterialPageRoute(
                      builder: (_) => const ConfigurationPage(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  context.read<TaskCloudProvider>().teardown();
                  context.read<ItemCloudProvider>().teardown();
                  context.read<WeeklyCloudProvider>().teardown();
                  context.read<ExpenseCloudProvider>().teardown();
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (errors.isNotEmpty)
                MaterialBanner(
                  backgroundColor: Colors.red.shade100,
                  content: Text(
                    errors.first, // sadece ilk hatayı gösteriyoruz
                    style: const TextStyle(color: Colors.black),
                  ),
                  leading: const Icon(Icons.warning, color: Colors.red),
                  actions: [
                    TextButton(
                      child: const Text('DISMISS'),
                      onPressed: () {
                        context.read<TaskCloudProvider>().clearError();
                        context.read<ItemCloudProvider>().clearError();
                        context.read<WeeklyCloudProvider>().clearError();
                        context.read<ExpenseCloudProvider>().clearError();
                      },
                    ),
                  ],
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 25),
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      final content = Column(
                        children: [
                          DashboardSummaryBar(
                            onTap: (dest) {
                              setState(() {
                                switch (dest) {
                                  case SummaryDest.tasks:
                                    _section = HomeSection.tasks;
                                    break;
                                  case SummaryDest.items:
                                    _section = HomeSection.items;
                                    break;
                                  case SummaryDest.expenses:
                                    _section = HomeSection.expenses;
                                    break;
                                  case SummaryDest.weekly:
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WeeklyPage(),
                                      ),
                                    );
                                    return;
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 4),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: (_section == HomeSection.expenses)
                                ? Column(
                                    key: const ValueKey('exp-mini'),
                                    children: [
                                      ExpensesMiniSummary(
                                        expenses:
                                            context
                                                .watch<ExpenseCloudProvider?>()
                                                ?.all ??
                                            const <ExpenseDoc>[],
                                        onTap:
                                            null, // artık sekme zaten expenses; tıklamada iş yok
                                        // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), // istersen
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('exp-mini-off'),
                                  ),
                          ),

                          // const SizedBox(height: 4),
                          // === ANA SWIPER ===
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController, // <-- DÜZELTME
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (i) =>
                                  setState(() => _activeIndex = i),
                              itemCount: orderedLabels.length,
                              itemBuilder: (context, i) {
                                final name = orderedLabels[i];
                                final uid = orderedUids[i];
                                final memberTasks = tasks
                                    .where(
                                      (t) =>
                                          Assignee.match(t.assignedToUid, name),
                                    )
                                    .toList();
                                final memberItems = items
                                    .where(
                                      (i) =>
                                          Assignee.match(i.assignedToUid, name),
                                    )
                                    .toList();

                                final card = (_section == HomeSection.expenses)
                                    ? ExpensesCard(memberUid: uid)
                                    : MemberCard(
                                        memberName: name,
                                        tasks: memberTasks,
                                        items: memberItems,
                                        section: _section,
                                        onJumpSection: _jumpTo,
                                      );

                                final versionKey = ValueKey<String>(
                                  'member-$i-t${memberTasks.length}-i${memberItems.length}-s${_section.name}',
                                );
                                return Center(
                                  child: _MemberPageKeepAlive(
                                    key: PageStorageKey('member-page-$i'),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: KeyedSubtree(
                                          key: versionKey,
                                          child: card,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 4),

                          // === MİNİ BAR ===
                          MiniMembersBar(
                            names: orderedLabels,
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
                          if (!isShort) const SizedBox(height: 12),
                        ],
                      );
                      return isShort
                          ? SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: c.maxHeight,
                                ),
                                child: content,
                              ),
                            )
                          : content;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberPageKeepAlive extends StatefulWidget {
  final Widget child;
  const _MemberPageKeepAlive({super.key, required this.child});

  @override
  State<_MemberPageKeepAlive> createState() => _MemberPageKeepAliveState();
}

class _MemberPageKeepAliveState extends State<_MemberPageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

bool _matchesAssignee(String? assignedTo, String cardLabel) {
  if (assignedTo == null || assignedTo.trim().isEmpty) return false;
  if (assignedTo == cardLabel) return true;

  // "You (xxx)" <-> "xxx" simetrik eşleşme
  final re = RegExp(r'^You \((.+)\)$');

  final mAssigned = re.firstMatch(assignedTo);
  if (mAssigned != null) {
    final base = mAssigned.group(1)!; // xxx
    return cardLabel == base || cardLabel == 'You ($base)';
  }

  final mCard = re.firstMatch(cardLabel);
  if (mCard != null) {
    final base = mCard.group(1)!;
    return assignedTo == base || assignedTo == 'You ($base)';
  }

  return false;
}
