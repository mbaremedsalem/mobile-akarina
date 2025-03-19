import 'package:akarina/data/models/langage.dart';
import 'package:akarina/main.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../../data/localization/language_constants.dart';

class LangueSelect extends StatefulWidget {
  final String? country;
  const LangueSelect({this.country, super.key});

  @override
  State<LangueSelect> createState() => _LangueSelectState();
}

class _LangueSelectState extends State<LangueSelect> {
  void _changeLanguage(Language language) async {
    Locale _locale = await setLocale(language.languageCode);
    MyApp.setLocale(context, _locale);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            spaceHeight(40),
            Text(
              getTranslated(context, "lang")!,
              textScaleFactor: 1.0,
              style: TextStyle(
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
                    _changeLanguage(
                      Language(2, "🇸🇦", "اَلْعَرَبِيَّةُ‎", "ar"),
                    );
                  },
                  child: Container(
                    height: getProportionateScreenWidth(110),
                    width: getProportionateScreenWidth(113),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color:
                            Localizations.localeOf(context).languageCode == "ar"
                                ? pcolor
                                : colorBorderElement,
                      ),
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(12)),
                      color:
                          Localizations.localeOf(context).languageCode == "ar"
                              ? secondcolor
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
                              getTranslated(context, "ar")!,
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: getProportionateScreenWidth(14),
                                  color: kBlackColor),
                            ),
                          ],
                        ),
                        Positioned(
                            top: 8,
                            right: 8,
                            child:
                                Localizations.localeOf(context).languageCode ==
                                        "ar"
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
                GestureDetector(
                  onTap: () {
                    _changeLanguage(
                      Language(1, "fr", "Francais", "fr"),
                    );
                  },
                  child: Container(
                    height: getProportionateScreenWidth(110),
                    width: getProportionateScreenWidth(113),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color:
                            Localizations.localeOf(context).languageCode == "fr"
                                ? pcolor
                                : colorBorderElement,
                      ),
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(12)),
                      color:
                          Localizations.localeOf(context).languageCode == "fr"
                              ? secondcolor
                              : kWhiteColor,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/french.png',
                              width: getProportionateScreenWidth(40),
                            ),
                            Text(
                              getTranslated(context, "fr")!,
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: getProportionateScreenWidth(14),
                                  color: kBlackColor),
                            ),
                          ],
                        ),
                        Positioned(
                            top: 8,
                            right: 8,
                            child:
                                Localizations.localeOf(context).languageCode ==
                                        "fr"
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
                GestureDetector(
                  onTap: () {
                    _changeLanguage(
                      Language(3, "en", "English", "en"),
                    );
                  },
                  child: Container(
                    height: getProportionateScreenWidth(110),
                    width: getProportionateScreenWidth(113),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color:
                            Localizations.localeOf(context).languageCode == "en"
                                ? pcolor
                                : colorBorderElement,
                      ),
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(12)),
                      color:
                          Localizations.localeOf(context).languageCode == "en"
                              ? secondcolor
                              : kWhiteColor,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/english.png',
                              width: getProportionateScreenWidth(40),
                            ),
                            Text(
                              getTranslated(context, "en")!,
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: getProportionateScreenWidth(14),
                                  color: kBlackColor),
                            ),
                          ],
                        ),
                        Positioned(
                            top: 8,
                            right: 8,
                            child:
                                Localizations.localeOf(context).languageCode ==
                                        "en"
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
              ],
            ),
            SizedBox(
              height: getProportionateScreenHeight(60),
            ),
            Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(20)),
              child: Defaultbutton(
                onTap: () {
                  Navigator.pop(context);
                },
                color: pcolor,
                textcolor: kWhiteColor,
                text: getTranslated(context, "confirmer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
