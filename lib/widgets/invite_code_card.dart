import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/family_provider.dart';

class InviteCodeCard extends StatefulWidget {
  const InviteCodeCard({super.key});

  @override
  State<InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends State<InviteCodeCard> {
  String? _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final code = await context.read<FamilyProvider>().getInviteCode();
    if (!mounted) return;
    setState(() {
      _code = code;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  const Icon(Icons.vpn_key),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _code ?? t.noData,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: t.copy,
                    icon: const Icon(Icons.copy),
                    onPressed: (_code == null)
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: _code!),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                  ),
                  IconButton(
                    tooltip: t.share,
                    icon: const Icon(Icons.share),
                    onPressed: (_code == null)
                        ? null
                        : () {
                            Share.share(
                              'Join our family on Togetherly: $_code',
                            );
                          },
                  ),
                ],
              ),
      ),
    );
  }
}
