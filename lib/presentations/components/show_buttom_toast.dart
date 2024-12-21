import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

ToastFuture showBottomToaster({
  required BuildContext context,
  required String? msg,
  Color? backgroundColor,
}) {
  return showToast(msg ?? '',
      textPadding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(10),
          vertical: getProportionateScreenHeight(10)),
      context: context,
      position: StyledToastPosition.bottom,
      textStyle: maintextstyle.copyWith(
        color: kWhiteColor,
        fontWeight: FontWeight.w400,
        fontSize: getProportionateScreenWidth(16),
      ),
      backgroundColor: kBlackColor,
      textAlign: TextAlign.center,
      animation: StyledToastAnimation.slideFromBottomFade,
      reverseAnimation: StyledToastAnimation.slideFromRight,
      duration: Duration(seconds: 6),
      animDuration: Duration(milliseconds: 350),
      fullWidth: true,
      isHideKeyboard: false,
      toastHorizontalMargin: getProportionateScreenWidth(16));
}
