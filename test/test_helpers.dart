import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

/// Tüm testler başlamadan 1 kez çağır.
Future<void> initTestEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await setUpTestHive(); // temp path
  await Hive.openBox<int>(
    'weeklyNotifCloudBox',
  ); // WeeklyCloudProvider ile aynı ad
}

/// Tüm testler bitince çağır.
Future<void> disposeTestEnv() async {
  await tearDownTestHive(); // diskten temizler ve kapatır
}
