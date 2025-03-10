import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';


class CountrySelect extends StatefulWidget {
  final String? country;
  const CountrySelect({this.country, super.key});

  @override
  State<CountrySelect> createState() => _CountrySelectState();
}

class _CountrySelectState extends State<CountrySelect> {
  String? pays = 'Mauritania';
  FlutterSecureStorage storage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    setState(() {
      pays = widget.country;
    });
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
              getTranslated(context, "Choisissez le pays")!,
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
                              'assets/images/mauritanie.png',
                              width: getProportionateScreenWidth(40),
                            ),
                            Text(
                              getTranslated(context, "Mauritania")!,
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pays = 'Senegal';
                    });
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
                      color:
                          pays == 'Senegal' ? secondcolor : kWhiteColor,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/senegal.png',
                              width: getProportionateScreenWidth(40),
                            ),
                            Text(
                              getTranslated(context, "Senegal")!,
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
              ],
            ),
            spaceHeight(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pays = 'Mali';
                    });
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
                      color: pays == 'Mali' ? secondcolor : kWhiteColor,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/mali.png',
                              width: getProportionateScreenWidth(40),
                            ),
                            Text(
                              getTranslated(context, "Mali")!,
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: getProportionateScreenWidth(14),
                                  color: kBlackColor
                                  ),
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pays = 'Guinee';
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
                      color:
                          pays == 'Guinee' ? secondcolor : kWhiteColor,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/guinee.png',
                              width: getProportionateScreenWidth(40),
                            ),
                            Text(
                              getTranslated(context, "Guinee")!,
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
                    // borderColor: kgrey300,
                    onTap: () {
                      Navigator.pop(context, '');
                    },
                    text: getTranslated(context, 'Retour'),
                    width: getProportionateScreenWidth(110),
                  ),
                  spaceWidth(5),
                  Defaultbutton(
                    onTap: () async {
                      await storage.write(key: "country", value: pays);
                      Navigator.pop(context, pays);
                    },
                    width: getProportionateScreenWidth(240),
                    color: pcolor,
                    textcolor: kWhiteColor,
                    text: getTranslated(context, "Confirmer"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
