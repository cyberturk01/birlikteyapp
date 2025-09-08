import 'package:birlikteyapp/pages/landing/splash_screen.dart';
import 'package:birlikteyapp/providers/ui_provider.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'constants/app_lists.dart';
import 'models/item.dart';
import 'models/task.dart';
import 'models/weekly_task.dart';
import 'providers/family_provider.dart';
import 'providers/item_provider.dart';
import 'providers/task_provider.dart';
import 'providers/weekly_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final defaultTasks = AppLists.defaultTasks;

  final defaultItems = AppLists.defaultItems;

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(WeeklyTaskAdapter());

  // Open boxes
  await Hive.openBox<String>('familyBox');
  await Hive.openBox<Task>('taskBox');
  await Hive.openBox<Item>('itemBox');
  await Hive.openBox<int>('taskCountBox');
  await Hive.openBox<int>('itemCountBox');
  await Hive.openBox<WeeklyTask>('weeklyBox');
  await Hive.openBox<int>('weeklyNotifBox');

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyProvider()),
        ChangeNotifierProvider(create: (_) => UiProvider()),
      ],
      child: FamilyApp(),
    ),
  );
}

class FamilyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Togtherly',
      themeMode: ui.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
