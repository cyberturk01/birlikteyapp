import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async => await initTestEnv());
  tearDownAll(() async => await disposeTestEnv());
  test('tasksForDay canonical eşleşir', () {
    final fake = FakeFirebaseFirestore();
    final p = WeeklyCloudProvider(db: fake);
    p.debugInject([
      WeeklyTaskCloud('Pazartesi', 'A'),
      WeeklyTaskCloud('Monday', 'B'),
      WeeklyTaskCloud('Dienstag', 'C'),
    ]);
    final mon = p.tasksForDay('Monday');
    expect(mon.map((e) => e.title).toList()..sort(), ['A', 'B']);
    final tue = p.tasksForDay('Tuesday');
    expect(tue.single.title, 'C');
  });
}
