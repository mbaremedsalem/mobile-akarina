import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import '../../size_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

Widget spiner({double? size}) {
  return SpinKitFadingCircle(
    color: pcolor,
    size: getProportionateScreenWidth(size ?? 30),
  );
}
