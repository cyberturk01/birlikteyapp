import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/family_provider.dart';
import '../../widgets/family_name_suggest_field.dart';

class FamilyOnboardingPage extends StatefulWidget {
  const FamilyOnboardingPage({super.key});

  @override
  State<FamilyOnboardingPage> createState() => _FamilyOnboardingPageState();
}

class _FamilyOnboardingPageState extends State<FamilyOnboardingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;

  bool _checking = false; // ad uygun mu kontrolü sürüyor
  bool _available = false; // ad uygun mu sonucu
  List<String> _suggestions = [];
  Timer? _debounce;
  int _reqToken = 0;

  bool _loading = false; // create/join işlemi
  String? _error;
  Timer? _nameDebounce;

  void _onNameChanged() {
    _nameDebounce?.cancel();
    final txt = _nameCtrl.text.trim();
    if (txt.isEmpty) {
      setState(() {
        _checking = false;
        _available = false;
      });
      return;
    }
    setState(() => _checking = true);

    _nameDebounce = Timer(const Duration(milliseconds: 350), () async {
      final myToken = ++_reqToken;
      final ok = !(await context.read<FamilyProvider>().isFamilyNameTaken(txt));
      if (!mounted || myToken != _reqToken) return;
      setState(() {
        _available = ok;
        _checking = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameDebounce?.cancel();
    _nameCtrl.removeListener(_onNameChanged);
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
    final t = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        throw t.errorFamilyNameEmpty;
      }
      if (!_available) {
        throw t.errorNameUnavailable;
      }

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
    final t = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      if (code.isEmpty) {
        throw t.errorInviteEmpty;
      }

      final ok = await context.read<FamilyProvider>().joinWithCode(code);
      if (!ok) {
        throw t.errorInviteInvalid;
      }
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
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: t.createFamilyTab),
            Tab(text: t.joinWithCodeTab),
          ],
        ),
        title: Text(t.setupFamily),
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
                                    t.chooseFamilyName,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FamilyNameSuggestField(
                                controller: _nameCtrl,
                                onPickSuggestion: (picked) {
                                  // Öneriye tıklandığında availability check’i tetikle
                                  _onNameChanged();
                                },
                                decoration: InputDecoration(
                                  labelText: t.familyNameLabel,
                                  hintText: t.familyNameHint,
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
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                              )),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
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
                                          t.nameCheckingOk,
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
                                              t.nameCheckingTaken,
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
                                      : Text(t.createFamilyCta),
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
                                    t.joinExistingFamily,
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
                                  labelText: t.inviteCode,
                                  hintText: t.inviteCodeHint,
                                  prefixIcon: const Icon(Icons.key),
                                  suffixIcon: IconButton(
                                    tooltip: t.paste,
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
                                      : Text(t.joinFamilyCta),
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
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.inviteYourFamily),
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
          Text(t.inviteShareHelp),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: Text(t.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) Navigator.pop(context);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.share),
          label: Text(t.share),
          onPressed: () async {
            await Share.share(t.inviteShareText(code));
            if (context.mounted) Navigator.pop(context);
          },
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.done),
        ),
      ],
    );
  }
}
