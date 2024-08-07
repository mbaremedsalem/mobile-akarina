
import 'package:akarina/business_logic/cubits/cubit/check_token_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/check_token_state.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/localization/localization.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/on_boarding/onboarding.dart';
import 'package:akarina/presentations/screens/splash/splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:akarina/router.dart';
import 'package:flutter/material.dart';
import 'package:quiver/async.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
  // This widget is the root of your application.
  CountdownTimer? _countdownTimer;
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

    @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');
    String? refreshToken = await storage.read(key: 'refresh');
    String? timer = await storage.read(key: 'session_time');
    // print(timer);
    final isBackground = state == AppLifecycleState.paused;
    final isresumed = state == AppLifecycleState.resumed;
    if (isBackground) {
      _countdownTimer = CountdownTimer(
          Duration(seconds: int.parse(timer!)), Duration(seconds: 1));
    } else if (isresumed) {
      if (_countdownTimer != null) {
        if (_countdownTimer!.remaining < Duration(seconds: 0)) {
          if (token != null) {
            Map body = {"refresh": refreshToken};
            try {
              await Repository(networkService: NetworkService()).logout(body);
              Services.logoutEndSession(navigatorKey);
            } catch (e) {
              Services.logoutEndSession(navigatorKey);
            }
          }
        }
        _countdownTimer!.cancel();
      }
    }
  }

  Locale _locale = Locale(ARABIC, 'CA');
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

  fetchsession() async {
    FlutterSecureStorage storage = FlutterSecureStorage();

    try {
      Repository repository = Repository(networkService: NetworkService());
      final response = await repository.fetchsession();
      // print(response);
      await storage.write(key: "session_time", value: response["value"]);
    } catch (e) {
      await storage.write(key: "session_time", value: "60");
    }
  }

    
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      // title: 'Flutter Demo',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: kmaincolor,
          canvasColor: kWhiteColor,
        ),
        locale: _locale,
        supportedLocales: const[
           Locale("ar", "SA"),
           Locale("fr", "CA"),
           Locale("en", "US"),
        ],
        localizationsDelegates: const[
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
        // home: BlocListener<CheckTokenCubit, CheckTokenState>(
        //     listener: (context, state) {
        //       if (state is NotFirstRun) {
        //         Navigator.pushNamedAndRemoveUntil(
        //             context, "indexLogin", (route) => false);
        //       }
        //       // if (state is FirstRun) {
        //       //   Navigator.pushNamedAndRemoveUntil(
        //       //       context, "indexLogin", (route) => false);
        //       // }
        //       if (state is FirstRun) {
        //         Navigator.push(context,
        //             MaterialPageRoute(builder: (context) => Onboarding()));
        //       }
        //     },
        //     child: const Onboarding()),
        
        home: const Onboarding(),
    );
  }
}

