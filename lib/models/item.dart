import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 1)
class Item extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool bought;

  @HiveField(2)
  String? assignedTo;

  String? remoteId;

  Item(this.name, {this.bought = false, this.assignedTo, this.remoteId});
}
