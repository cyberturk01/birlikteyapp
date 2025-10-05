import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async => await initTestEnv()); // setUpTestHive + openBox
  tearDownAll(() async => await disposeTestEnv());

  late WeeklyCloudProvider p;

  setUp(() {
    final fake = FakeFirebaseFirestore();
    final box = Hive.box<int>('weeklyNotifCloudBox');
    p = WeeklyCloudProvider(db: fake, notifBox: box); // ✅ kutu hazır
  });

  group('_canonicalDay', () {
    test('English forms', () {
      expect(p.canonicalDayForTest('Monday'), 'Monday');
      expect(p.canonicalDayForTest('mon'), 'Monday');
      expect(p.canonicalDayForTest('Tue'), 'Tuesday');
      expect(p.canonicalDayForTest('wed '), 'Wednesday');
      expect(p.canonicalDayForTest('thu'), 'Thursday');
      expect(p.canonicalDayForTest('fri'), 'Friday');
      expect(p.canonicalDayForTest('sat'), 'Saturday');
      expect(p.canonicalDayForTest('sun'), 'Sunday');
    });

    test('Turkish forms', () {
      expect(p.canonicalDayForTest('Pazartesi'), 'Monday');
      expect(p.canonicalDayForTest('pzt'), 'Monday');
      expect(p.canonicalDayForTest('salı'), 'Tuesday');
      expect(p.canonicalDayForTest('çarşamba'), 'Wednesday');
      expect(p.canonicalDayForTest('car'), 'Wednesday');
      expect(p.canonicalDayForTest('perşembe'), 'Thursday');
      expect(p.canonicalDayForTest('cuma'), 'Friday');
      expect(p.canonicalDayForTest('cumartesi'), 'Saturday');
      expect(p.canonicalDayForTest('cmt'), 'Saturday');
      expect(p.canonicalDayForTest('pazar'), 'Sunday');
      expect(p.canonicalDayForTest('paz'), 'Sunday');
    });

    test('German forms', () {
      expect(p.canonicalDayForTest('Montag'), 'Monday');
      expect(p.canonicalDayForTest('Mo'), 'Monday');
      expect(p.canonicalDayForTest('Dienstag'), 'Tuesday');
      expect(p.canonicalDayForTest('Di'), 'Tuesday');
      expect(p.canonicalDayForTest('Mittwoch'), 'Wednesday');
      expect(p.canonicalDayForTest('Mi'), 'Wednesday');
      expect(p.canonicalDayForTest('Donnerstag'), 'Thursday');
      expect(p.canonicalDayForTest('Do'), 'Thursday');
      expect(p.canonicalDayForTest('Freitag'), 'Friday');
      expect(p.canonicalDayForTest('Fr'), 'Friday');
      expect(p.canonicalDayForTest('Samstag'), 'Saturday');
      expect(p.canonicalDayForTest('Sonnabend'), 'Saturday');
      expect(p.canonicalDayForTest('Sa'), 'Saturday');
      expect(p.canonicalDayForTest('Sonntag'), 'Sunday');
      expect(p.canonicalDayForTest('So'), 'Sunday');
    });
  });
}
