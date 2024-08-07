import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';

const pcolor = Color(0xFF5538D9);
const plightcolor = Color(0xFF9680FF);
const pdarkcolor = Color(0xFF3819B5);

const secondcolor = Color(0xFFCABDFF);
const secondlightcolor = Color(0xFFF1EDFF);
const kmaincolor = Color(0xFF162A4B);

final splashDark = Color(0xFF1B144D);
final splashDark80 = Color.fromARGB(232, 32, 23, 103);
final splashDark90 = Color.fromARGB(232, 30, 22, 90);
const splashDarker = Color(0xFF1B147C);
const splashLessDark = Color(0xFF362999);
const buttonBackground = Color(0xFF4A4BA2);

const kBlackColor = Color(0xFF171717);
const kredcolor = Color(0xFFDC2626);
const secondgreencolor = Color(0xFF30A46C);
const kgreencolor = Color(0xFF3D9A50);
const korange = Color.fromARGB(255, 231, 131, 23);
const kmru = Color(0xFF747D60);
final kgrey50 = Colors.grey.shade50;
const klightgrey = Color(0xFFF5F5F5);
final kgrey100 = Colors.grey.shade100;
final kgrey200 = Colors.grey.shade200;
final kgrey300 = Colors.grey.shade300;
final kgrey400 = Colors.grey.shade400;
final kgrey500 = Colors.grey.shade500;
final kgrey600 = Colors.grey.shade600;
const kgrey700 = Color(0xFF525252);
final kgrey800 = Color(0xFF3F3B3C);
final kgrey900 = Colors.grey.shade900;

const colorBorder = Color(0xFFD4D4D4);
const colorBorderSubt = Color(0xFFDDDDE3);
const colorBorderElement = Color(0xFFD3D4DB);
const colorBorderSuccess = Color(0xFF92CEAC);
const colorBackground = Color(0xFFF5F5F5);
const colorBorderError = Color(0xFFF3AEAF);

const colorTextMuted = Color(0xFFA3A3A3);
const colorTextSubt = Color(0xFF525252);
const colorTextLow = Color(0xFF60646C);
const colorTextHigh = Color(0xFF1C2024);
const colorTextPrimary = Color(0xFF472DC8);
const colorTextSuccess = Color(0xFF318794E);
const colorTextError = Color(0xFFC62A2F);
const colorTextOnContainerSuccess = Color(0xFF193B2D);
const colorsTextPrimaryContrast = Color(0xFF26196C);

const colorSurfaceContainerSuccess = Color(0xFFE9F9EE);
const colorSurfaceElement = Color(0xFFF2F2F5);
const colorSurfaceDefault = Color(0xFFFCFCFD);
const colorSurfaceDisabled = Color(0xFFE4E4E9);

final colorOrange = Colors.orange;

const klightmaincolor = Color.fromRGBO(18, 52, 123, 0.1);
Color kvert = Colors.green.shade50;
// Color kred = Colors.red.shade50;
const kWhiteColor = Color(0xFFFFFFFF);
const kmattelcolor = Color(0xFF0066b3);
const kmauritlcolor = Color(0xFFF36E20);
const kchingutelcolor = Color(0xFF0283C0);

const kGreyColor = Color(0xff8A959E);

final maintextstyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: getProportionateScreenWidth(14),
    fontWeight: FontWeight.w500,
    color: kBlackColor);

final buttonheight = getProportionateScreenWidth(45);
final buttonshape = RoundedRectangleBorder(
    borderRadius: new BorderRadius.circular(getProportionateScreenWidth(10)));

final textformdecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(
      horizontal: getProportionateScreenWidth(20),
      vertical: getProportionateScreenHeight(5)),
  counterText: '',
  labelStyle: maintextstyle.copyWith(
      color: colorTextLow,
      fontSize: getProportionateScreenWidth(14),
      fontWeight: FontWeight.w400),
  errorMaxLines: 4,
  hintStyle: maintextstyle.copyWith(
      color: kBlackColor,
      fontWeight: FontWeight.w400,
      fontSize: getProportionateScreenWidth(13)),
  errorStyle: maintextstyle.copyWith(
      color: kredcolor,
      fontWeight: FontWeight.w400,
      fontSize: getProportionateScreenWidth(12)),
  border: InputBorder.none,
  // focusedBorder: OutlineInputBorder(
  //   borderSide: BorderSide(color: Colors.grey.shade500),
  //   borderRadius:
  //       BorderRadius.all(Radius.circular(getProportionateScreenWidth(12))),
  // ),
  // errorBorder: OutlineInputBorder(
  //   borderSide: BorderSide(color: kredcolor),
  //   borderRadius:
  //       BorderRadius.all(Radius.circular(getProportionateScreenWidth(12))),
  // ),
  // focusedErrorBorder: OutlineInputBorder(
  //   borderSide: BorderSide(color: kredcolor),
  //   borderRadius:
  //       BorderRadius.all(Radius.circular(getProportionateScreenWidth(12))),
  // ),
  // enabledBorder: OutlineInputBorder(
  //   borderSide: BorderSide(color: Colors.grey.shade300),
  //   borderRadius:
  //       BorderRadius.all(Radius.circular(getProportionateScreenWidth(12))),
  // ),

  fillColor: kWhiteColor,
  filled: true,
);

Widget back(BuildContext context) {
  return Positioned(
    right: 2.0,
    child: GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(5)),
          child: Icon(Icons.close,
              size: getProportionateScreenWidth(30), color: kBlackColor),
        ),
      ),
    ),
  );
}

Widget spaceHeight(double height) {
  return SizedBox(height: getProportionateScreenHeight(height));
}

Widget spaceWidth(double width) {
  return SizedBox(width: getProportionateScreenWidth(width));
}
