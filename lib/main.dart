import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:birlikteyapp/firebase_options.dart';
import 'package:birlikteyapp/models/expense.dart';
import 'package:birlikteyapp/models/item.dart';
import 'package:birlikteyapp/models/task.dart';
import 'package:birlikteyapp/models/user_template.dart';
import 'package:birlikteyapp/models/weekly_task.dart';
import 'package:birlikteyapp/pages/family/family_onboarding_page.dart';
import 'package:birlikteyapp/pages/home/home_page.dart';
import 'package:birlikteyapp/providers/expense_provider.dart';
import 'package:birlikteyapp/providers/family_provider.dart';
import 'package:birlikteyapp/providers/item_provider.dart';
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:birlikteyapp/providers/task_provider.dart';
import 'package:birlikteyapp/providers/templates_provider.dart';
import 'package:birlikteyapp/providers/ui_provider.dart';
import 'package:birlikteyapp/providers/weekly_provider.dart';
import 'package:birlikteyapp/services/auth_service.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:birlikteyapp/services/task_service.dart';
import 'package:birlikteyapp/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Emülatör (debug)
  if (kDebugMode) {
    FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  }

  // Firestore offline cache açık kalsın
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Ekran yönü
  final views = WidgetsBinding.instance.platformDispatcher.views;
  final shortestLogical = views.isNotEmpty
      ? views.first.physicalSize.shortestSide / views.first.devicePixelRatio
      : 600;
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

  runApp(const _Root());
}

class _Root extends StatefulWidget {
  const _Root({super.key});
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = _initApp();
  }

  @override
  Widget build(BuildContext context) {
    // Splash + tek runApp mimarisi
    return FutureBuilder<void>(
      future: _init,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Init bitti → gerçek uygulama
        final ui = UiProvider();
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => FamilyProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ItemProvider()),
            ChangeNotifierProvider(create: (_) => WeeklyProvider()),
            ChangeNotifierProvider(create: (_) => TemplatesProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
            ChangeNotifierProvider(create: (_) => ui..loadPrefs()),
            Provider<AuthService>(create: (_) => AuthService()),
            Provider<TaskService>(create: (_) => TaskService()),
            ChangeNotifierProxyProvider3<
              AuthService,
              TaskService,
              FamilyProvider,
              TaskCloudProvider
            >(
              create: (ctx) => TaskCloudProvider(
                ctx.read<AuthService>(),
                ctx.read<TaskService>(),
              ),
              update: (ctx, auth, service, family, prev) {
                final p = prev ?? TaskCloudProvider(auth, service);
                p.update(auth, service);
                p.setFamilyId(family.familyId);
                return p;
              },
            ),
          ],
          child: Consumer<UiProvider>(
            builder: (_, ui, __) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Togetherly',
              themeMode: ui.themeMode,
              theme: AppTheme.light(ui.brand),
              darkTheme: AppTheme.dark(ui.brand),
              home: const AuthGate(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initApp() async {
    // Bildirim servisi
    await NotificationService.init();

    // Hive
    await Hive.initFlutter();
    _safeRegister(TaskAdapter());
    _safeRegister(ItemAdapter());
    _safeRegister(WeeklyTaskAdapter());
    _safeRegister(UserTemplateAdapter());
    _safeRegister(WeeklyEntryAdapter());
    _safeRegister(ExpenseAdapter());

    // Gerekli kutular
    await Future.wait([
      Hive.openBox<String>('familyBox'),
      Hive.openBox<Task>('taskBox'),
      Hive.openBox<Item>('itemBox'),
      Hive.openBox<UserTemplate>('userTemplates'),
      Hive.openBox<Expense>('expenseBox'),
      Hive.openBox<int>('taskCountBox'),
      Hive.openBox<int>('itemCountBox'),
      Hive.openBox<WeeklyTask>('weeklyBox'),
      Hive.openBox<int>('weeklyNotifBox'),
    ]);

    // İlk seed (sadece boşsa)
    final taskBox = Hive.box<Task>('taskBox');
    if (taskBox.isEmpty) {
      for (final t in AppLists.defaultTasks) {
        taskBox.add(Task(t));
      }
    }
    final itemBox = Hive.box<Item>('itemBox');
    if (itemBox.isEmpty) {
      for (final i in AppLists.defaultItems) {
        itemBox.add(Item(i));
      }
    }
  }

  void _safeRegister<T>(TypeAdapter<T> a) {
    try {
      Hive.registerAdapter(a);
    } catch (_) {}
  }
}

/// === Auth akışı ===
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        // 1) Önce veriye bak
        final user = snap.data;
        if (user == null) {
          // Çıkış yapıldı → hemen Login
          return const LoginPage();
        }

        // 2) familyId local state'te varsa direkt Home
        final famProv = context.watch<FamilyProvider>();
        if (famProv.familyId != null) {
          return const HomePage();
        }

        // 3) users/{uid}.activeFamilyId dinle (ilk snapshot gelene kadar küçük loader)
        final usersRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        return StreamBuilder<String?>(
          stream: usersRef
              .snapshots()
              .map((s) => (s.data()?['activeFamilyId'] as String?)?.trim())
              .distinct(),
          builder: (_, idSnap) {
            if (idSnap.connectionState == ConnectionState.waiting &&
                !idSnap.hasData) {
              // Native splash varsa bu çok kısa görünecek
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final activeFam = idSnap.data;
            if (activeFam != null && activeFam.isNotEmpty) {
              famProv.adoptActiveFromCloud(activeFam);
              return const HomePage();
            }

            // aktif aile yok → onboarding
            return const FamilyOnboardingPage();
          },
        );
      },
    );
  }
}

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (_, authSnap) {
//         final user = authSnap.data;
//         if (user == null) return const LoginPage();
//
//         final famProv = context.watch<FamilyProvider>();
//         if (famProv.familyId != null) {
//           return const SplashScreen();
//         }
//
//         final usersRef = FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid);
//
//         return StreamBuilder<String?>(
//           stream: usersRef
//               .snapshots()
//               .map((s) => (s.data()?['activeFamilyId'] as String?)?.trim())
//               .distinct(),
//           builder: (_, idSnap) {
//             final activeFam = idSnap.data;
//             if (idSnap.connectionState == ConnectionState.waiting &&
//                 !idSnap.hasData) {
//               return const SplashScreen();
//             }
//             if ((activeFam != null && activeFam.isNotEmpty)) {
//               famProv.adoptActiveFromCloud(activeFam);
//               // ⬇️ yine SplashScreen
//               return const SplashScreen();
//             }
//             return const FamilyOnboardingPage();
//           },
//         );
//       },
//     );
//   }
// }
