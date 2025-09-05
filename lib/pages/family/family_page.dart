import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/family_provider.dart';

class FamilyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Family Members")),
      body: ListView.builder(
        itemCount: familyProvider.familyMembers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(familyProvider.familyMembers[index]),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => familyProvider.removeMember(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TextEditingController controller = TextEditingController();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Add Family Member"),
                content: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: "Enter name"),
                ),
                actions: [
                  TextButton(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    child: Text("Add"),
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        familyProvider.addMember(controller.text);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
