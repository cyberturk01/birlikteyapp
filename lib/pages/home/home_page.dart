import 'package:birlikteyapp/utils/context_perms.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../models/view_section.dart';
import '../../permissions/permissions.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/location_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../widgets/empty_state.dart';
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
  final String? initialFilterMemberUid;
  const HomePage({super.key, this.initialFilterMemberUid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeSection _section = HomeSection.tasks;
  late final PageController _pageController;
  int _activeIndex = 0;
  bool _appliedInitial = false;
  bool _cloudBound = false;
  String? _boundFamilyId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeIndex);

    // initialFilterMember geldiyse index’e çevir
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _applyLazyListeningFor(_section);
      if (FirebaseAuth.instance.currentUser == null) return;
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

  void _applyLazyListeningFor(HomeSection s) {
    final expense = context.read<ExpenseCloudProvider>();

    if (s == HomeSection.expenses) {
      expense.startListening();
    } else {
      expense.stopListening(clear: false); // veri kalsın istersen false
    }

    // Weekly’i HomePage’te göstermiyoruz; WeeklyPage’e gidince açacağız (aşağıda).
  }

  void _jumpTo(HomeSection s) {
    if (_section == s) return;
    setState(() => _section = s);
    _applyLazyListeningFor(s);
  }

  List<PopupMenuEntry<String>> _buildMainMenuItems(
    BuildContext context,
    AppLocalizations t,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Aile yönetimi (owner/editor → görünür; diğerleri gizli)
    if (context.can(FamilyPermission.manageMembers)) {
      items.add(
        PopupMenuItem(
          value: 'manage',
          child: ListTile(
            leading: const Icon(Icons.group),
            title: Text(t.menuManageFamily),
          ),
        ),
      );
    }

    // Add Center (örn: toplu ekleme/temizlik merkezi) → tasks/items/weekly yazabilen roller
    final canAddCenter =
        context.canWriteTasks ||
        context.canWriteItems ||
        context.canWriteWeekly;
    if (canAddCenter) {
      items.add(
        PopupMenuItem(
          value: 'addCenter',
          child: ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(t.menuAddCenter),
          ),
        ),
      );
    }

    items.add(
      PopupMenuItem(
        value: 'weekly',
        child: ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(t.weekly), // mevcut yerelleştirme anahtarın
        ),
      ),
    );

    // Config (Bütçe vb.) → manageBudgets izni
    if (context.canManageBudgets) {
      items.add(
        PopupMenuItem(
          value: 'config',
          child: ListTile(
            leading: const Icon(Icons.tune),
            title: Text(t.configTitle),
          ),
        ),
      );
    }

    if (items.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }

    // Çıkış → herkes görsün
    items.add(
      PopupMenuItem(
        value: 'signout',
        child: ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text(t.signOut),
        ),
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final famProv = context.watch<FamilyProvider>();
    final familyId = famProv.familyId;
    debugPrint('[HomePage] familyId=$familyId');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return EmptyState(
        title: t.appTitle,
        message: t.welcome, // "Welcome" vb.
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            child: Text(t.signIn), // "Sign in"
          ),
        ],
      );
    }

    // 3.b) familyId yoksa → onboarding/manager’e yönlendiren "empty state"
    if (familyId == null || familyId.isEmpty) {
      return EmptyState(
        title: t.appTitle,
        message: t.setupFamilyDesc, // "Create or join a family" gibi
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              await showFamilyManager(context);
              if (!context.mounted) return;
              setState(() {}); // döndükten sonra yeniden çiz
            },
            label: Text(t.setupFamily),
          ),
        ],
      );
    }

    // 3.c) Bulut provider’ları güvenli bağla (yalnızca 1 kez)
    if (!_cloudBound || _boundFamilyId != familyId) {
      _cloudBound = true;
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await context.read<TaskCloudProvider>().setFamilyId(familyId);
        await context.read<ItemCloudProvider>().setFamilyId(familyId);
        context.read<WeeklyCloudProvider>().setFamilyId(familyId);
        await context.read<ExpenseCloudProvider>().setFamilyId(familyId);
        await context.read<LocationCloudProvider>().setFamilyId(familyId);

        try {
          await ensureMembership(familyId);
        } catch (_) {}
      });
    }

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

    return StreamBuilder<List<FamilyMemberEntry>>(
      key: ValueKey('${user.uid}-$familyId'),
      stream: famProv.watchMemberEntries(),
      builder: (context, snap) {
        if (snap.hasError) {
          // izin hataları dahil — boş ekran yerine uyarı göster
          return EmptyState(
            title: t.appTitle,
            message: t.somethingWentWrong, // "Something went wrong"
            actions: [
              Text(snap.error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => setState(() {}),
                child: Text(t.retry),
              ),
            ],
          );
        }
        final entries = snap.data ?? const <FamilyMemberEntry>[];
        if (snap.connectionState == ConnectionState.waiting &&
            entries.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final ordered = _orderWithMeFirstEntries(entries);

        if (ordered.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(t.appTitle)),
            body: EmptyState(
              title: t.members,
              message:
                  t.noMembersFound, // ya da “Henüz üye yok, birini ekleyin.”
              actions: [
                FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  onPressed: () => showFamilyManager(context),
                  label: Text(t.addMember),
                ),
              ],
            ),
          );
        }

        if (_boundFamilyId != familyId) {
          _appliedInitial = false;
          _activeIndex = 0;
        }

        // ✅ İlk seçim: entries hazırken ve henüz yapılmamışken
        if (!_appliedInitial && ordered.isNotEmpty) {
          final ui = context.read<UiProvider>();
          final targetUid =
              widget.initialFilterMemberUid ??
              ui.activeMemberUid ??
              FirebaseAuth.instance.currentUser?.uid;

          int idx = 0;
          if (targetUid != null) {
            final i = ordered.indexWhere((e) => e.uid == targetUid);
            if (i >= 0) idx = i;
          }

          _activeIndex = idx;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_activeIndex);
            }
            await context.read<UiProvider>().setActiveMemberUid(
              ordered[_activeIndex].uid,
            );
            setState(() => _appliedInitial = true);
          });
        }

        if (_activeIndex >= ordered.length) {
          _activeIndex = ordered.length - 1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_activeIndex);
            }
            setState(() {});
          });
        }

        final h = MediaQuery.of(context).size.height;
        final isShort = h < 640;
        debugPrint('Home labels=$ordered.map((e)=>e.label)');
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                IconButton(
                  tooltip: t.appTitle,
                  icon: const Icon(Icons.family_restroom),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 2),
                Text(t.appTitle),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'manage':
                      await showFamilyManager(context);
                      break;
                    case 'addCenter':
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManagePage()),
                      );
                      break;
                    case 'weekly':
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WeeklyPage()),
                      );
                      break;
                    case 'config':
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConfigurationPage(),
                        ),
                      );
                      break;
                    case 'privacy':
                      await Navigator.pushNamed(context, '/privacy');
                      break;
                    case 'signout':
                      await context.read<TaskCloudProvider>().teardown();
                      await context.read<ItemCloudProvider>().teardown();
                      await context.read<WeeklyCloudProvider>().teardown();
                      await context.read<ExpenseCloudProvider>().teardown();
                      await context.read<LocationCloudProvider>().teardown();
                      context.read<FamilyProvider>().clearActive();

                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;

                      await Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (route) => false,
                      );
                      break;
                  }
                },
                itemBuilder: (ctx) => _buildMainMenuItems(ctx, t),
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
                      child: Text(t.dismiss),
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
                              if (!mounted) return;

                              if (dest == SummaryDest.weekly) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WeeklyPage(),
                                  ),
                                );
                                return;
                              }

                              // 🟢 YENİ: _jumpTo çağır → içinde hem setState hem de start/stopListening var
                              _jumpTo(switch (dest) {
                                SummaryDest.tasks => HomeSection.tasks,
                                SummaryDest.items => HomeSection.items,
                                SummaryDest.expenses => HomeSection.expenses,
                                SummaryDest.weekly =>
                                  _section, // zaten yukarıda push edildi
                              });
                            },
                          ),

                          const SizedBox(height: 4),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            layoutBuilder: (currentChild, previousChildren) =>
                                Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                ),
                            child: (_section == HomeSection.expenses)
                                ? const _ExpensesMiniCentered(
                                    key: ValueKey('exp-mini-on'),
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
                              itemCount: ordered.length,
                              itemBuilder: (context, i) {
                                final ent = ordered[i]; // FamilyMemberEntry
                                final uid = ent.uid;
                                final label = ent.label;

                                final card = (_section == HomeSection.expenses)
                                    ? ExpensesCard(memberUid: uid)
                                    : _MemberCardForUid(
                                        uid: uid,
                                        label: label,
                                        section: _section,
                                        onJumpSection: _jumpTo,
                                      );

                                final versionKey = ValueKey<String>(
                                  'member-$i-s${_section.name}',
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
                            names: ordered.map((e) => e.label).toList(),
                            activeIndex: _activeIndex,
                            onPickIndex: (i) async {
                              setState(() => _activeIndex = i);
                              if (_pageController.hasClients) {
                                await _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                              await context
                                  .read<UiProvider>()
                                  .setActiveMemberUid(ordered[i].uid);
                            },
                          ),

                          if (!isShort) const SizedBox(height: 24),
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

class _MemberCardForUid extends StatelessWidget {
  final String uid;
  final String label;
  final HomeSection section;
  final void Function(HomeSection) onJumpSection;

  const _MemberCardForUid({
    required this.uid,
    required this.label,
    required this.section,
    required this.onJumpSection,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<TaskCloudProvider, List<Task>>(
      selector: (ctx, p) =>
          p.tasks.where((t) => t.assignedToUid == uid).toList(growable: false),
      shouldRebuild: _listChangedShallow<Task>,
      builder: (_, memberTasks, __) {
        return Selector<ItemCloudProvider, List<Item>>(
          selector: (ctx, p) => p.items
              .where((it) => it.assignedToUid == uid)
              .toList(growable: false),
          shouldRebuild: _listChangedShallow<Item>,
          builder: (_, memberItems, __) {
            return MemberCard(
              memberUid: uid,
              memberName: label,
              tasks: memberTasks,
              items: memberItems,
              section: section,
              onJumpSection: onJumpSection,
            );
          },
        );
      },
    );
  }
}

/// Basit, hızlı shallow karşılaştırma – gereksiz rebuild’leri keser
bool _listChangedShallow<T>(List<T> prev, List<T> next) {
  if (identical(prev, next)) return false;
  if (prev.length != next.length) return true;
  for (var i = 0; i < prev.length; i++) {
    if (!identical(prev[i], next[i])) return true;
  }
  return false;
}

class _ExpensesMiniCentered extends StatelessWidget {
  const _ExpensesMiniCentered({super.key});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseCloudProvider>();
    final list = expProv.all; // sıralı kopya, UI için ideal
    if (list.isEmpty) {
      return const SizedBox(height: 56); // ufak yer tutucu
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ExpensesMiniSummary(expenses: list, onTap: null),
      ),
    );
  }
}

List<FamilyMemberEntry> _orderWithMeFirstEntries(List<FamilyMemberEntry> list) {
  final idx = list.indexWhere((e) => e.label.startsWith('You ('));
  if (idx <= 0) return list;
  final copy = [...list];
  final me = copy.removeAt(idx);
  copy.insert(0, me);
  return copy;
}

Future<void> debugFam(String fid) async {
  final db = FirebaseFirestore.instance;
  final actor = FirebaseAuth.instance.currentUser?.uid;
  final doc = await db.collection('families').doc(fid).get();
  final data = (doc.data() ?? <String, dynamic>{});

  final owner = data['ownerUid'];
  final membersMap =
      (data['members'] as Map?)?.cast<String, dynamic>() ?? const {};
  final memberKeys = membersMap.keys.toList();

  debugPrint(
    '[FamCheck] fid=$fid owner=$owner memberKeys=$memberKeys actor=$actor '
    'containsActor=${memberKeys.contains(actor)}',
  );
}

Future<void> ensureMembership(String familyId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || familyId.isEmpty) return;

  final ref = FirebaseFirestore.instance.collection('families').doc(familyId);

  final snap = await ref.get();
  if (!snap.exists) {
    throw StateError('Family does not exist');
  }

  final data = snap.data() ?? {};
  final members = (data['members'] as Map<String, dynamic>? ?? {});
  final roleNow = members[uid] as String?;

  // Zaten üyeyse dokunma
  if (roleNow != null && roleNow.isNotEmpty) return;

  // 2) Sadece kendi key'ini ekle (DERİN MERGE YOK, DOT-PATH VAR)
  await ref.update({
    'members.$uid': 'editor', // varsayılan rol
    'updatedAt': FieldValue.serverTimestamp(),
  });
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
