import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/langage.dart';
import 'package:akarina/main.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/show_buttom_toast.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/layout/layout.dart';
import 'package:akarina/presentations/screens/on_boarding/onboarding.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:mobiledigital/data/localization/language_constants.dart';
// import 'package:mobiledigital/data/models/language.dart';
// import 'package:mobiledigital/main.dart';
// import 'package:mobiledigital/presentation/components/default_buttom.dart';
// import 'package:mobiledigital/presentation/components/show_button_toaster.dart';
// import 'package:mobiledigital/presentation/constants/constants.dart';
// import 'package:mobiledigital/size_config.dart';

class Choose extends StatefulWidget {
  const Choose({super.key});

  @override
  State<Choose> createState() => _ChooseState();
}

class _ChooseState extends State<Choose> {
  void _changeLanguage(Language language) async {
    Locale _locale = await setLocale(language.languageCode);
    MyApp.setLocale(context, _locale);
  }

  int index = 0;
  String? pays = '';
  FlutterSecureStorage storage = FlutterSecureStorage();
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return index == 0
        ? Theme(
          data: ThemeData(fontFamily: 'Changa'), // Appliquer Changa ici,
          child: Scaffold(
            body: Container(
                width: SizeConfig.screenWidth,
                // height: getProportionateScreenHeight(490),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        spaceHeight(40),
                        Text(
                          getTranslated(context, "Choisissez la langue")!,
                          textScaleFactor: 1.0,
                          style: maintextstyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: getProportionateScreenWidth(20),
                              color: kBlackColor),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadiusDirectional.circular(
                                  getProportionateScreenWidth(20)),
                              color: kWhiteColor),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Column(
                              children: [
                                spaceHeight(40),
                                GestureDetector(
                                  onTap: () {
                                    _changeLanguage(
                                      Language(2, "🇸🇦", "اَلْعَرَبِيَّةُ‎", "ar"),
                                    );
                                  },
                                  child: Container(
                                    height: getProportionateScreenWidth(56),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(16),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(16),
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: Localizations.localeOf(context)
                                                    .languageCode ==
                                                "ar"
                                            ? 2
                                            : 1,
                                        color: Localizations.localeOf(context)
                                                    .languageCode ==
                                                "ar"
                                            ? secondcolor
                                            : colorBorderElement,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(12)),
                                      color: Localizations.localeOf(context)
                                                  .languageCode ==
                                              "ar"
                                          ? secondlightcolor.withOpacity(0.6)
                                          : kWhiteColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, "ar")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  getProportionateScreenWidth(14),
                                              color: kBlackColor),
                                        ),
                                        Localizations.localeOf(context)
                                                    .languageCode ==
                                                "ar"
                                            ? SvgPicture.asset(
                                                'assets/icons/CheckCircle.svg',
                                                colorFilter: const ColorFilter.mode(
                                                    pcolor, BlendMode.srcIn),
                                              )
                                            : SvgPicture.asset(
                                                'assets/icons/Circle.svg',
                                                // colorFilter: ColorFilter.mode(
                                                //     pcolor, BlendMode.srcIn),
                                              )
                                      ],
                                    ),
                                  ),
                                ),
                                spaceHeight(8),
                                GestureDetector(
                                  onTap: () {
                                    _changeLanguage(
                                      Language(1, "fr", "Francais", "fr"),
                                    );
                                  },
                                  child: Container(
                                    height: getProportionateScreenWidth(56),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(16),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(16),
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: Localizations.localeOf(context)
                                                    .languageCode ==
                                                "fr"
                                            ? 2
                                            : 1,
                                        color: Localizations.localeOf(context)
                                                    .languageCode ==
                                                "fr"
                                            ? secondcolor
                                            : colorBorderElement,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(12)),
                                      color: Localizations.localeOf(context)
                                                  .languageCode ==
                                              "fr"
                                          ? secondlightcolor.withOpacity(0.6)
                                          : kWhiteColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, "fr")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  getProportionateScreenWidth(14),
                                              color: kBlackColor),
                                        ),
                                        Localizations.localeOf(context)
                                                    .languageCode ==
                                                "fr"
                                            ? SvgPicture.asset(
                                                'assets/icons/CheckCircle.svg',
                                                colorFilter: const ColorFilter.mode(
                                                    pcolor, BlendMode.srcIn),
                                              )
                                            : SvgPicture.asset(
                                                'assets/icons/Circle.svg',
                                                // colorFilter: ColorFilter.mode(
                                                //     pcolor, BlendMode.srcIn),
                                              )
                                      ],
                                    ),
                                  ),
                                ),
                                spaceHeight(8),
                                GestureDetector(
                                  onTap: () {
                                    _changeLanguage(
                                      Language(3, "en", "English", "en"),
                                    );
                                  },
                                  child: Container(
                                    height: getProportionateScreenWidth(56),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(16),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(16),
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: Localizations.localeOf(context)
                                                    .languageCode ==
                                                "en"
                                            ? 2
                                            : 1,
                                        color: Localizations.localeOf(context)
                                                    .languageCode ==
                                                "en"
                                            ? secondcolor
                                            : colorBorderElement,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(12)),
                                      color: Localizations.localeOf(context)
                                                  .languageCode ==
                                              "en"
                                          ? secondlightcolor.withOpacity(0.6)
                                          : kWhiteColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, "en")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  getProportionateScreenWidth(14),
                                              color: kBlackColor),
                                        ),
                                        Localizations.localeOf(context)
                                                    .languageCode ==
                                                "en"
                                            ? SvgPicture.asset(
                                                'assets/icons/CheckCircle.svg',
                                                colorFilter: const ColorFilter.mode(
                                                    pcolor, BlendMode.srcIn),
                                              )
                                            : SvgPicture.asset(
                                                'assets/icons/Circle.svg',
                                                // colorFilter: ColorFilter.mode(
                                                //     pcolor, BlendMode.srcIn),
                                              )
                                      ],
                                    ),
                                  ),
                                ),
                                spaceHeight(8),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                          child: Defaultbutton(
                            onTap: () {
                              setState(() {
                                index = 1;
                              });
                            },
                            color: pcolor,
                            textcolor: kWhiteColor,
                            text: getTranslated(context, "suivant"),
                            hasIcon: true,
                            borderRadius: getProportionateScreenWidth(5),
                              width: getProportionateScreenWidth(500),
                              height: getProportionateScreenHeight(40),
                            suffixIcon: Icon(
                              Icons.arrow_forward,
                              color: kWhiteColor,
                              size: getProportionateScreenWidth(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        )
        : Scaffold(
          body: Container(
              width: SizeConfig.screenWidth,
              // height: getProportionateScreenHeight(490),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      spaceHeight(40),
                      Text(
                        getTranslated(context, "Choisissez le pays")!,
                        textScaleFactor: 1.0,
                        style: maintextstyle.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: getProportionateScreenWidth(20),
                            color: kBlackColor),
                      ),
                      spaceHeight(40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                pays = 'Mauritania';
                              });
                            },
                            child: Container(
                              height: getProportionateScreenWidth(85),
                              width: getProportionateScreenWidth(174),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1.5,
                                  color: pays == 'Mauritania' ? pcolor : kgrey300,
                                ),
                                borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(12)),
                                color: pays == 'Mauritania'
                                    ? secondlightcolor
                                    : kWhiteColor,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/mauritanie.png',
                                        width: getProportionateScreenWidth(40),
                                      ),
                                      Text(
                                        getTranslated(context, "Mauritanie")!,
                                        textScaleFactor: 1.0,
                                        style: maintextstyle.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize:
                                                getProportionateScreenWidth(14),
                                            color: kBlackColor),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                      top: 8,
                                      right: 8,
                                      child: pays == 'Mauritania'
                                          ? SvgPicture.asset(
                                              'assets/icons/CheckCircle.svg',
                                              colorFilter: const ColorFilter.mode(
                                                  pcolor, BlendMode.srcIn),
                                            )
                                          : Container())
                                ],
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 0.3,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  // pays = 'Guinee';
                                });
                              },
                              child: Container(
                                height: getProportionateScreenWidth(85),
                                width: getProportionateScreenWidth(174),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1.5,
                                    color: pays == 'Guinee' ? pcolor : kgrey300,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                  color: pays == 'Guinee'
                                      ? secondlightcolor
                                      : kWhiteColor,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/maroc.png',
                                          width: getProportionateScreenWidth(40),
                                        ),
                                        Text(
                                          getTranslated(context, "Maroc")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  getProportionateScreenWidth(14),
                                              color: kBlackColor),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                        top: 8,
                                        right: 8,
                                        child: pays == 'Guinee'
                                            ? SvgPicture.asset(
                                                'assets/icons/CheckCircle.svg',
                                                colorFilter: const ColorFilter.mode(
                                                    pcolor, BlendMode.srcIn),
                                              )
                                            : Container())
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      spaceHeight(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Opacity(
                            opacity: 0.3,
                            child: GestureDetector(
                              onTap: () {
                                // setState(() {
                                //   pays = 'Senegal';
                                // });
                              },
                              child: Container(
                                height: getProportionateScreenWidth(85),
                                width: getProportionateScreenWidth(174),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1.5,
                                    color: pays == 'Senegal' ? pcolor : kgrey300,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                  color: pays == 'Senegal'
                                      ? secondlightcolor
                                      : kWhiteColor,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/arabe.png',
                                          width: getProportionateScreenWidth(40),
                                        ),
                                        Text(
                                          getTranslated(context, "Saoudia")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  getProportionateScreenWidth(14),
                                              color: kBlackColor),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                        top: 8,
                                        right: 8,
                                        child: pays == 'Senegal'
                                            ? SvgPicture.asset(
                                                'assets/icons/CheckCircle.svg',
                                                colorFilter: const ColorFilter.mode(
                                                    pcolor, BlendMode.srcIn),
                                              )
                                            : Container())
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 0.3,
                            child: GestureDetector(
                              onTap: () {
                                // setState(() {
                                //   pays = 'Mali';
                                // });
                              },
                              child: Container(
                                height: getProportionateScreenWidth(85),
                                width: getProportionateScreenWidth(174),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1.5,
                                    color: pays == 'Mali' ? pcolor : kgrey300,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12)),
                                  color: pays == 'Mali'
                                      ? secondlightcolor
                                      : kWhiteColor,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/algerie.png',
                                          width: getProportionateScreenWidth(40),
                                        ),
                                        Text(
                                          getTranslated(context, "Algerie")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  getProportionateScreenWidth(14),
                                              color: kBlackColor),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                        top: 8,
                                        right: 8,
                                        child: pays == 'Mali'
                                            ? SvgPicture.asset(
                                                'assets/icons/CheckCircle.svg',
                                                colorFilter: const ColorFilter.mode(
                                                    pcolor, BlendMode.srcIn),
                                              )
                                            : Container())
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Defaultbutton(
                              color: kWhiteColor,
                              textcolor: kBlackColor,
                              hasborder: true,
                              borderColor: kgrey300,
                              onTap: () {
                                setState(() {
                                  index = 0;
                                });
                              },
                              text: getTranslated(context, 'Retourner'),
                              width: getProportionateScreenWidth(110),
                              height: getProportionateScreenHeight(40),
                            ),
                            spaceWidth(5),
                            Defaultbutton(
                              onTap: () async {
                                await storage.write(key: "country", value: pays);
                                pays!.length > 0
                                    ? Navigator.push(context, MaterialPageRoute(builder: (context) => const Layout()))
                                    : showBottomToaster(
                                        context: context,
                                        msg: getTranslated(
                                            context, "Choisissez le pays")!,
                                      );
                              },
                              width: getProportionateScreenWidth(240),
                              height: getProportionateScreenHeight(40),
                              color: pcolor,
                              textcolor: kWhiteColor,
                              text: getTranslated(context, "suivant"),
                              hasIcon: true,
                              suffixIcon: Icon(
                                Icons.arrow_forward,
                                color: kWhiteColor,
                                size: getProportionateScreenWidth(24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(
                        height: getProportionateScreenHeight(20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        );
  }
}
