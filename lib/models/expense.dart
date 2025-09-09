import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 8) // ⚠️ Projendeki diğer typeId’lerle çakışmasın
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String? assignedTo; // kimin harcaması (opsiyonel)

  @HiveField(3)
  DateTime date;

  Expense(this.title, this.amount, {this.assignedTo, DateTime? date})
    : date = date ?? DateTime.now();
}
