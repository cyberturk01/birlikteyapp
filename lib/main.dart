import 'dart:ui';

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
import 'package:birlikteyapp/providers/location_cloud_provider.dart';
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:birlikteyapp/providers/templates_provider.dart';
import 'package:birlikteyapp/providers/ui_provider.dart';
import 'package:birlikteyapp/providers/weekly_cloud_provider.dart';
import 'package:birlikteyapp/services/auth_service.dart';
import 'package:birlikteyapp/services/firestore_scores_repo.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:birlikteyapp/services/offline_queue.dart';
import 'package:birlikteyapp/services/scores_repo.dart';
import 'package:birlikteyapp/services/task_service.dart';
import 'package:birlikteyapp/theme/app_theme.dart';
import 'package:birlikteyapp/utils/privacy_policy_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/login_page.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // async zone errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
            ChangeNotifierProvider(create: (_) => ui..init()),
            Provider<ScoresRepo>(
              create: (_) => FirestoreScoresRepo(FirebaseFirestore.instance),
            ),
            ChangeNotifierProvider(
              create: (_) => LocationCloudProvider(
                FirebaseAuth.instance,
                FirebaseFirestore.instance,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => LocationCloudProvider(
                FirebaseAuth.instance,
                FirebaseFirestore.instance,
              ),
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
            ChangeNotifierProxyProvider4<
              AuthService,
              TaskService,
              ScoresRepo,
              FamilyProvider,
              TaskCloudProvider
            >(
              create: (ctx) => TaskCloudProvider(
                ctx.read<AuthService>(),
                ctx.read<TaskService>(),
                ctx.read<ScoresRepo>(),
              ),
              update: (ctx, auth, taskService, scores, family, prev) {
                final p = prev ?? TaskCloudProvider(auth, taskService, scores);
                // senin provider'daki update(AuthService, TaskService, ScoresRepo)
                p.update(auth, taskService, scores);
                // familyId her değiştiğinde burada set edilecek
                p.setFamilyId(family.familyId);
                return p;
              },
            ),
          ],
          child: Consumer<UiProvider>(
            builder: (_, ui, __) => MaterialApp(
              locale: ui.locale,
              routes: {'/privacy': (_) => const PrivacyPolicyPage()},
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('tr'), // Türkçe
                Locale('de'), // Almanca
              ],
              navigatorKey: navigatorKey,
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
    await NotificationService.requestPermissions();

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
      Hive.openBox('oplog'),
    ]);
    await OfflineQueue.I.init();
    final auth = FirebaseAuth.instance;
    await OfflineQueue.I.setOwner(auth.currentUser?.uid);
    auth.authStateChanges().listen((u) {
      OfflineQueue.I.setOwner(u?.uid);
    });

    try {
      await OfflineQueue.I.flush();
      debugPrint('[OQ] initial flush done');
    } catch (_) {
      /* sessiz geç */
    }
    // İlk seed (sadece boşsa)
    final taskBox = Hive.box<Task>('taskBox');
    if (taskBox.isEmpty) {
      for (final t in AppLists.defaultTasks(context)) {
        await taskBox.add(Task(t));
      }
    }
    final itemBox = Hive.box<Item>('itemBox');
    if (itemBox.isEmpty) {
      for (final i in AppLists.defaultItems(context)) {
        await itemBox.add(Item(i));
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

            return const FamilyOnboardingPage();
          },
        );
      },
    );
  }
}
