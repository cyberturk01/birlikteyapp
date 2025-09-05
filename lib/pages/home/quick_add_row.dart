import 'package:flutter/material.dart';

const String kNoOne = '__NONE__';

class QuickAddRow extends StatefulWidget {
  final String hint;
  final List<String> familyMembers;
  final String? presetAssignee; // panel kişi filtresi varsa otomatik atama
  final void Function(String text, String? assignedTo) onSubmit;

  const QuickAddRow({
    Key? key,
    required this.hint,
    required this.familyMembers,
    required this.onSubmit,
    this.presetAssignee,
  }) : super(key: key);

  @override
  State<QuickAddRow> createState() => _QuickAddRowState();
}

class _QuickAddRowState extends State<QuickAddRow> {
  final TextEditingController _c = TextEditingController();
  String _selected = kNoOne; // sentinel

  @override
  void initState() {
    super.initState();
    if (widget.presetAssignee != null &&
        widget.presetAssignee!.trim().isNotEmpty) {
      _selected = widget.presetAssignee!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // input
        Expanded(
          child: TextField(
            controller: _c,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.add),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        // assignee
        DropdownButton<String>(
          value: _selected,
          hint: const Text('Assign'),
          items: [
            const DropdownMenuItem(value: kNoOne, child: Text('No one')),
            ...widget.familyMembers.map(
              (m) => DropdownMenuItem(value: m, child: Text(m)),
            ),
          ],
          onChanged: (v) => setState(() => _selected = v ?? kNoOne),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }

  void _submit() {
    final text = _c.text.trim();
    final assigned = (_selected == kNoOne) ? null : _selected;
    if (text.isNotEmpty) {
      widget.onSubmit(text, assigned);
      _c.clear();
      if (widget.presetAssignee == null || widget.presetAssignee!.isEmpty) {
        setState(() => _selected = kNoOne);
      }
    }
  }
}
