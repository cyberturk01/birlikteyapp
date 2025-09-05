import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';
import '../home/family_manager.dart';
import '../home/home_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // arama için
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<FamilyProvider>().familyMembers;
    final hasMembers = members.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Togetherly — Welcome'),
        actions: [
          // İstersen buradan da family manager’ı açabilirsin:
          IconButton(
            tooltip: 'Manage Family',
            icon: const Icon(Icons.manage_accounts),
            onPressed: () => showFamilyManager(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: hasMembers
            ? _buildExisting(context, members)
            : _buildEmpty(context),
      ),
    );
  }

  // =================== ÜYE YOKSA ===================
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
            padding: const EdgeInsets.all(18.0),
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
                      // Aile yöneticisini aç
                      await showFamilyManager(context);
                      // Provider notifyListeners() tetiklediğinde build otomatik yenilenir.
                      if (!mounted) return;
                      setState(() {}); // güven olsun diye
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

  // =================== ÜYELER VARSA ===================
  Widget _buildExisting(BuildContext context, List<String> family) {
    final theme = Theme.of(context);

    // filtre
    final filtered = _query.isEmpty
        ? family
        : family
              .where((n) => n.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    // İlk ekranda en fazla 4 göster (2x2), kaydırma yok
    final int visibleCount = filtered.length > 4 ? 4 : filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Welcome back 👋',
                style: theme.textTheme.headlineSmall,
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
        Text('Pick a member to continue'),
        const SizedBox(height: 12),

        if (family.length > 4) ...[
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

        if (visibleCount == 0)
          const Expanded(child: Center(child: Text('No members found')))
        else
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleCount, // min(filtered.length, 4)
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2x2 sabit
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (_, i) {
                final name = filtered[i];
                return _MemberTile(
                  name: name,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(initialFilterMember: name),
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
                    builder: (_) => AllMembersPage(
                      initialList: family,
                      initialQuery: _query,
                      onPick: (name) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(initialFilterMember: name),
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
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _MemberTile({Key? key, required this.name, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 28, child: Text(initial)),
              const SizedBox(height: 10),
              Text(
                name,
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

// --- tam liste (opsiyonel) ---
class AllMembersPage extends StatefulWidget {
  final List<String> initialList;
  final String initialQuery;
  final ValueChanged<String> onPick;

  const AllMembersPage({
    Key? key,
    required this.initialList,
    required this.initialQuery,
    required this.onPick,
  }) : super(key: key);

  @override
  State<AllMembersPage> createState() => _AllMembersPageState();
}

class _AllMembersPageState extends State<AllMembersPage> {
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
          (n) =>
              _query.isEmpty || n.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('All members')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
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
                      final name = list[i];
                      return _MemberTile(
                        name: name,
                        onTap: () => widget.onPick(name),
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
