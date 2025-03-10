import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../../size_config.dart';

class Nonetwork extends StatelessWidget {
  const Nonetwork({Key? key, this.onpress}) : super(key: key);

  final Function? onpress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/wifi_off.svg',
          height: getProportionateScreenHeight(100),
          // color: primarycolor,
        ),
        SizedBox(
          width: getProportionateScreenHeight(10),
        ),
        Padding(
          padding: EdgeInsets.only(top: getProportionateScreenHeight(0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getTranslated(context, "Pas")!,
                style: maintextstyle.copyWith(
                    color: kBlackColor, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onpress as void Function()?,
                padding: EdgeInsets.all(0),
                icon: Icon(
                  Icons.refresh,
                  color: Colors.red,
                ),
              ),
              // Defaultbutton(
              //   width: getProportionateScreenWidth(120),
              //   onTap: onpress as void Function()?,
              //   color: klightgoldColor,
              //   height: getProportionateScreenHeight(32),
              //   text: getTranslated(context, 'Ressayer'),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
