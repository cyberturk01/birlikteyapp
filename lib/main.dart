import 'package:birlikteyapp/pages/home/home_page.dart';
import 'package:birlikteyapp/providers/expense_provider.dart';
import 'package:birlikteyapp/providers/templates_provider.dart';
import 'package:birlikteyapp/providers/ui_provider.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:birlikteyapp/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/login_page.dart';
import 'constants/app_lists.dart';
import 'firebase_options.dart';
import 'models/expense.dart';
import 'models/item.dart';
import 'models/task.dart';
import 'models/user_template.dart';
import 'models/weekly_task.dart';
import 'providers/family_provider.dart';
import 'providers/item_provider.dart';
import 'providers/task_provider.dart';
import 'providers/weekly_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // // Activate App Check
  // await FirebaseAppCheck.instance.activate(
  //   // You can also use a debug provider for local testing
  //   androidProvider: AndroidProvider.playIntegrity,
  // );

  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortestLogical =
      view.physicalSize.shortestSide / view.devicePixelRatio;

  // 600+ logical px → tablet kabul (Material breakpoint)
  final isTablet = shortestLogical >= 600;

  await SystemChrome.setPreferredOrientations(
    isTablet
        ? <DeviceOrientation>[
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : <DeviceOrientation>[
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
  );
  await NotificationService.init();

  final defaultTasks = AppLists.defaultTasks;

  final defaultItems = AppLists.defaultItems;

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(WeeklyTaskAdapter());
  Hive.registerAdapter(UserTemplateAdapter());
  Hive.registerAdapter(WeeklyEntryAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // Open boxes
  await Hive.openBox<String>('familyBox');
  await Hive.openBox<Task>('taskBox');
  await Hive.openBox<Item>('itemBox');
  await Hive.openBox<int>('taskCountBox');
  await Hive.openBox<int>('itemCountBox');
  await Hive.openBox<WeeklyTask>('weeklyBox');
  await Hive.openBox<int>('weeklyNotifBox');
  await Hive.openBox<UserTemplate>('userTemplates');
  await Hive.openBox<Expense>('expenseBox');

  final taskBox = Hive.box<Task>('taskBox');
  if (taskBox.isEmpty) {
    for (var t in defaultTasks) {
      taskBox.add(Task(t));
    }
  }

  final itemBox = Hive.box<Item>('itemBox');
  if (itemBox.isEmpty) {
    for (var i in defaultItems) {
      itemBox.add(Item(i));
    }
  }
  final ui = UiProvider();
  await ui.loadPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyProvider()),
        ChangeNotifierProvider(create: (_) => UiProvider()),
        ChangeNotifierProvider(create: (_) => TemplatesProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => UiProvider()..loadPrefs()),
        ChangeNotifierProvider.value(value: ui),
      ],
      child: FamilyApp(),
    ),
  );
}

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Togetherly',
      themeMode: ui.themeMode,
      theme: AppTheme.light(ui.brand), // ✅ brand buradan
      darkTheme: AppTheme.dark(ui.brand),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return const LoginPage();
        }
        return const HomePage(); // mevcut ana sayfan
      },
    );
  }
}
