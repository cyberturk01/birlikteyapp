import 'package:hive/hive.dart';

part 'user_template.g.dart';

@HiveType(
  typeId: 35,
) // boş bir id seç; projendeki diğer typeId’lerle çakışmasın
class UserTemplate extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  List<String> tasks;

  @HiveField(3)
  List<String> items;

  /// weekly listesi: ('Monday', 'Take out trash') gibi tuple yerine
  /// Hive uyumu için küçük bir sınıf kullanalım:
  @HiveField(4)
  List<WeeklyEntry> weekly;

  UserTemplate({
    required this.name,
    required this.description,
    List<String>? tasks,
    List<String>? items,
    List<WeeklyEntry>? weekly,
  }) : tasks = tasks ?? [],
       items = items ?? [],
       weekly = weekly ?? [];
}

@HiveType(typeId: 36)
class WeeklyEntry {
  @HiveField(0)
  String day;
  @HiveField(1)
  String title;

  WeeklyEntry(this.day, this.title);
}
