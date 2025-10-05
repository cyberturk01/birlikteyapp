import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async => await initTestEnv());
  tearDownAll(() async => await disposeTestEnv());
  test('sort by time then title', () {
    final fake = FakeFirebaseFirestore();
    final p = WeeklyCloudProvider(db: fake);
    p.debugInject([
      WeeklyTaskCloud('Monday', 'Bake cake', hour: 9, minute: 30),
      WeeklyTaskCloud('Monday', 'Alpha', hour: 9, minute: 30),
      WeeklyTaskCloud('Monday', 'Zeta'),
      WeeklyTaskCloud('Monday', 'Brush', hour: 8, minute: 0),
    ]);
    final s = p.tasksForDaySorted('Monday');
    expect(s.map((e) => e.title).toList(), [
      'Brush',
      'Alpha',
      'Bake cake',
      'Zeta',
    ]);
  });
}
