import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:akarina/presentations/screens/register/register.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../../../data/localization/language_constants.dart';

class IndexLogin extends StatefulWidget {
  const IndexLogin({super.key});

  @override
  State<IndexLogin> createState() => _IndexLoginState();
}

class _IndexLoginState extends State<IndexLogin> {
  int currentState = 0;

  String? pays;

  final FlutterSecureStorage storage = FlutterSecureStorage();

  void fetch() async {
    String? t = await storage.read(key: "country");

    if (mounted) {
      setState(() {
        pays = t;
      });
    }
  }

  @override
  void initState() {
    fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: pcolor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // spaceHeight(80),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(16)),
                child: SizedBox(
                  width: SizeConfig.screenWidth / 1.2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      spaceHeight(10),
                      Image.asset(
                        'assets/images/icon.png',
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                        width: getProportionateScreenWidth(100),
                      ),
                    
                      // spaceHeight(10),
                      currentState == 0
                          ? Text(
                            getTranslated(context, "Bienvenue, connectez-vous à votre compte")!,
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize: getProportionateScreenWidth(20),
                                  color: kWhiteColor,
                                  fontWeight: FontWeight.w400))
                          : Text(getTranslated(context, "nscrivez-vous et profitez d'une expérience Apprentissage.")!,
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize: getProportionateScreenWidth(20),
                                  color: kWhiteColor,
                                  fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(getProportionateScreenWidth(20)),
                      topRight:
                          Radius.circular(getProportionateScreenWidth(20)),
                    ),
                    color: kWhiteColor),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      spaceHeight(20),
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(15)),
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: kgrey200,
                            ),
                            borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(20)),
                            color: kgrey100),
                        padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(2),
                            vertical: getProportionateScreenHeight(2)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  currentState = 0;
                                });
                              },
                              child: Container(
                                height: getProportionateScreenHeight(41),
                                width: getProportionateScreenWidth(168),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(20)),
                                  color: currentState == 0
                                      ? kWhiteColor
                                      : kgrey100,
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentState == 0
                                          ? kgrey300
                                          : kgrey100,
                                      offset: const Offset(
                                        0.0,
                                        0.0,
                                      ),
                                      blurRadius: 10.0,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(getTranslated(context, 'cnx')!,
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize:
                                              getProportionateScreenWidth(14),
                                          color: kBlackColor,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                String? t = await storage.read(key: "country");

                                if (mounted) {
                                  setState(() {
                                    pays = t;
                                    currentState = 1;
                                  });
                                }
                              },
                              child: Container(
                                height: getProportionateScreenHeight(41),
                                width: getProportionateScreenWidth(168),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(20)),
                                  color: currentState == 1
                                      ? kWhiteColor
                                      : kgrey100,
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentState == 1
                                          ? kgrey300
                                          : kgrey100,
                                      offset: const Offset(
                                        0.0,
                                        0.0,
                                      ),
                                      blurRadius: 10.0,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(getTranslated(context, 'créer un compte')!,
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize:
                                              getProportionateScreenWidth(14),
                                          color: kBlackColor,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                          height: SizeConfig.screenHeight / 1.5,
                          child: currentState == 0
                              ? const Login()
                              : pays == 'Mauritania'
                                  ? const Register()
                                  : const Register())
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
