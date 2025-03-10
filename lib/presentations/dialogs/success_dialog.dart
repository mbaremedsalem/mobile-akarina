import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Succesdialog extends StatelessWidget {
  const Succesdialog({Key? key, this.msag}) : super(key: key);

  final String? msag;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(getProportionateScreenWidth(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(getProportionateScreenWidth(10)),
                color: kWhiteColor),
            padding: EdgeInsets.fromLTRB(
              getProportionateScreenWidth(20),
              getProportionateScreenHeight(20),
              getProportionateScreenWidth(20),
              getProportionateScreenHeight(20),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/succes.svg',
                      width: getProportionateScreenWidth(80),
                      // color: pcolor,
                    )
                  ],
                ),
                SizedBox(
                  height: getProportionateScreenHeight(6),
                ),
                Text(
                  msag!,
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.0,
                  style: maintextstyle.copyWith(
                      color: kBlackColor,
                      fontSize: getProportionateScreenWidth(18),
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: getProportionateScreenHeight(30),
                ),
                Defaultbutton(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  height: getProportionateScreenHeight(40),
                  color: klightgrey,
                  textcolor: kBlackColor,
                  text: getTranslated(context, "Retourner"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
