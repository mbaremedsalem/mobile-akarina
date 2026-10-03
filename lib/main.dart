import 'dart:ui';
import 'package:akarina/business_logic/cubits/cubit/check_token_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/localization/localization.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/data/services/fcm_service.dart';
import 'package:akarina/data/services/navigation_service.dart';
import 'package:akarina/data/services/notification_store.dart';
import 'package:akarina/firebase_options.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/layout/layout.dart';
import 'package:akarina/presentations/screens/splash/splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:akarina/router.dart';
import 'package:flutter/material.dart';
import 'package:quiver/async.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Firebase peut déjà être initialisé nativement (via google-services.json)
  // avant même l'exécution de main(), donc on catch spécifiquement duplicate-app.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès !');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('ℹ️ Firebase déjà initialisé nativement');
    } else {
      print('❌ Erreur initialisation Firebase: $e');
    }
  }
  
  // ✅ Initialiser FCM seulement si Firebase est initialisé
  try {
    if (Firebase.apps.isNotEmpty) {
      await FCMService.initialize();
      print('✅ FCM initialisé avec succès !');
    }
  } catch (e) {
    print('❌ Erreur initialisation FCM: $e');
  }
  
  bool isFirstLaunch = await checkFirstLaunch();

  PlatformDispatcher.instance.onError = (error, stack) {
    print(error);
    print(stack);
    return true;
  };

  runApp(MyApp(
    appRouter: AppRouter(),
    isFirstLaunch: isFirstLaunch,
  ));
}

Future<bool> checkFirstLaunch() async {
  final storage = FlutterSecureStorage();
  String? firstLaunch = await storage.read(key: 'isFirstLaunch');

  if (firstLaunch == null) {
    await storage.write(
        key: 'isFirstLaunch',
        value: 'false');
    return true;
  }
  return false;
}

const String THEME_MODE_KEY = 'themeMode';

class MyApp extends StatefulWidget {
  final AppRouter? appRouter;
  final bool isFirstLaunch;
  const MyApp({super.key, this.appRouter, required this.isFirstLaunch});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  /// Change et persiste le mode clair/sombre de l'app.
  static void setThemeMode(BuildContext context, ThemeMode mode) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setThemeMode(mode);
  }

  static ThemeMode themeModeOf(BuildContext context) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    return state._themeMode;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  CountdownTimer? _countdownTimer;
  final GlobalKey<NavigatorState> navigatorKey = rootNavigatorKey;
  Locale _locale = Locale(ARABIC, 'CA');
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');
    String? refreshToken = await storage.read(key: 'refresh');
    String? timer = await storage.read(key: 'session_time');

    final isBackground = state == AppLifecycleState.paused;
    final isResumed = state == AppLifecycleState.resumed;

    if (isResumed) {
      // L'isolate d'arrière-plan FCM ne peut pas mettre à jour le badge
      // affiché dans l'app : on resynchronise au retour au premier plan.
      NotificationStore.refreshUnreadCount();
    }

    if (isBackground) {
      if (timer != null) {
        _countdownTimer = CountdownTimer(
            Duration(seconds: int.parse(timer)), Duration(seconds: 1));
      }
    } else if (isResumed) {
      if (_countdownTimer != null &&
          _countdownTimer!.remaining < Duration(seconds: 0)) {
        if (token != null) {
          Map body = {"refresh": refreshToken};
          try {
            await Repository(networkService: NetworkService()).logout(body);
            Services.logoutEndSession(navigatorKey);
          } catch (e) {
            Services.logoutEndSession(navigatorKey);
          }
        }
        _countdownTimer!.cancel();
      }
    }
  }

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    FlutterSecureStorage().write(key: THEME_MODE_KEY, value: mode.name);
  }

  Future<void> _loadThemeMode() async {
    final saved = await FlutterSecureStorage().read(key: THEME_MODE_KEY);
    if (!mounted || saved == null) return;
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.light,
      );
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestLocationPermission();
    _loadThemeMode();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CheckTokenCubit>(
          create: (context) => CheckTokenCubit(
              repository: Repository(networkService: NetworkService())),
        ),
        BlocProvider<LoginCubit>(
          create: (context) => LoginCubit(
              repository: Repository(networkService: NetworkService())),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: _locale.languageCode == 'ar' ? 'Cairo' : 'Poppins',
            useMaterial3: false,
            brightness: Brightness.light,
            scaffoldBackgroundColor: kWhiteColor,
            appBarTheme: AppBarTheme(color: kWhiteColor, elevation: 0.0)),
        darkTheme: ThemeData(
            fontFamily: _locale.languageCode == 'ar' ? 'Cairo' : 'Poppins',
            useMaterial3: false,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: kWhiteColor,
              elevation: 0.0,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: pcolor,
              brightness: Brightness.dark,
            )),
        themeMode: _themeMode,
        locale: _locale,
        supportedLocales: const [
          Locale("ar", "SA"),
          Locale("fr", "CA"),
          Locale("en", "US"),
        ],
        localizationsDelegates: const [
          Localization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale!.languageCode &&
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        onGenerateRoute: widget.appRouter!.generateRoute,
        // L'app s'ouvre toujours sur l'application complète (Layout) ; le
        // mode "Maisons de cérémonie" reste accessible à la demande depuis
        // la page de connexion ou Profil (voir applyAppMode), mais ne
        // change plus l'écran de démarrage.
        home: widget.isFirstLaunch ? const Splash() : const Layout(),
      ),
    );
  }
}