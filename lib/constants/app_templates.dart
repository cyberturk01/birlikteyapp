import 'package:flutter/foundation.dart';

@immutable
class TemplatePack {
  final String id;
  final String name;
  final String description;
  final List<String> tasks; // anlık görevler
  final List<String> items; // market
  // weekly: (day, title)
  final List<(String, String)> weekly;

  const TemplatePack({
    required this.id,
    required this.name,
    required this.description,
    this.tasks = const [],
    this.items = const [],
    this.weekly = const [],
  });
}

class AppTemplates {
  static const cleaningDay = TemplatePack(
    id: 'tpl_cleaning',
    name: 'Cleaning Day',
    description: 'House cleanup routine',
    tasks: [
      'Vacuum the living room',
      'Mop the kitchen',
      'Clean the bathroom',
      'Dust the shelves',
      'Take out the trash',
    ],
    weekly: [
      ('Saturday', 'Deep clean kitchen'),
      ('Sunday', 'Change bedsheets'),
    ],
  );

  static const weeklyKitchen = TemplatePack(
    id: 'tpl_weekly_kitchen',
    name: 'Weekly Kitchen Shopping',
    description: 'Basic fridge & pantry refill',
    items: [
      'Milk',
      'Eggs',
      'Bread',
      'Cheese',
      'Tomatoes',
      'Onions',
      'Potatoes',
      'Olive oil',
      'Rice',
      'Pasta',
    ],
    weekly: [
      ('Tuesday', 'Check pantry & fridge'),
      ('Wednesday', 'Make shopping list'),
    ],
  );

  static const laundryDay = TemplatePack(
    id: 'tpl_laundry',
    name: 'Laundry Day',
    description: 'Clothes + linens cycle',
    tasks: [
      'Sort clothes',
      'Run washing machine',
      'Hang to dry',
      'Fold and put away',
      'Change bedsheets',
    ],
    weekly: [('Monday', 'Wash darks'), ('Thursday', 'Wash whites')],
  );

  static const guestsComing = TemplatePack(
    id: 'tpl_guests',
    name: 'Guests Coming',
    description: 'Prep home + quick grocery',
    tasks: ['Tidy up living room', 'Clean guest bathroom', 'Prepare snacks'],
    items: ['Tea', 'Coffee', 'Snacks', 'Fruit', 'Paper towels'],
    weekly: [('Friday', 'Pre-guest tidy-up')],
  );

  static const all = <TemplatePack>[
    cleaningDay,
    weeklyKitchen,
    laundryDay,
    guestsComing,
  ];
}
