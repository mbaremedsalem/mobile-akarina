import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';


class Defaultbutton extends StatelessWidget {
  const Defaultbutton({
    this.color,
    this.height,
    this.width,
    this.onTap,
    this.textcolor,
    this.text,
    this.suffixIcon,
    this.hasborder,
    this.borderColor,
    this.hasIcon,
    Key? key,
  }) : super(key: key);

  final void Function()? onTap;

  final double? height;
  final double? width;
  final Color? color;
  final String? text;
  final Color? textcolor;
  final Widget? suffixIcon;
  final bool? hasborder;
  final Color? borderColor;
  final bool? hasIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(10)),
          width: width,
          height: height ?? getProportionateScreenHeight(30),
          decoration: BoxDecoration(
            color: color,
            border: (hasborder ?? false)
                ? Border.all(color: borderColor ?? colorBorder)
                : null,
            borderRadius: BorderRadius.all(
                Radius.circular(getProportionateScreenWidth(5))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              (hasIcon ?? false) ? spaceWidth(25) : Container(),
              Text(
                text!,
                textScaleFactor: 1.0,
                style: maintextstyle.copyWith(
                    color: textcolor ?? kBlackColor,
                    fontWeight: FontWeight.w600,
                    fontSize: getProportionateScreenWidth(14)),
                textAlign: TextAlign.center,
              ),
              (hasIcon ?? false) ? suffixIcon ?? Container() : Container(),
            ],
          )),
    );
  }
}


Widget defaultTextField({
  required TextEditingController controller,
  bool isPassword = false,
  bool isClickable = true,
  required TextInputType type,
  Function? onSubmit,
  Function? onTap,
  required String text,
  required IconData prefix,
  IconData? suffix,
  Function? suffixFunction,
  String textForUnValid = 'this element is required',
  Color? backgroundColor,
  //required Function validate,
}) =>
    Container(
      height: 80,
      decoration: const BoxDecoration(),
      child: TextFormField(
        enableSuggestions: true,
        autocorrect: true,
        controller: controller,
        enabled: isClickable,
        onTap: () {
          onTap!();
        },
        validator: (value) {
          if (value!.isEmpty) {
            return textForUnValid;
          }
          return null;
        },
        onChanged: (value) {},
        onFieldSubmitted: (value) {
          onSubmit!(value);
        },
        obscureText: isPassword ? true : false,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: text,
          prefixIcon: Icon(prefix),
          suffixIcon: IconButton(
            onPressed: () {
              suffixFunction!();
            },
            icon: Icon(suffix),
          ),
          filled: true,
              fillColor: backgroundColor,

          border: const OutlineInputBorder(
            // InputBorder.none,
              borderRadius: BorderRadius.all(Radius.circular(7)),
              borderSide: BorderSide.none,
              gapPadding: 4),

        ),
            
      ),
    );
