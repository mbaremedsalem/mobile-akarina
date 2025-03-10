import 'dart:async';

import 'package:akarina/presentations/screens/on_boarding/onboarding.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../on_boarding/shoose.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
    @override
  void initState() {
    super.initState();
    // Démarrer le timer pour rediriger après 3 secondes
    Timer(const Duration(seconds: 3), () {
      // Naviguer vers l'écran d'onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Choose()
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return   SafeArea(
      child: Scaffold(
        body: Container(
          height: SizeConfig.screenHeight,
          width: SizeConfig.screenWidth,
          child: SvgPicture.asset(
                    'assets/svg/logo.svg',
                     
                  ),
        ),
      ),
    );
  }
}