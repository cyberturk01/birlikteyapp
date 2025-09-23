import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 1)
class Item extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool bought;

  @HiveField(2)
  String? assignedToUid;

  String? remoteId;

  Item(String name, {this.bought = false, this.assignedToUid, this.remoteId})
    : name = _capitalize(name);

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  factory Item.fromSnap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Item(
      (d['name'] as String).trim(),
      bought: (d['bought'] as bool?) ?? false,
      assignedToUid:
          (d['assignedToUid'] as String?) ??
          (d['assignedTo'] as String?), // GERİYE DÖNÜK
    )..remoteId = doc.id;
  }
}
