import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:birlikteyapp/firebase_options.dart';
import 'package:birlikteyapp/models/expense.dart';
import 'package:birlikteyapp/models/item.dart';
import 'package:birlikteyapp/models/task.dart';
import 'package:birlikteyapp/models/user_template.dart';
import 'package:birlikteyapp/models/weekly_task.dart';
import 'package:birlikteyapp/pages/family/family_onboarding_page.dart';
import 'package:birlikteyapp/pages/landing/landing_page.dart';
import 'package:birlikteyapp/providers/expense_cloud_provider.dart';
import 'package:birlikteyapp/providers/family_provider.dart';
import 'package:birlikteyapp/providers/item_cloud_provider.dart';
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:birlikteyapp/providers/templates_provider.dart';
import 'package:birlikteyapp/providers/ui_provider.dart';
import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:birlikteyapp/services/auth_service.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:birlikteyapp/services/scores_repo.dart';
import 'package:birlikteyapp/services/task_service.dart';
import 'package:birlikteyapp/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Emülatör (debug)
  // if (kDebugMode) {
  //   FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  //   FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  // }

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Firestore offline cache açık kalsın
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Text(
          '💥 UI error:\n${details.exception}',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

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
  const _Root();
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
            ChangeNotifierProvider(create: (_) => TemplatesProvider()),
            ChangeNotifierProvider(create: (_) => ui..loadPrefs()),
            Provider<ScoresRepo>(
              create: (_) => ScoresRepo(FirebaseFirestore.instance),
            ),
            Provider<AuthService>(create: (_) => AuthService()),
            Provider<TaskService>(create: (_) => TaskService()),
            ChangeNotifierProvider(create: (_) => WeeklyCloudProvider()),
            ChangeNotifierProxyProvider<FamilyProvider, ExpenseCloudProvider>(
              create: (_) => ExpenseCloudProvider(
                FirebaseAuth.instance,
                FirebaseFirestore.instance,
              ),
              update: (_, family, exp) {
                final p =
                    exp ??
                    ExpenseCloudProvider(
                      FirebaseAuth.instance,
                      FirebaseFirestore.instance,
                    );
                p.setFamilyId(
                  family.familyId,
                ); // 🔑 olmazsa _col hep null kalır
                return p;
              },
            ),
            ChangeNotifierProxyProvider3<
              AuthService,
              TaskService,
              FamilyProvider,
              ItemCloudProvider
            >(
              create: (ctx) => ItemCloudProvider(
                ctx.read<AuthService>(),
                ctx.read<TaskService>(),
              ),
              update: (ctx, auth, service, family, previous) {
                final p = previous ?? ItemCloudProvider(auth, service);
                p.update(auth, service);
                p.setFamilyId(family.familyId);
                return p;
              },
            ),
            // TaskCloudProvider: ScoresRepo’yu da ver
            ChangeNotifierProxyProvider3<
              AuthService,
              TaskService,
              ScoresRepo,
              TaskCloudProvider
            >(
              create: (ctx) => TaskCloudProvider(
                ctx.read<AuthService>(),
                ctx.read<TaskService>(),
                ctx.read<ScoresRepo>(),
              ),
              update: (ctx, auth, taskService, scores, prev) {
                final p = prev ?? TaskCloudProvider(auth, taskService, scores);
                p.update(auth, taskService, scores);
                p.setFamilyId(ctx.read<FamilyProvider>().familyId);
                return p;
              },
            ),
          ],
          child: Consumer<UiProvider>(
            builder: (_, ui, __) => MaterialApp(
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('tr'), // Türkçe
                Locale('de'), // Almanca
              ],
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
      Hive.openBox('appBox'),
      Hive.openBox<int>('weeklyNotifCloudBox'),
      Hive.openBox<String>('familyBox'),
      Hive.openBox<Task>('taskBox'),
      Hive.openBox<Item>('itemBox'),
      Hive.openBox<UserTemplate>('userTemplates'),
      Hive.openBox<Expense>('expenseBox'),
      Hive.openBox<int>('taskCountBox'),
      Hive.openBox<int>('itemCountBox'),
      Hive.openBox<WeeklyTask>('weeklyBox'),
      Hive.openBox<int>('weeklyNotifBox'),
      Hive.openBox<String>('recentExpenseCats'),
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

/// === Auth akışı (birleştirilmiş) ===
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        // 1) Kullanıcı yok → Login
        final user = snap.data;
        if (user == null) {
          return const LoginPage();
        }

        // 2) familyId zaten localde varsa direkt Home
        final famProv = context.watch<FamilyProvider>();
        final localFam = famProv.familyId;
        if (localFam != null && localFam.isNotEmpty) {
          return const LandingPage();
        }

        // 3) Cloud'dan users/{uid}.activeFamilyId dinle
        final usersRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: usersRef.snapshots(),
          builder: (_, idSnap) {
            // İlk snapshot beklenirken küçük loader
            if (idSnap.connectionState == ConnectionState.waiting &&
                !idSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = idSnap.data?.data() ?? const <String, dynamic>{};
            final activeFam = (data['activeFamilyId'] as String?)?.trim();

            if (activeFam != null && activeFam.isNotEmpty) {
              // build içinde notifyListeners tetiklememek için post-frame
              if (famProv.familyId != activeFam) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // adoptActiveFromCloud senin provider'ında mevcut
                  famProv.adoptActiveFromCloud(activeFam);
                });
              }
              return const LandingPage();
            }

            // aktif aile yok → onboarding (aile kur / katıl)
            return const FamilyOnboardingPage();
          },
        );
      },
    );
  }
}

// /// === Auth akışı ===
// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (_, snap) {
//         // 1) Önce veriye bak
//         final user = snap.data;
//         if (user == null) {
//           // Çıkış yapıldı → hemen Login
//           return const LoginPage();
//         }
//
//         // 2) familyId local state'te varsa direkt Home
//         final famProv = context.watch<FamilyProvider>();
//         if (famProv.familyId != null) {
//           return const HomePage();
//         }
//
//         // 3) users/{uid}.activeFamilyId dinle (ilk snapshot gelene kadar küçük loader)
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
//             if (idSnap.connectionState == ConnectionState.waiting &&
//                 !idSnap.hasData) {
//               // Native splash varsa bu çok kısa görünecek
//               return const Scaffold(
//                 body: Center(child: CircularProgressIndicator()),
//               );
//             }
//
//             final activeFam = idSnap.data;
//             if (activeFam != null && activeFam.isNotEmpty) {
//               famProv.adoptActiveFromCloud(activeFam);
//               return const HomePage();
//             }
//
//             // aktif aile yok → onboarding
//             return const FamilyOnboardingPage();
//           },
//         );
//       },
//     );
//   }
// }
