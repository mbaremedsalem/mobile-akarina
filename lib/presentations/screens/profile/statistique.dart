import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/profile.dart';
import 'package:akarina/presentations/components/divider.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';


class Statistique extends StatelessWidget {
  const Statistique({Key? key, this.data}) : super(key: key);

  final Profil? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(getProportionateScreenWidth(25)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "paimentfait")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: data!.payements.toString(),
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${getTranslated(context, "Mru")}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          defaultdivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "rembou")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: data!.remboursements.toString(),
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${getTranslated(context, "Mru")}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          defaultdivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "transferrecu")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: data!.envoiesRecus.toString(),
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${"  ${getTranslated(context, "Mru")}"}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          defaultdivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "transferenvoyer")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: data!.envoiesFaits.toString(),
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${getTranslated(context, "Mru")}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          defaultdivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "rech")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: data!.recharges.toString(),
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${getTranslated(context, "Mru")}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          defaultdivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "retraits")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: data!.retraits.toString(),
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${getTranslated(context, "Mru")}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          defaultdivider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated(context, "frais")!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(color: kBlackColor),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                      text: "0",
                      style: maintextstyle.copyWith(
                          color: pcolor,
                          fontSize: getProportionateScreenWidth(18),
                          fontWeight: FontWeight.w700),
                      children: <InlineSpan>[
                        TextSpan(
                          style: maintextstyle.copyWith(
                              color: kmru,
                              fontSize: getProportionateScreenWidth(14)),
                          text: "  ${getTranslated(context, "Mru")}",
                        )
                      ]),
                  textScaleFactor: 1.0,
                ),
              )
            ],
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       getTranslated(context, "Retraits par Sms"),
          //       style: maintextstyle.copyWith(
          //
          //           fontWeight: FontWeight.w700,
          //           color: Colors.black),
          //     ),
          //     Text(
          //       "${data.retraitsParSms.toString()} ${"  ${getTranslated(context, "Mru")}"}",
          //       style: maintextstyle.copyWith(
          //
          //           fontWeight: FontWeight.w700,
          //           color: Colors.orange),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
