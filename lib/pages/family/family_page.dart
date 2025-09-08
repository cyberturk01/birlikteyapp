import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../providers/family_provider.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({Key? key}) : super(key: key);

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final TextEditingController _memberCtrl = TextEditingController();

  @override
  void dispose() {
    _memberCtrl.dispose();
    super.dispose();
  }

  void _addMember() {
    final familyProv = context.read<FamilyProvider>();
    final name = _memberCtrl.text.trim();
    if (name.isEmpty) return;

    final exists = familyProv.familyMembers.any(
      (m) => m.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This name already exists')));
      return;
    }

    familyProv.addMember(name); // void ise await yok
    _memberCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final familyProv = context.watch<FamilyProvider>();
    final members = familyProv.familyMembers;

    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: members.isEmpty
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_2, size: 56),
                      const SizedBox(height: 10),
                      Text(
                        'No family members yet',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _AddMemberRow(controller: _memberCtrl, onAdd: _addMember),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // Üstte tek satır hızlı ekleme
                  _AddMemberRow(controller: _memberCtrl, onAdd: _addMember),
                  const SizedBox(height: 12),

                  // Liste
                  Expanded(
                    child: ListView.separated(
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final name = members[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => familyProv.removeMember(i),
                          ),
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

// Tek yerde kullanılan küçük input satırı bileşeni
class _AddMemberRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddMemberRow({Key? key, required this.controller, required this.onAdd})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter member name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text(S.add),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../providers/family_provider.dart';
//
// class FamilyPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final familyProvider = Provider.of<FamilyProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Family Members")),
//       body: ListView.builder(
//         itemCount: familyProvider.familyMembers.length,
//         itemBuilder: (context, index) {
//           return ListTile(
//             title: Text(familyProvider.familyMembers[index]),
//             trailing: IconButton(
//               icon: Icon(Icons.delete, color: Colors.red),
//               onPressed: () => familyProvider.removeMember(index),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           TextEditingController controller = TextEditingController();
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: Text("Add Family Member"),
//                 content: TextField(
//                   controller: controller,
//                   decoration: InputDecoration(hintText: "Enter name"),
//                 ),
//                 actions: [
//                   TextButton(
//                     child: Text("Cancel"),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   ElevatedButton(
//                     child: Text("Add"),
//                     onPressed: () {
//                       if (controller.text.trim().isNotEmpty) {
//                         familyProvider.addMember(controller.text);
//                       }
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }
