import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';
import '../../widgets/leaderboard_page.dart';
import '../family/family_manager.dart';
import '../home/home_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);
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
          title: const Text('Togetherly — Welcome'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Leaderboard', icon: Icon(Icons.emoji_events)),
              Tab(text: 'Members', icon: Icon(Icons.group)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Manage Family',
              icon: const Icon(Icons.manage_accounts),
              onPressed: () => showFamilyManager(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: TabBarView(
            children: [
              // TAB 1
              Column(
                children: [
                  const Expanded(child: LeaderboardPage()),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.dashboard_customize),
                      label: const Text('Go to dashboard'),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // TAB 2: Members (UID tabanlı)
              StreamBuilder<List<FamilyMemberEntry>>(
                stream: famProv.watchMemberEntries(),
                builder: (_, snap) {
                  final entries = snap.data ?? const <FamilyMemberEntry>[];
                  if (snap.connectionState == ConnectionState.waiting &&
                      entries.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (entries.isEmpty) return _buildEmpty(context);

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
                              'Welcome back 👋',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add member',
                            icon: const Icon(Icons.person_add_alt_1),
                            onPressed: () => showFamilyManager(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Pick a member to continue'),
                      const SizedBox(height: 12),

                      if (entries.length > 4) ...[
                        TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search member…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (visible.isEmpty)
                        const Expanded(
                          child: Center(child: Text('No members found')),
                        )
                      else
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
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HomePage(initialFilterMember: e.uid),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 8),

                      if (filtered.length > 4)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.groups),
                            label: Text('See all members (${filtered.length})'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _AllMembersPageUid(
                                    initialList: entries,
                                    initialQuery: _query,
                                    onPickUid: (uid) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HomePage(
                                            initialFilterMember: uid,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    /* (seninkiyle aynı) */
    // ... (hiç değiştirmedim)
    // showFamilyManager(context) butonlu kart
    // return ...
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
                  'Let’s set up your family',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first family member to start sharing tasks and shopping lists together.',
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
                    label: const Text('Add first member'),
                    onPressed: () async {
                      await showFamilyManager(context);
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You can add more members anytime from the top-right.',
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
  final VoidCallback onTap;
  const _MemberTile({Key? key, required this.label, required this.onTap})
    : super(key: key);

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
              CircleAvatar(radius: 28, child: Text(initial)),
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
    Key? key,
    required this.initialList,
    required this.initialQuery,
    required this.onPickUid,
  }) : super(key: key);

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
      appBar: AppBar(title: const Text('All members')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search member…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  int cross = 2;
                  if (c.maxWidth >= 1200)
                    cross = 6;
                  else if (c.maxWidth >= 900)
                    cross = 5;
                  else if (c.maxWidth >= 700)
                    cross = 4;
                  else if (c.maxWidth >= 520)
                    cross = 3;

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
