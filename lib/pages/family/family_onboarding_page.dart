import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/family_provider.dart';

class FamilyOnboardingPage extends StatefulWidget {
  const FamilyOnboardingPage({super.key});

  @override
  State<FamilyOnboardingPage> createState() => _FamilyOnboardingPageState();
}

class _FamilyOnboardingPageState extends State<FamilyOnboardingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _checking = false; // ad uygun mu kontrolü sürüyor
  bool _available = false; // ad uygun mu sonucu
  List<String> _suggestions = [];
  Timer? _debounce;

  bool _loading = false; // create/join işlemi
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    _nameCtrl.addListener(() {
      _error = null;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), _checkAvailability);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tab.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final txt = _nameCtrl.text.trim();
    if (txt.isEmpty) {
      setState(() {
        _available = false;
        _suggestions = [];
        _checking = false;
      });
      return;
    }
    setState(() => _checking = true);
    try {
      final fam = context.read<FamilyProvider>();
      final taken = await fam.isFamilyNameTaken(txt);
      if (taken) {
        final sugg = await fam.suggestFamilyNames(txt);
        setState(() {
          _available = false;
          _suggestions = sugg;
        });
      } else {
        setState(() {
          _available = true;
          _suggestions = [];
        });
      }
    } catch (e) {
      // sessizce yut
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _create() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) throw 'Aile adı boş olamaz';
      if (!_available) throw 'Bu isim şu an kullanılamıyor';

      final fam = context.read<FamilyProvider>();
      await fam.createFamily(name);

      // Invite modal: kodu göster-kopyala-paylaş-QR
      final code = await fam.getInviteCode(); // aşağıda ekliyoruz
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _InviteDialog(code: code ?? 'UNKNOWN'),
      );

      // AuthGate akışı Home/Splash’e götürecek
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      if (code.isEmpty) throw 'Davet kodu boş olamaz';

      final ok = await context.read<FamilyProvider>().joinWithCode(code);
      if (!ok) throw 'Geçersiz davet kodu';
      // AuthGate akışı devam ettirecek
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canCreate =
        _nameCtrl.text.trim().isNotEmpty && _available && !_loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your family'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Create family'),
            Tab(text: 'Join with code'),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Stack(
          children: [
            TabBarView(
              controller: _tab,
              children: [
                // ======= CREATE TAB =======
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.family_restroom, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Choose a family name',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Family name',
                                  hintText: 'e.g., Yigit Family',
                                  prefixIcon: const Icon(Icons.edit),
                                  suffixIcon: _checking
                                      ? const Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : (_nameCtrl.text.trim().isEmpty
                                            ? null
                                            : Icon(
                                                _available
                                                    ? Icons.check_circle
                                                    : Icons.error_outline,
                                                color: _available
                                                    ? Colors.green
                                                    : theme.colorScheme.error,
                                              )),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: (_nameCtrl.text.trim().isEmpty)
                                      ? const SizedBox.shrink()
                                      : _available
                                      ? Text(
                                          'Great! This name is available.',
                                          key: const ValueKey('ok'),
                                          style: TextStyle(
                                            color: Colors.green[700],
                                          ),
                                        )
                                      : Column(
                                          key: const ValueKey('sugg'),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'This name is taken. Try one of these:',
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: _suggestions.map((s) {
                                                return ActionChip(
                                                  label: Text(s),
                                                  onPressed: () {
                                                    _nameCtrl.text = s;
                                                    _nameCtrl.selection =
                                                        TextSelection.fromPosition(
                                                          TextPosition(
                                                            offset: s.length,
                                                          ),
                                                        );
                                                    _checkAvailability();
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: canCreate ? _create : null,
                                  icon: const Icon(Icons.check),
                                  label: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Create family'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ======= JOIN TAB =======
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.group_add, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Join an existing family',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _codeCtrl,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]'),
                                  ),
                                  UpperCaseTextFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Invite code',
                                  hintText: 'e.g., ABCD23',
                                  prefixIcon: const Icon(Icons.key),
                                  suffixIcon: IconButton(
                                    tooltip: 'Paste',
                                    icon: const Icon(Icons.paste),
                                    onPressed: () async {
                                      final clip = await Clipboard.getData(
                                        'text/plain',
                                      );
                                      final val = (clip?.text ?? '')
                                          .trim()
                                          .toUpperCase();
                                      if (val.isNotEmpty) {
                                        _codeCtrl.text = val;
                                        _codeCtrl.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(offset: val.length),
                                            );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _join,
                                  icon: const Icon(Icons.login),
                                  label: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Join family'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_error != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// === Invite Modal ===
class _InviteDialog extends StatelessWidget {
  final String code;
  const _InviteDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite your family'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // QR (opsiyonel)
          QrImageView(data: code, size: 160),
          const SizedBox(height: 12),
          const Text('Share this code with your family to join your home.'),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) Navigator.pop(context);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share'),
          onPressed: () async {
            await Share.share('Join our family on Togetherly: $code');
            if (context.mounted) Navigator.pop(context);
          },
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
