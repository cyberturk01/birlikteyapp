import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async => await initTestEnv());
  tearDownAll(() async => await disposeTestEnv());
  test('_canonicalDay: EN', () async {
    final fakeDb = FakeFirebaseFirestore();
    final box = await Hive.openBox<int>('weeklyNotifCloudBox');
    final p = WeeklyCloudProvider(db: fakeDb, notifBox: box);
    expect(p.canonicalDayForTest('Monday'), 'Monday');
    expect(p.canonicalDayForTest('Tue'), 'Tuesday');
    expect(p.canonicalDayForTest('sat'), 'Saturday');
  });

  test('_canonicalDay: TR', () async {
    final fakeDb = FakeFirebaseFirestore();
    final box = await Hive.openBox<int>('weeklyNotifCloudBox');
    final p = WeeklyCloudProvider(db: fakeDb, notifBox: box);
    expect(p.canonicalDayForTest('Pazartesi'), 'Monday');
    expect(p.canonicalDayForTest('Salı'), 'Tuesday');
    expect(p.canonicalDayForTest('Çarşamba'), 'Wednesday');
    expect(p.canonicalDayForTest('Perşembe'), 'Thursday');
    expect(p.canonicalDayForTest('Cuma'), 'Friday');
    expect(p.canonicalDayForTest('Cumartesi'), 'Saturday');
    expect(p.canonicalDayForTest('Pazar'), 'Sunday');
    // kısaltmalar:
    expect(p.canonicalDayForTest('Pzt'), 'Monday');
    expect(p.canonicalDayForTest('Cmt'), 'Saturday');
    expect(p.canonicalDayForTest('Paz'), 'Sunday');
  });

  test('_canonicalDay: DE', () async {
    final fakeDb = FakeFirebaseFirestore();
    final box = await Hive.openBox<int>('weeklyNotifCloudBox');
    final p = WeeklyCloudProvider(db: fakeDb, notifBox: box);
    expect(p.canonicalDayForTest('Montag'), 'Monday');
    expect(p.canonicalDayForTest('Dienstag'), 'Tuesday');
    expect(p.canonicalDayForTest('Mittwoch'), 'Wednesday');
    expect(p.canonicalDayForTest('Donnerstag'), 'Thursday');
    expect(p.canonicalDayForTest('Freitag'), 'Friday');
    expect(p.canonicalDayForTest('Samstag'), 'Saturday');
    expect(p.canonicalDayForTest('Sonnabend'), 'Saturday'); // kuzey varyant
    expect(p.canonicalDayForTest('Sonntag'), 'Sunday');
    // kısaltmalar:
    expect(p.canonicalDayForTest('Mo'), 'Monday');
    expect(p.canonicalDayForTest('Di'), 'Tuesday');
    expect(p.canonicalDayForTest('Sa'), 'Saturday');
  });
}
