import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/ui_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../widgets/leaderboard_page.dart';
import '../family/family_manager.dart';
import '../home/home_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final famProv = context.watch<FamilyProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Togetherly — ${AppLocalizations.of(context)!.welcome}'),
          bottom: TabBar(
            tabs: [
              Tab(
                text: AppLocalizations.of(context)!.members,
                icon: const Icon(Icons.group),
              ),
              Tab(
                text: AppLocalizations.of(context)!.leaderboard,
                icon: const Icon(Icons.emoji_events),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: AppLocalizations.of(context)!.language, // "Language"
              icon: const Icon(Icons.language),
              onPressed: () => _showLanguageSheet(context),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.signOut,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
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
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: TabBarView(
            children: [
              // TAB 1
              StreamBuilder<List<FamilyMemberEntry>>(
                stream: famProv.watchMemberEntries(),
                builder: (_, snap) {
                  final raw = snap.data ?? const <FamilyMemberEntry>[];
                  if (snap.connectionState == ConnectionState.waiting &&
                      raw.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (raw.isEmpty) return _buildEmpty(context);

                  final meUid = FirebaseAuth.instance.currentUser?.uid;
                  final entries = List<FamilyMemberEntry>.from(raw);
                  entries.sort((a, b) {
                    if (a.uid == meUid && b.uid != meUid) return -1;
                    if (b.uid == meUid && a.uid != meUid) return 1;
                    return a.label.toLowerCase().compareTo(
                      b.label.toLowerCase(),
                    );
                  });

                  final filtered = _query.isEmpty
                      ? entries
                      : entries
                            .where(
                              (e) => e.label.toLowerCase().contains(
                                _query.toLowerCase(),
                              ),
                            )
                            .toList();

                  final visible = filtered.take(4).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.welcomeBack,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: AppLocalizations.of(context)!.addMember,
                            icon: const Icon(Icons.person_add_alt_1),
                            onPressed: () => showFamilyManager(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(AppLocalizations.of(context)!.pickMember),
                      const SizedBox(height: 12),

                      if (entries.length > 4) ...[
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: AppLocalizations.of(
                              context,
                            )!.searchMember,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (visible.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noMembersFound,
                            ),
                          ),
                        )
                      else if (visible.isNotEmpty) ...[
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visible.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.15,
                                ),
                            itemBuilder: (_, i) {
                              final e = visible[i];
                              return _MemberTile(
                                label: e.label,
                                photoUrl: e.photoUrl,
                                onTap: () async {
                                  await context
                                      .read<UiProvider>()
                                      .setActiveMemberUid(e.uid);
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HomePage(
                                        initialFilterMemberUid: e.uid,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 👇 Görsel buraya
                        Center(
                          child: Image.asset(
                            'assets/images/family_welcome.png',
                            height: 220, // çok büyük olmasın
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      if (filtered.length > 4)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.groups),
                            label: Text(
                              '${AppLocalizations.of(context)!.seeAllMembers} ${filtered.length}',
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _AllMembersPageUid(
                                    initialList: entries,
                                    initialQuery: _query,
                                    onPickUid: (uid) async {
                                      await context
                                          .read<UiProvider>()
                                          .setActiveMemberUid(uid);
                                      if (!context.mounted) return;
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HomePage(
                                            initialFilterMemberUid: uid,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),

              // TAB 2: Members (UID tabanlı)
              Column(
                children: [
                  const Expanded(child: LeaderboardPage()),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.dashboard_customize),
                      label: Text(AppLocalizations.of(context)!.goToDashboard),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.family_restroom, size: 42),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.setupFamily,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.setupFamilyDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(AppLocalizations.of(context)!.addFirstMember),
                    onPressed: () async {
                      await showFamilyManager(context);
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.setupFamilyHint,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String label;
  final String? photoUrl;
  final VoidCallback onTap;
  const _MemberTile({required this.label, required this.onTap, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? Text(initial)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tüm üyeler (UID tabanlı)
class _AllMembersPageUid extends StatefulWidget {
  final List<FamilyMemberEntry> initialList;
  final String initialQuery;
  final ValueChanged<String> onPickUid;

  const _AllMembersPageUid({
    required this.initialList,
    required this.initialQuery,
    required this.onPickUid,
  });

  @override
  State<_AllMembersPageUid> createState() => _AllMembersPageUidState();
}

class _AllMembersPageUidState extends State<_AllMembersPageUid> {
  late TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchCtrl = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.initialList
        .where(
          (e) =>
              _query.isEmpty ||
              e.label.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.allMembers)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: AppLocalizations.of(context)!.searchMember,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  int cross = 2;
                  if (c.maxWidth >= 1200) {
                    cross = 6;
                  } else if (c.maxWidth >= 900) {
                    cross = 5;
                  } else if (c.maxWidth >= 700) {
                    cross = 4;
                  } else if (c.maxWidth >= 520) {
                    cross = 3;
                  }

                  return GridView.builder(
                    itemCount: list.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return _MemberTile(
                        label: e.label,
                        photoUrl: e.photoUrl,
                        onTap: () => widget.onPickUid(e.uid),
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

void _showLanguageSheet(BuildContext context) {
  final ui = context.read<UiProvider>();
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 8,
          children: [
            Text(
              AppLocalizations.of(context)!.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Locale>(
              value: ui.locale ?? Localizations.localeOf(context),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('tr'), child: Text('Türkçe')),
                DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
              ],
              onChanged: (loc) {
                if (loc != null) ui.setLocale(loc);
                Navigator.pop(context);
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.language,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showLanguagePicker(BuildContext context) {
  final ui = context.read<UiProvider>();
  final t = AppLocalizations.of(context)!;
  final current = ui.locale ?? Localizations.localeOf(context);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      Widget tile(Locale loc, String name) {
        final selected = current.languageCode == loc.languageCode;
        return ListTile(
          leading: const Icon(Icons.language),
          title: Text(name),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () {
            ui.setLocale(loc);
            Navigator.pop(context);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.language, // "Language"
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              tile(const Locale('en'), 'English'),
              tile(const Locale('tr'), 'Türkçe'),
              tile(const Locale('de'), 'Deutsch'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
