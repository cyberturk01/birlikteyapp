import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../providers/item_provider.dart';
import '../member_dropdown.dart';

class AssignItemSheet extends StatefulWidget {
  final Item item;
  const AssignItemSheet({super.key, required this.item});

  @override
  State<AssignItemSheet> createState() => _AssignItemSheetState();
}

class _AssignItemSheetState extends State<AssignItemSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.item.assignedTo;
  }

  @override
  Widget build(BuildContext context) {
    final itemProv = context.read<ItemProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Assign item',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          MemberDropdown(
            value: _selected,
            onChanged: (v) => setState(() => _selected = v),
            label: 'Assign to',
            nullLabel: 'No one',
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                itemProv.updateAssignment(
                  widget.item,
                  (_selected != null && _selected!.trim().isNotEmpty)
                      ? _selected
                      : null,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
