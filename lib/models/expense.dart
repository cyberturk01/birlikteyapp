import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 8)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String? assignedToUid;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? category;

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  Expense(
    this.amount, { // <-- amount ilk positional
    DateTime? date,
    this.assignedToUid,
    this.category,
  }) : title = '', // adapter zaten ..title = fields[0] yapıyor
       date = date ?? DateTime.now();

  factory Expense.withTitle(
    String rawTitle,
    double amount, {
    DateTime? date,
    String? assignedToUid,
    String? category,
  }) {
    final e = Expense(
      amount,
      date: date,
      assignedToUid: assignedToUid,
      category: category,
    );
    e.title = _capitalize(rawTitle);
    return e;
  }
}
