// ignore_for_file: file_names
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter/material.dart';

ToastFuture showToaster(BuildContext context, String? msg, Color? color) {
  return showToast(
    msg ?? '',
    textPadding: EdgeInsets.symmetric(
      horizontal: getProportionateScreenWidth(10),
      vertical: getProportionateScreenHeight(5),
    ),
    context: context,
    position: StyledToastPosition.top,
    textStyle: textstyle.copyWith(
        fontSize: getProportionateScreenWidth(16),
        color: kWhiteColor,
        fontWeight: FontWeight.w500),
    backgroundColor: color ?? Colors.red,
    animation: StyledToastAnimation.slideFromRight,
    alignment: Alignment.center,
    reverseAnimation: StyledToastAnimation.slideFromRight,
    duration: const Duration(seconds: 7),
    animDuration: const Duration(milliseconds: 350),
    fullWidth: false,
    isHideKeyboard: false,
  );
}
