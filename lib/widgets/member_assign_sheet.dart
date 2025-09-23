import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_provider.dart';
import 'member_dropdown_uid.dart';

class MemberAssignSheet extends StatelessWidget {
  final String title;
  final String nullLabel;
  final String? initial; // null = unassigned
  final ValueChanged<String?> onSave;

  const MemberAssignSheet({
    super.key,
    required this.title,
    required this.nullLabel,
    required this.initial,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String nullLabel,
    required String? initial,
    required ValueChanged<String?> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        String? selected = initial; // local state
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              // labels dinamik: family değişince dropdown da güncellenir
              final fam = ctx.watch<FamilyProvider>();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MemberDropdownUid(
                    value: selected,
                    onChanged: (v) => setLocal(() => selected = v),
                    label: 'Assign to',
                    nullLabel: nullLabel,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onSave(
                          (selected != null && selected!.trim().isNotEmpty)
                              ? selected
                              : null,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
