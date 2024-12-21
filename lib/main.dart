import 'package:akarina/business_logic/cubits/cubit/check_token_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/localization/localization.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/firebase_options.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/api/firebase_api.dart';
import 'package:akarina/presentations/screens/on_boarding/shoose.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
  await FirebaseApi().initNotifications();
  runApp(MyApp(
    appRouter: AppRouter(),
  ));
}

class MyApp extends StatefulWidget {
  final AppRouter? appRouter;
  MyApp({this.appRouter});
  
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  CountdownTimer? _countdownTimer;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Locale _locale = Locale(ARABIC, 'CA');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');
    String? refreshToken = await storage.read(key: 'refresh');
    String? timer = await storage.read(key: 'session_time');

    final isBackground = state == AppLifecycleState.paused;
    final isResumed = state == AppLifecycleState.resumed;

    if (isBackground) {
      _countdownTimer = CountdownTimer(
          Duration(seconds: int.parse(timer!)), Duration(seconds: 1));
    } else if (isResumed) {
      if (_countdownTimer != null && _countdownTimer!.remaining < Duration(seconds: 0)) {
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

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        this._locale = locale;
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
    _requestLocationPermission();  // Demande de la permission ici
  }
    Future<void> _requestLocationPermission() async {
    // Demande d'autorisation de localisation
    var status = await Permission.location.status;
    if (!status.isGranted) {
      // Si la permission n'est pas accordée, on la demande
      await Permission.location.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CheckTokenCubit>(
          create: (context) => CheckTokenCubit(repository: Repository(networkService: NetworkService())),
        ),
        BlocProvider<LoginCubit>(
          create: (context) => LoginCubit(repository: Repository(networkService: NetworkService())),
        ),
        // Add other cubits here as needed
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'arial',
          primaryColor: kmaincolor,
          canvasColor: kWhiteColor,
        ),
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
        home: const Choose(),
        
      ),
    );
  }
}
