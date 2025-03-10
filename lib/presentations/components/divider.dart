import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';


Widget defaultdivider({double? height, Color? color, double? thickness}) {
  return Divider(
    height: height ?? getProportionateScreenHeight(6),
    thickness: thickness ?? getProportionateScreenWidth(1),
    color: color ?? Color.fromARGB(58, 111, 109, 109),
  );
}
