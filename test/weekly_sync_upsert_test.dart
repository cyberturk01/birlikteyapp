import 'package:birlikteyapp/models/task.dart';
import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:birlikteyapp/services/auth_service.dart';
import 'package:birlikteyapp/services/scores_repo.dart';
import 'package:birlikteyapp/services/task_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

class _TaskProvFake extends TaskCloudProvider {
  final List<Task> _mem = [];

  _TaskProvFake()
    : super(
        _DummyAuth(),
        _DummyTask(),
        _DummyScore(),
        firebaseAuth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'u1'),
        ),
      );

  // Listeyi tamamen in-memory yönetelim
  @override
  List<Task> get tasks => _mem;

  @override
  Future<void> addTask(Task t) async => _mem.add(t);

  @override
  Future<void> renameTask(Task t, String v) async {
    final idx = _mem.indexOf(t);
    if (idx != -1) _mem[idx].name = v;
  }

  @override
  Future<void> updateAssignment(Task t, String? v) async {
    final idx = _mem.indexOf(t);
    if (idx != -1) _mem[idx].assignedToUid = v;
  }

  // ⬇️ KRİTİK: Firestore'a gitmeyen upsert
  @override
  Future<void> upsertByOrigin({
    required String origin,
    required String title,
    String? assignedToUid,
  }) async {
    // 1) aynı origin varsa: alanları güncelle
    final i = _mem.indexWhere((t) => t.origin == origin);
    if (i != -1) {
      if (_mem[i].name != title) _mem[i].name = title;
      if ((_mem[i].assignedToUid ?? '') != (assignedToUid ?? '')) {
        _mem[i].assignedToUid = (assignedToUid?.trim().isEmpty ?? true)
            ? null
            : assignedToUid!.trim();
      }
      return;
    }
    // 2) yoksa: yeni task ekle
    _mem.add(Task(title, assignedToUid: assignedToUid, origin: origin));
  }
}

class _DummyAuth implements AuthService {
  dynamic noSuchMethod(_) => null;
}

class _DummyTask implements TaskService {
  dynamic noSuchMethod(_) => null;
}

class _DummyScore implements ScoresRepo {
  dynamic noSuchMethod(_) => null;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestEnv(); // setUpTestHive + openBox
  });
  tearDownAll(() async => await disposeTestEnv());

  String todayCanon() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  test('sync upsert & no duplicate by origin', () async {
    final box = Hive.box<int>('weeklyNotifCloudBox');
    final weekly = WeeklyCloudProvider(
      db: FakeFirebaseFirestore(),
      notifBox: box,
    );

    final taskProv = _TaskProvFake();

    // Monday senaryosu
    weekly.debugInject([
      WeeklyTaskCloud(todayCanon(), 'Take out trash', assignedToUid: 'u1')
        ..id = 'w1',
    ]);

    await weekly.syncTodayToTasks(taskProv);
    expect(taskProv.tasks.length, 1);
    expect(taskProv.tasks.first.origin, 'weekly:w1');

    // tekrar sync
    await weekly.syncTodayToTasks(taskProv);
    expect(taskProv.tasks.length, 1);

    // upsert
    weekly.debugInject([
      WeeklyTaskCloud(todayCanon(), 'Take out trash NOW', assignedToUid: 'u1')
        ..id = 'w1',
    ]);
    await weekly.syncTodayToTasks(taskProv);
    expect(taskProv.tasks.length, 1);
    expect(taskProv.tasks.first.name, 'Take out trash NOW');
  });
}
