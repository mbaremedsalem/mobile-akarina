import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Profileskeleton extends StatefulWidget {
  Profileskeleton({this.heidht});

  final double? heidht;
  @override
  _ProfileskeletonState createState() => _ProfileskeletonState();
}

class _ProfileskeletonState extends State<Profileskeleton> {
  BoxDecoration decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(getProportionateScreenWidth(10)),
      color: Colors.grey[300]);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 1,
        itemBuilder: (BuildContext ctx, index) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[200]!,
              child: box(),
            ),
          );
        });
  }

  Widget box() {
    return Padding(
      padding: EdgeInsets.only(
          left: getProportionateScreenWidth(23),
          right: getProportionateScreenWidth(23)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: getProportionateScreenWidth(28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                      decoration: decoration,
                      width: getProportionateScreenWidth(120),
                      height: getProportionateScreenHeight(15)),
                  SizedBox(
                    height: getProportionateScreenHeight(10),
                  ),
                  Container(
                      decoration: decoration,
                      width: getProportionateScreenWidth(70),
                      height: getProportionateScreenHeight(20))
                ],
              )
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(38)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(38))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(35),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
          SizedBox(
            height: getProportionateScreenHeight(30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(130),
                  height: getProportionateScreenHeight(15)),
              Container(
                  decoration: decoration,
                  width: getProportionateScreenWidth(80),
                  height: getProportionateScreenHeight(15))
            ],
          ),
        ],
      ),
    );
  }
}
