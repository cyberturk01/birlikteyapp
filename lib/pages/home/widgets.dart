import 'package:flutter/material.dart';

/// Küçük badge göstermek için
class AppBadge extends StatelessWidget {
  final String text;
  const AppBadge({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

/// Liste boşken görünen mesaj
class EmptyMessage extends StatelessWidget {
  final String text;
  const EmptyMessage({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).hintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Future<void> showFamilyManager(BuildContext context) async {
//   return showModalBottomSheet(
//     context: context,
//     useSafeArea: true,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//     ),
//     builder: (_) {
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 16),
//         // Buraya mevcut Aile Yönetimi widget'ınızı koyun:
//         // Örn: FamilyManagerSheet() ya da FamilyPage() vb.
//         child: _FamilyManagerSheet(), // <-- sende hangisiyse onu kullan
//       );
//     },
//   );
// }

/// Küçük başlık satırı (ör. "Tasks", "Market")
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
