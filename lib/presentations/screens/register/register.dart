import 'dart:convert';

import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> with TickerProviderStateMixin {
  int fiftenyears = 5475;
  int _currentStep = 0;
  StepperType stepperType = StepperType.vertical;
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKekotp = GlobalKey<FormState>();
  String? prenom;
  String? nom;
  String? nni;
  String? newpassword;
  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  String? msg;
  String phone = '';
  final storage = FlutterSecureStorage();

  bool codeinvalid = false;

  bool nniValid = false;
  bool phoneValid = false;
  bool otpValid = false;
  bool passwordValid = false;

  String? validatepassword(String value) {
    String pattern =
        r'^(?!(.)\1{3})(?!0123|1234|2345|3456|4567|5678|6789|7890|0987|9876|8765|7654|6543|5432|4321|3210)\d{4}$';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return getTranslated(context, "pay2");
    } else if (!regExp.hasMatch(value)) {
      return getTranslated(context, 'mdp faible');
    }
    return null;
  }

   late CustomTimerController _controller ;

   @override
  void initState() {
   _controller= CustomTimerController( vsync:this , begin: Duration(
                                                        minutes: 5),
                                                    end: const Duration(),);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      SizeConfig().init(context);
    return   Scaffold(
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                // margin: EdgeInsets.symmetric(
                //     horizontal: getProportionateScreenWidth(20)),
                padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(20),
                    vertical: getProportionateScreenHeight(25)),
                decoration: const BoxDecoration(),
                //----------------- NNI ---------------------
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _currentStep == 0 && nniValid == false
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenWidth(4)),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kBlackColor),
                                    child: SvgPicture.asset(
                                      "assets/icons/profile_plus.svg",
                                      colorFilter: const ColorFilter.mode(
                                          kWhiteColor, BlendMode.srcIn),
                                      width: getProportionateScreenWidth(22),
                                    ),
                                  ),
                                  SizedBox(
                                    width: getProportionateScreenWidth(10),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(getTranslated(context, "ÉTAPE 1")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      10),
                                              fontWeight: FontWeight.w600,
                                              color: kgrey400)),
                                      Text(
                                          getTranslated(context,
                                              "Informations personnelles")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      14),
                                              fontWeight: FontWeight.w400,
                                              color: kBlackColor)),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(5),
                              ),
                              Form(
                                key: _formKey,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    spaceWidth(5),
                                    SizedBox(
                                      height: getProportionateScreenHeight(220),
                                      width: getProportionateScreenWidth(20),
                                      child: VerticalDivider(
                                        color: kgrey300,
                                        width: getProportionateScreenWidth(11),
                                        thickness: 2,
                                      ),
                                    ),
                                    spaceWidth(10),
                                    SizedBox(
                                      width: getProportionateScreenWidth(300),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.all(
                                                getProportionateScreenWidth(3)),
                                            decoration: BoxDecoration(
                                                border:
                                                    Border.all(color: kgrey300),
                                                borderRadius: BorderRadius.circular(
                                                    getProportionateScreenWidth(
                                                        12))),
                                            child: TextFormField(
                                              maxLength: 10,
                                              inputFormatters: <
                                                  TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(RegExp('[0-9]')),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration:
                                                  textformdecoration.copyWith(
                                                      prefixIcon: Padding(
                                                        padding: EdgeInsets.symmetric(
                                                            vertical:
                                                                getProportionateScreenHeight(
                                                                    10),
                                                            horizontal:
                                                                getProportionateScreenWidth(
                                                                    6)),
                                                        child: SvgPicture.asset(
                                                          "assets/icons/card_id.svg",
                                                          colorFilter:
                                                               ColorFilter.mode(
                                                                  kgrey800,
                                                                  BlendMode
                                                                      .srcIn),
                                                        ),
                                                      ),
                                                      labelText: getTranslated(
                                                          context,
                                                          "Numéro national d'identification")!),
                                              validator: (v) {
                                                if (v!.isEmpty) {
                                                  return getTranslated(
                                                      context, "nnicourt");
                                                } else {
                                                  if (v.length == 10) {
                                                    return null;
                                                  }
                                                  return getTranslated(
                                                      context, "nnicourt");
                                                }
                                              },
                                              onChanged: (v) {
                                                setState(() {
                                                  nni = v;
                                                });
                                              },
                                            ),
                                          ),
                                          spaceHeight(15),
                                          Container(
                                            padding: EdgeInsets.all(
                                                getProportionateScreenWidth(3)),
                                            decoration: BoxDecoration(
                                                border:
                                                    Border.all(color: kgrey300),
                                                borderRadius: BorderRadius.circular(
                                                    getProportionateScreenWidth(
                                                        12))),
                                            child: TextFormField(
                                              maxLength: 8,
                                              inputFormatters: <
                                                  TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(RegExp('[0-9]')),
                                              ],
                                              validator: (value) {
                                                String pattern = r'^[0-9]*$';
                                                RegExp regExp =
                                                    RegExp(pattern);

                                                if (value!.isEmpty) {
                                                  return getTranslated(context,
                                                      "telobligatoire");
                                                } else {
                                                  if (value.startsWith('2') ||
                                                      value.startsWith('3') ||
                                                      value.startsWith('4')) {
                                                    if (value.length == 8) {
                                                      if (regExp
                                                          .hasMatch(value)) {
                                                        return null;
                                                      } else {
                                                        return getTranslated(
                                                            context,
                                                            "telnonvalide");
                                                      }
                                                    } else {
                                                      return getTranslated(
                                                          context,
                                                          "telnonvalide");
                                                    }
                                                  } else {
                                                    return getTranslated(
                                                        context,
                                                        "telnonvalide");
                                                  }
                                                }
                                              },
                                              decoration:
                                                  textformdecoration.copyWith(
                                                      prefixIcon: Padding(
                                                        padding: EdgeInsets.symmetric(
                                                            vertical:
                                                                getProportionateScreenHeight(
                                                                    10),
                                                            horizontal:
                                                                getProportionateScreenWidth(
                                                                    6)),
                                                        child: SvgPicture.asset(
                                                          "assets/icons/phone.svg",
                                                          colorFilter:
                                                               ColorFilter.mode(
                                                                  kgrey800,
                                                                  BlendMode
                                                                      .srcIn),
                                                          height: 8,
                                                        ),
                                                      ),
                                                      labelText: getTranslated(
                                                          context,
                                                          "Numéro de Téléphone")!),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (v) {
                                                setState(() {
                                                  phone = v;
                                                });
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    10),
                                          ),
                                           loading
                                              ? spiner()
                                              : Defaultbutton(
                                                  height:
                                                      getProportionateScreenHeight(
                                                          50),
                                                  text: getTranslated(
                                                      context, "suivant"),
                                                  onTap: () async {
                                                    setState(() {
                                                      nniValid = true;
                                                      _currentStep += 1;
                                                    });
                                                    if (_formKey.currentState!
                                                        .validate()) {
                                                      // continued();
                                                    }
                                                  },
                                                  color: pcolor,
                                                  textcolor: kWhiteColor,
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                      backgroundColor: secondcolor,
                                      maxRadius:
                                          getProportionateScreenWidth(16),
                                      child: Icon(
                                        Icons.check,
                                        color: kWhiteColor,
                                        size: getProportionateScreenWidth(22),
                                      )),
                                  SizedBox(
                                    width: getProportionateScreenWidth(10),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(getTranslated(context, "ÉTAPE 1")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      10),
                                              fontWeight: FontWeight.w600,
                                              color: kgrey400)),
                                      Text(
                                          getTranslated(context,
                                              "Informations personnelles")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      14),
                                              fontWeight: FontWeight.w400,
                                              color: kBlackColor)),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.only(
                                    left: getProportionateScreenWidth(16),
                                    right: getProportionateScreenWidth(16),
                                    top: getProportionateScreenHeight(5)),
                                height: getProportionateScreenHeight(30),
                                width: getProportionateScreenWidth(20),
                                child: VerticalDivider(
                                  color: secondcolor,
                                  width: getProportionateScreenWidth(11),
                                  thickness: 2,
                                ),
                              ),
                            ],
                          ),
                    spaceHeight(5),
                    //-------------- Telephone ---------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _currentStep != 1 && phoneValid == false
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                            getProportionateScreenWidth(6)),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kgrey300, width: 1.2),
                                            shape: BoxShape.circle),
                                        child: Text('#',
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        20),
                                                fontWeight: FontWeight.w400,
                                                color: colorBorder)),
                                      ),
                                      SizedBox(
                                        width: getProportionateScreenWidth(10),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              getTranslated(
                                                  context, "ÉTAPE 2")!,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          10),
                                                  fontWeight: FontWeight.w600,
                                                  color: colorTextMuted)),
                                          Text(
                                              getTranslated(context,
                                                  "Confirmation numéro de téléphone")!,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          14),
                                                  fontWeight: FontWeight.w400,
                                                  color: colorTextMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(
                                        left: getProportionateScreenWidth(13),
                                        right: getProportionateScreenWidth(13),
                                        top: getProportionateScreenHeight(5)),
                                    height: getProportionateScreenHeight(20),
                                    width: getProportionateScreenWidth(20),
                                    child: VerticalDivider(
                                      color: colorBorder,
                                      width: getProportionateScreenWidth(11),
                                      thickness: 2,
                                    ),
                                  ),
                                ],
                              )
                            : _currentStep == 1 && phoneValid == false
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: kBlackColor,
                                            maxRadius:
                                                getProportionateScreenWidth(16),
                                            child: Text(
                                              '#',
                                              style: TextStyle(
                                                color: kWhiteColor,
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        18),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width:
                                                getProportionateScreenWidth(10),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  getTranslated(
                                                      context, "ÉTAPE 2")!,
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      fontSize:
                                                          getProportionateScreenWidth(
                                                              10),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colorTextMuted)),
                                              Text(
                                                  getTranslated(context,
                                                      "Confirmation numéro de téléphone")!,
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      fontSize:
                                                          getProportionateScreenWidth(
                                                              14),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: kBlackColor)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height:
                                            getProportionateScreenHeight(15),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getTranslated(context, "prenom")!,
                                            textScaleFactor: 1.0,
                                            style: const TextStyle(
                                                color: kBlackColor),
                                          ),
                                          Expanded(
                                            child: Text(
                                              prenom ?? "",
                                              textScaleFactor: 1.0,
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                  color: kBlackColor,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getTranslated(context, "nom")!,
                                            textScaleFactor: 1.0,
                                            style: const TextStyle(
                                                color: kBlackColor),
                                          ),
                                          Expanded(
                                            child: Text(
                                              nom ?? "",
                                              textScaleFactor: 1.0,
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                  color: kBlackColor,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                     
                                      SizedBox(
                                        height:
                                            getProportionateScreenHeight(18),
                                      ),
                                      Text(getTranslated(context, "tel")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                            color: kBlackColor,
                                            fontSize:
                                                getProportionateScreenWidth(16),
                                          )),
                                      SizedBox(
                                        height: getProportionateScreenHeight(8),
                                      ),
                                      Form(
                                        key: _formKey2,
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              maxLength: 8,
                                              inputFormatters: <
                                                  TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(RegExp('[0-9]')),
                                              ],
                                              validator: (value) {
                                                String pattern = r'^[0-9]*$';
                                                RegExp regExp =
                                                    RegExp(pattern);

                                                if (value!.isEmpty) {
                                                  return getTranslated(context,
                                                      "telobligatoire");
                                                } else {
                                                  if (value.startsWith('2') ||
                                                      value.startsWith('3') ||
                                                      value.startsWith('4')) {
                                                    if (value.length == 8) {
                                                      if (regExp
                                                          .hasMatch(value)) {
                                                        return null;
                                                      } else {
                                                        return getTranslated(
                                                            context,
                                                            "telnonvalide");
                                                      }
                                                    } else {
                                                      return getTranslated(
                                                          context,
                                                          "telnonvalide");
                                                    }
                                                  } else {
                                                    return getTranslated(
                                                        context,
                                                        "telnonvalide");
                                                  }
                                                }
                                              },
                                              decoration:
                                                  textformdecoration.copyWith(
                                                      errorStyle: TextStyle
                                                          (
                                                              fontSize:
                                                                  getProportionateScreenWidth(
                                                                      12),
                                                              color:
                                                                  pdarkcolor)),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (v) {
                                                setState(() {
                                                  phone = v;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            getProportionateScreenHeight(20),
                                      ),
                                      loading
                                          ? spiner()
                                          : Defaultbutton(
                                              height:
                                                  getProportionateScreenHeight(
                                                      50),
                                              text: getTranslated(
                                                  context, "suivant"),
                                              onTap: () async {
                                                if (_formKey2.currentState!
                                                    .validate()) {
                                                  // telValidate();
                                                }
                                              },
                                              color: pcolor,
                                              textcolor: kWhiteColor,
                                            ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                          backgroundColor: pcolor,
                                          maxRadius:
                                              getProportionateScreenWidth(10),
                                          child: Icon(
                                            Icons.check,
                                            color: kWhiteColor,
                                            size:
                                                getProportionateScreenWidth(15),
                                          )),
                                      SizedBox(
                                        width: getProportionateScreenWidth(10),
                                      ),
                                      Text(getTranslated(context, "tel")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      14),
                                              fontWeight: FontWeight.w700,
                                              color: pcolor)),
                                    ],
                                  ),
                      ],
                    ),

                    // -------------- Otp ----------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _currentStep != 2 && otpValid == false
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: getProportionateScreenWidth(20),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: pdarkcolor, width: 1.2)),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '3',
                                      style: maintextstyle.copyWith(
                                        color: pdarkcolor,
                                        fontSize:
                                            getProportionateScreenWidth(12),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: getProportionateScreenWidth(10),
                                  ),
                                  Text(getTranslated(context, "smsconfirme")!,
                                      textScaleFactor: 1.0,
                                      style: maintextstyle.copyWith(
                                          fontSize:
                                              getProportionateScreenWidth(14),
                                          fontWeight: FontWeight.w700,
                                          color: pdarkcolor)),
                                ],
                              )
                            : _currentStep == 2 && otpValid == false
                                ? Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: pdarkcolor,
                                              maxRadius:
                                                  getProportionateScreenWidth(
                                                      10),
                                              child: Text(
                                                '3',
                                                style: maintextstyle.copyWith(
                                                  color: kWhiteColor,
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          12),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      10),
                                            ),
                                            Text(
                                                getTranslated(
                                                    context, "smsconfirme")!,
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
                                                    fontSize:
                                                        getProportionateScreenWidth(
                                                            14),
                                                    fontWeight: FontWeight.w700,
                                                    color: pdarkcolor)),
                                          ],
                                        ),
                                        SizedBox(
                                          height:
                                              getProportionateScreenHeight(25),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                                height:
                                                    getProportionateScreenHeight(
                                                        60),
                                                width:
                                                    getProportionateScreenWidth(
                                                        140),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      getProportionateScreenWidth(
                                                          20),
                                                ),
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: kBlackColor,
                                                        width: 1.2),
                                                    color: plightcolor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            getProportionateScreenHeight(
                                                                10))),
                                                child: CustomTimer(
                                                    controller: _controller,
                                                  
                                                    builder: (t, time) {
                                                      return Text(
                                                          "${time.minutes}:${time.seconds}",
                                                          textScaleFactor: 1.0,
                                                          style: maintextstyle.copyWith(
                                                              fontSize:
                                                                  getProportionateScreenWidth(
                                                                      30),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color:
                                                                  pdarkcolor));
                                                    },
                                                    // stateBuilder:
                                                    //     (time, state) {
                                                    //   // If null is returned, "builder" is displayed.
                                                    //   return null;
                                                    // },
                                                    // animationBuilder: (child) {
                                                    //   return AnimatedSwitcher(
                                                    //     duration: const Duration(
                                                    //         milliseconds: 250),
                                                    //     child: child,
                                                    //   );
                                                    // },
                                                    // onChangeState: (state) {
                                                    //   if (state ==
                                                    //       CustomTimerState
                                                    //           .finished) {
                                                    //     setState(() {
                                                    //       codeinvalid = true;
                                                    //     });
                                                    //   }
                                                    //   if (state ==
                                                    //       CustomTimerState
                                                    //           .reset) {
                                                    //     _controller.start();
                                                    //   }
                                                    // }
                                                    )
                                                    ),
                                          ],
                                        ),
                                        SizedBox(
                                          height:
                                              getProportionateScreenHeight(15),
                                        ),
                                        codeinvalid
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: <Widget>[
                                                  Text(
                                                    getTranslated(context,
                                                        "le code n'est plus valide")!,
                                                    textScaleFactor: 1.0,
                                                    style:
                                                        maintextstyle.copyWith(
                                                            color: kredcolor),
                                                  ),
                                                  GestureDetector(
                                                      onTap: () async {
                                                        setState(() {
                                                          codeinvalid = false;
                                                        });
                                                        _controller.reset();
                                                        var u = Uri.parse(
                                                            "${NetworkService()
                                                                    .baseUrl}api/user/otp/verify/$phone/");

                                                        await http.get(u, headers: {
                                                          'Content-Type':
                                                              'application/json; charset=utf-8'
                                                        });
                                                        // print(respone.statusCode);
                                                      },
                                                      child: Text(
                                                        getTranslated(context,
                                                            "Ressayer")!,
                                                        textScaleFactor: 1.0,
                                                        style: maintextstyle
                                                            .copyWith(
                                                                color:
                                                                    pdarkcolor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    getProportionateScreenWidth(
                                                                        18)),
                                                      )),
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text("SMS code",
                                                        textScaleFactor: 1.0,
                                                        style: maintextstyle
                                                            .copyWith(
                                                          color: kBlackColor,
                                                          fontSize:
                                                              getProportionateScreenWidth(
                                                                  14),
                                                        )),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        getProportionateScreenHeight(
                                                            5),
                                                  ),
                                                  Form(
                                                    key: _formKekotp,
                                                    child: Column(
                                                      children: [
                                                        TextFormField(
                                                          maxLength: 6,
                                                          inputFormatters: <
                                                              TextInputFormatter>[
                                                            FilteringTextInputFormatter
                                                                .allow(RegExp(
                                                                    '[0-9]')),
                                                          ],
                                                          validator: (v) {
                                                            if (v!.isEmpty) {
                                                              return getTranslated(
                                                                  context,
                                                                  "pay2");
                                                            } else {
                                                              if (v.length ==
                                                                  6) {
                                                                return null;
                                                              }
                                                              return "";
                                                            }
                                                          },
                                                          decoration: textformdecoration.copyWith(
                                                              errorStyle: maintextstyle.copyWith(
                                                                  fontSize:
                                                                      getProportionateScreenWidth(
                                                                          12),
                                                                  color:
                                                                      kredcolor)),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          onChanged: (v) {
                                                            setState(() {
                                                              msg = v;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        getProportionateScreenHeight(
                                                            10),
                                                  ),
                                                  loading
                                                      ? spiner()
                                                      : Defaultbutton(
                                                          height:
                                                              getProportionateScreenHeight(
                                                                  50),
                                                          text: getTranslated(
                                                              context,
                                                              "suivant"),
                                                          onTap: () async {
                                                            if (_formKekotp
                                                                .currentState!
                                                                .validate()) {
                                                              otpValidate();
                                                            }
                                                          },
                                                          color: pdarkcolor,
                                                          textcolor:
                                                              kWhiteColor,
                                                        ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                          backgroundColor: pcolor,
                                          maxRadius:
                                              getProportionateScreenWidth(10),
                                          child: Icon(
                                            Icons.check,
                                            color: kWhiteColor,
                                            size:
                                                getProportionateScreenWidth(15),
                                          )),
                                      SizedBox(
                                        width: getProportionateScreenWidth(10),
                                      ),
                                      Text(
                                          getTranslated(
                                              context, "smsconfirme")!,
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      14),
                                              fontWeight: FontWeight.w700,
                                              color: pcolor)),
                                    ],
                                  ),
                      ],
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(30),
                    ),

                    //-------------- Code ---------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _currentStep != 3 && passwordValid == false
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenWidth(6)),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: kgrey300, width: 1.2),
                                        shape: BoxShape.circle),
                                    child: Text('#',
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                getProportionateScreenWidth(20),
                                            fontWeight: FontWeight.w400,
                                            color: colorBorder)),
                                  ),
                                  SizedBox(
                                    width: getProportionateScreenWidth(10),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(getTranslated(context, "ÉTAPE 3")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      10),
                                              fontWeight: FontWeight.w600,
                                              color: colorTextMuted)),
                                      Text(
                                          getTranslated(context,
                                              "Création mot de passe")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      14),
                                              fontWeight: FontWeight.w400,
                                              color: colorTextMuted)),
                                    ],
                                  ),
                                ],
                              )
                            : _currentStep == 3 && passwordValid == false
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: plightcolor,
                                            maxRadius:
                                                getProportionateScreenWidth(10),
                                            child: Text(
                                              '4',
                                              style: TextStyle(
                                                color: kWhiteColor,
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        12),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width:
                                                getProportionateScreenWidth(10),
                                          ),
                                          Text(getTranslated(context, "code")!,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          14),
                                                  fontWeight: FontWeight.w700,
                                                  color: plightcolor)),
                                        ],
                                      ),
                                      SizedBox(
                                        height:
                                            getProportionateScreenHeight(25),
                                      ),
                                      Form(
                                        key: _formKey3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                  getTranslated(
                                                      context, 'codeerror')!,
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      color: kBlackColor,
                                                      fontSize:
                                                          getProportionateScreenWidth(
                                                              14),
                                                      fontWeight:
                                                          FontWeight.w400)),
                                            ),
                                            SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      20),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      getProportionateScreenWidth(
                                                          30)),
                                              child: Directionality(
                                                textDirection:
                                                    TextDirection.ltr,
                                                child: PinCodeTextField(
                                                  enablePinAutofill: false,
                                                  cursorHeight:
                                                      getProportionateScreenWidth(
                                                          24),
                                                  appContext: context,
                                                  pastedTextStyle: const TextStyle(
                                                    color: kGreyColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  length: 4,
                                                  animationType:
                                                      AnimationType.fade,
                                                  validator: (v) =>
                                                      validatepassword(v!),
                                                  pinTheme: PinTheme(
                                                    borderWidth: 1,
                                                    selectedColor: kGreyColor
                                                        .withOpacity(0.2),
                                                    selectedFillColor:
                                                        kGreyColor
                                                            .withOpacity(0.2),
                                                    inactiveFillColor:
                                                        kGreyColor
                                                            .withOpacity(0.2),
                                                    inactiveColor: kGreyColor
                                                        .withOpacity(0.2),
                                                    shape:
                                                        PinCodeFieldShape.box,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            getProportionateScreenWidth(
                                                                10)),
                                                    fieldHeight:
                                                        getProportionateScreenHeight(
                                                            65),
                                                    fieldWidth:
                                                        getProportionateScreenWidth(
                                                            48),
                                                    activeFillColor: kGreyColor
                                                        .withOpacity(0.2),
                                                    activeColor: kGreyColor
                                                        .withOpacity(0.2),
                                                  ),
                                                  obscuringWidget: Icon(
                                                    Icons.circle,
                                                    color: kBlackColor,
                                                    size:
                                                        getProportionateScreenWidth(
                                                            25),
                                                  ),
                                                  cursorColor: kBlackColor,
                                                  enableActiveFill: true,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      newpassword = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      16),
                                            ),
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                  getTranslated(
                                                      context, 'confirme')!,
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      color: kBlackColor,
                                                      fontSize:
                                                          getProportionateScreenWidth(
                                                              14),
                                                      fontWeight:
                                                          FontWeight.w400)),
                                            ),
                                            SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      20),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      getProportionateScreenWidth(
                                                          30)),
                                              child: Directionality(
                                                textDirection:
                                                    TextDirection.ltr,
                                                child: PinCodeTextField(
                                                  enablePinAutofill: false,
                                                  cursorHeight:
                                                      getProportionateScreenWidth(
                                                          24),
                                                  appContext: context,
                                                  pastedTextStyle: const TextStyle(
                                                    color: kGreyColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  length: 4,
                                                  animationType:
                                                      AnimationType.fade,
                                                  pinTheme: PinTheme(
                                                    borderWidth: 1,
                                                    selectedColor: kGreyColor
                                                        .withOpacity(0.2),
                                                    selectedFillColor:
                                                        kGreyColor
                                                            .withOpacity(0.2),
                                                    inactiveFillColor:
                                                        kGreyColor
                                                            .withOpacity(0.2),
                                                    inactiveColor: kGreyColor
                                                        .withOpacity(0.2),
                                                    shape:
                                                        PinCodeFieldShape.box,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            getProportionateScreenWidth(
                                                                10)),
                                                    fieldHeight:
                                                        getProportionateScreenHeight(
                                                            65),
                                                    fieldWidth:
                                                        getProportionateScreenWidth(
                                                            48),
                                                    activeFillColor: kGreyColor
                                                        .withOpacity(0.2),
                                                    activeColor: kGreyColor
                                                        .withOpacity(0.2),
                                                  ),
                                                  obscuringWidget: Icon(
                                                    Icons.circle,
                                                    color: kBlackColor,
                                                    size:
                                                        getProportionateScreenWidth(
                                                            25),
                                                  ),
                                                  cursorColor: kBlackColor,
                                                  enableActiveFill: true,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  validator: (v) =>
                                                      v != newpassword
                                                          ? getTranslated(
                                                              context,
                                                              "identiquemot")
                                                          : null,
                                                  onChanged: (value) {},
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            getProportionateScreenHeight(10),
                                      ),
                                      loading
                                          ? spiner()
                                          : Defaultbutton(
                                              height:
                                                  getProportionateScreenHeight(
                                                      50),
                                              text: getTranslated(
                                                  context, "confirmer"),
                                              onTap: () async {
                                                if (_formKey3.currentState!
                                                    .validate()) {
                                                  // continued();
                                                }
                                              },
                                              color: pcolor,
                                              textcolor: kWhiteColor,
                                            ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                          backgroundColor: pcolor,
                                          maxRadius:
                                              getProportionateScreenWidth(10),
                                          child: Icon(
                                            Icons.check,
                                            color: kWhiteColor,
                                            size:
                                                getProportionateScreenWidth(15),
                                          )),
                                      SizedBox(
                                        width: getProportionateScreenWidth(10),
                                      ),
                                      Text(getTranslated(context, "code")!,
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      14),
                                              fontWeight: FontWeight.w700,
                                              color: pcolor)),
                                    ],
                                  ),
                      ],
                    ),

                    //-----------------------------------
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void otpValidate() async {
    if (_currentStep == 2) {
      if (_formKekotp.currentState!.validate()) {
        setState(() {
          loading = true;
        });
        _controller.pause();
        try {
          var u = Uri.parse(
              "${NetworkService().baseUrl}api/user/otp/verify/$phone/");

          var respone = await http.post(u,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                'otp': msg,
              }));
          // print(respone.statusCode);
          if (respone.statusCode == 200) {
            setState(() {
              loading = false;
              _currentStep += 1;
              otpValid = true;
            });
          } else {
            setState(() {
              loading = false;
            });
            _controller.start();

            showToast(
              getTranslated(context, "Code OTP invalid"),
              textPadding: EdgeInsets.only(
                  right: getProportionateScreenWidth(4),
                  left: getProportionateScreenWidth(4)),
              context: context,
              position: StyledToastPosition.top,
              textStyle: maintextstyle.copyWith(
                fontSize: getProportionateScreenWidth(16),
              ),
              backgroundColor: Colors.red,
              animation: StyledToastAnimation.slideFromRight,
              reverseAnimation: StyledToastAnimation.slideFromRight,
              duration: Duration(seconds: 7),
              animDuration: Duration(milliseconds: 350),
              fullWidth: false,
              isHideKeyboard: false,
            );
          }
        } catch (e) {
          setState(() {
            loading = false;
          });
          _controller.start();

          showToast(
            getTranslated(context, "Code OTP invalid"),
            textPadding: EdgeInsets.only(
                right: getProportionateScreenWidth(4),
                left: getProportionateScreenWidth(4)),
            context: context,
            position: StyledToastPosition.top,
            textStyle: maintextstyle.copyWith(
              fontSize: getProportionateScreenWidth(16),
            ),
            backgroundColor: Colors.red,
            animation: StyledToastAnimation.slideFromRight,
            reverseAnimation: StyledToastAnimation.slideFromRight,
            duration: Duration(seconds: 7),
            animDuration: Duration(milliseconds: 350),
            fullWidth: false,
            isHideKeyboard: false,
          );
        }
      }
    }
  }



}