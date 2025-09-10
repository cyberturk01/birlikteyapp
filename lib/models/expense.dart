import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 8)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String? assignedTo;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? category;

  Expense(
    this.title,
    this.amount, {
    DateTime? date,
    this.assignedTo,
    this.category,
  }) : date = date ?? DateTime.now();
}
