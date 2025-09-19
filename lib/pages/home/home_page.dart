import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../providers/weekly_provider.dart';
import '../../widgets/mini_members_bar.dart';
import '../config/config_page.dart';
import '../expenses/expenses_card.dart';
import '../manage/manage_page.dart';
import '../weekly/weekly_page.dart';
import 'dashboard_summary.dart';
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
      // final target = widget.initialFilterMember;
      final weekly = context.read<WeeklyProvider>();
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

    // Eğer "sekme değişince aktif üyeye hafif scroll" istersen:
    // if (_pageController.hasClients) {
    //   _pageController.animateToPage(_activeIndex,
    //     duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // final family = context.watch<FamilyProvider>().familyMembers;
    // // İlk kez: aktif yoksa ilk kişiyi seç
    // _activeMember ??= family.isNotEmpty ? family.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final famProv = context.watch<FamilyProvider>();
    final familyId = famProv.familyId;
    debugPrint('[HomePage] familyId=$familyId');

    if (familyId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_cloudBound) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TaskCloudProvider>().setFamilyId(familyId);
        context.read<ItemCloudProvider>().setFamilyId(familyId);
        context.read<WeeklyCloudProvider>().setFamilyId(familyId);
      });
      _cloudBound = true;
    }

    return StreamBuilder<List<String>>(
      stream: famProv.watchMemberLabels(),
      builder: (context, snap) {
        final labels = snap.data ?? const <String>[];

        final names = labels.isEmpty
            ? context.read<FamilyProvider>().memberLabelsOrFallback
            : labels;

        if (snap.connectionState == ConnectionState.waiting && labels.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ❷ Giriş yapanı en başa taşı (aşağıda kod var)
        final ordered = _orderWithMeFirst(labels);

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
        debugPrint('Home labels=$labels');
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
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
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

                // === ANA SWIPER ===
                Expanded(
                  child: PageView.builder(
                    controller: _pageController, // <-- DÜZELTME
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _activeIndex = i),
                    itemCount: ordered.length,
                    itemBuilder: (context, i) {
                      final name = ordered[i];
                      final memberTasks = tasks
                          .where((t) => _matchesAssignee(t.assignedTo, name))
                          .toList();
                      final memberItems = items
                          .where((it) => _matchesAssignee(it.assignedTo, name))
                          .toList();

                      final card = (_section == HomeSection.expenses)
                          ? ExpensesCard(memberName: name)
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: KeyedSubtree(key: versionKey, child: card),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // === MİNİ BAR ===
                MiniMembersBar(
                  names: ordered,
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
                const SizedBox(height: 26),
              ],
            ),
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

// Küçük dikdörtgen member kutusu:
class _MiniMemberTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _MiniMemberTile({required this.name, required this.onTap});

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

List<String> _orderWithMeFirst(List<String> labels) {
  // FamilyProvider.watchMemberLabels() şu cihazdaki kullanıcıyı hep "You (...)" olarak döndürür.
  final idx = labels.indexWhere((s) => s.startsWith('You ('));
  if (idx <= 0) return labels;
  final copy = [...labels];
  final me = copy.removeAt(idx);
  copy.insert(0, me);
  return copy;
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
