import 'package:flutter/material.dart';

typedef QuickAddSubmit = Future<void> Function(String text);

class QuickAddSheet extends StatelessWidget {
  final String title; // "Add task for Ali" / "Add item for Ali"
  final String hintText; // "Enter task…" / "Enter item…"
  final IconData leadingIcon; // Icons.task_alt / Icons.shopping_bag
  final List<String> suggestions; // chip önerileri
  final QuickAddSubmit onSubmit; // kullanıcı yazıp "Add" deyince
  final String addButtonText; // "Add"
  final String? initialValue; // opsiyonel: textfield başlangıç değeri

  const QuickAddSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.leadingIcon,
    required this.suggestions,
    required this.onSubmit,
    this.addButtonText = 'Add',
    this.initialValue,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String hintText,
    required IconData leadingIcon,
    required List<String> suggestions,
    required QuickAddSubmit onSubmit,
    String addButtonText = 'Add',
    String? initialValue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => QuickAddSheet(
        title: title,
        hintText: hintText,
        leadingIcon: leadingIcon,
        suggestions: suggestions,
        onSubmit: onSubmit,
        addButtonText: addButtonText,
        initialValue: initialValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = TextEditingController(text: initialValue ?? '');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: Icon(leadingIcon),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _commit(context, c.text),
              ),
              const SizedBox(height: 12),

              if (suggestions.isNotEmpty) ...[
                Text(
                  "Suggestions",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions.map((name) {
                        return ActionChip(
                          label: Text(name),
                          onPressed: () => _commit(context, name),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(addButtonText),
                  onPressed: () => _commit(context, c.text),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _commit(BuildContext context, String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    await onSubmit(text);
    if (context.mounted) Navigator.pop(context);
  }
}
