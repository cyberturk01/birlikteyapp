import 'package:birlikteyapp/pages/landing/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/item.dart';
import 'models/task.dart';
import 'models/weekly_task.dart';
import 'providers/family_provider.dart';
import 'providers/item_provider.dart';
import 'providers/task_provider.dart';
import 'providers/weekly_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final defaultTasks = [
    "Take out the trash",
    "Clean the kitchen",
    "Do the laundry",
    "Vacuum the living room",
    "Water the plants",
    "Cook dinner",
    "Wash the dishes",
    "Change the bedsheets",
    "Iron clothes",
    "Organize the fridge",
  ];

  final defaultItems = [
    "Milk",
    "Bread",
    "Eggs",
    "Butter",
    "Cheese",
    "Rice",
    "Pasta",
    "Tomatoes",
    "Potatoes",
    "Onions",
    "Apples",
    "Bananas",
    "Chicken",
    "Beef",
    "Fish",
    "Olive oil",
    "Salt",
    "Sugar",
    "Coffee",
    "Tea",
  ];

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(WeeklyTaskAdapter()); // NEW

  // Open boxes
  await Hive.openBox<String>('familyBox');
  await Hive.openBox<Task>('taskBox');
  await Hive.openBox<Item>('itemBox');
  await Hive.openBox<int>('taskCountBox');
  await Hive.openBox<int>('itemCountBox');
  await Hive.openBox<WeeklyTask>('weeklyBox'); // NEW

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
      ],
      child: FamilyApp(),
    ),
  );
}

class FamilyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Togetherly',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SplashScreen(),
    );
  }
}
