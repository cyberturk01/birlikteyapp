import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_provider.dart';

/// Aile adı yazarken kullanılabilecek akıllı öneri alanı.
/// - TextField + altında öneri chip'leri
/// - Input değişince debounce ile FamilyProvider.suggestFamilyNames çağırır
class FamilyNameSuggestField extends StatefulWidget {
  final TextEditingController controller;

  /// Öneri seçilince bilgilendirme (opsiyonel)
  final ValueChanged<String>? onPickSuggestion;

  /// TextField decoration (opsiyonel, default verilir)
  final InputDecoration? decoration;

  const FamilyNameSuggestField({
    super.key,
    required this.controller,
    this.onPickSuggestion,
    this.decoration,
  });

  @override
  State<FamilyNameSuggestField> createState() => _FamilyNameSuggestFieldState();
}

class _FamilyNameSuggestFieldState extends State<FamilyNameSuggestField> {
  List<String> _suggests = const [];
  bool _loading = false;
  Timer? _debounce;
  int _reqToken = 0; // en son istek için token (yarışları önlemek için)

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _kick(); // ilk kez boş/başlangıçta da çalışsın
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _kick);
  }

  Future<void> _kick() async {
    final base = widget.controller.text.trim();
    if (base.isEmpty) {
      if (!mounted) return;
      setState(() {
        _suggests = const [];
        _loading = false;
      });
      return;
    }

    final token = ++_reqToken;
    setState(() => _loading = true);

    try {
      final prov = context.read<FamilyProvider>();
      final list = await prov.suggestFamilyNames(base, limit: 5);
      if (!mounted || token != _reqToken) return; // eski isteği at
      setState(() {
        _suggests = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _reqToken) return;
      setState(() {
        _suggests = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deco =
        widget.decoration ??
        const InputDecoration(
          labelText: 'Family name',
          hintText: 'e.g., Yigit Family',
          border: OutlineInputBorder(),
          isDense: true,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: deco.copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lightbulb),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_suggests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggests.map((s) {
              return ActionChip(
                label: Text(s),
                onPressed: () {
                  widget.controller.text = s;
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: s.length),
                  );
                  widget.onPickSuggestion?.call(s);
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
