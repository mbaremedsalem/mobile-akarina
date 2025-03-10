import 'dart:convert';
import 'dart:io';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/register/components/term.dart';
import 'package:akarina/size_config.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class RegisterAutres extends StatefulWidget {
  RegisterAutres({Key? key}) : super(key: key);

  @override
  _RegisterAutresState createState() => _RegisterAutresState();
}

class _RegisterAutresState extends State<RegisterAutres> {
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
  String phone = '';
  String? password;
  String? newpassword;
  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  String? msg;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  bool codeinvalid = false;

  bool nniValid = false;
  bool phoneValid = false;
  bool otpValid = false;
  bool passwordValid = false;

  late File photoVisage = File('');
  bool isPhotoVisage = false;
  late File photoIdentite = File('');
  bool isPhotoIdentite = false;

  String? validatepassword(String value) {
    String pattern =
        r'^(?!(.)\1{3})(?!0123|1234|2345|3456|4567|5678|6789|7890|0987|9876|8765|7654|6543|5432|4321|3210)\d{4}$';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      return getTranslated(context, "pay2");
    } else if (!regExp.hasMatch(value)) {
      return getTranslated(context, 'mdp faible');
    }
    return null;
  }

  final CustomTimerController _controller = CustomTimerController();
  final int _duration = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                                      getProportionateScreenWidth(6)),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kBlackColor),
                                  child: SvgPicture.asset(
                                    "assets/icons/card_id.svg",
                                    colorFilter: const ColorFilter.mode(
                                        kWhiteColor, BlendMode.srcIn),
                                    width: getProportionateScreenWidth(18),
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
                                        style: maintextstyle.copyWith(
                                            fontSize:
                                                getProportionateScreenWidth(
                                                    10),
                                            fontWeight: FontWeight.w600,
                                            color: kgrey400)),
                                    Text(
                                        getTranslated(context,
                                            "Informations d'identification")!,
                                        textScaleFactor: 1.0,
                                        style: maintextstyle.copyWith(
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
                                    height: getProportionateScreenHeight(240),
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
                                        spaceHeight(8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                var pickedFile =
                                                    await openCamera();
      
                                                if (pickedFile
                                                    .path.isNotEmpty) {
                                                  setState(() {
                                                    photoVisage =
                                                        File(pickedFile.path);
                                                    isPhotoVisage = true;
                                                  });
                                                  print(photoVisage.path);
                                                }
                                              },
                                              child: DottedBorder(
                                                  color: isPhotoVisage
                                                      ? kgreencolor
                                                      : colorBorder,
                                                  radius: Radius.circular(
                                                      getProportionateScreenWidth(
                                                          16)),
                                                  padding:
                                                      const EdgeInsets.all(0.5),
                                                  borderType:
                                                      BorderType.RRect,
                                                  strokeWidth:
                                                      isPhotoVisage ? 2 : 1,
                                                  dashPattern: isPhotoVisage
                                                      ? [8, 0]
                                                      : [8, 6],
                                                  child: Stack(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.symmetric(
                                                            horizontal:
                                                                getProportionateScreenWidth(
                                                                    12),
                                                            vertical:
                                                                getProportionateScreenHeight(
                                                                    12)),
                                                        width:
                                                            getProportionateScreenWidth(
                                                                145),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      getProportionateScreenWidth(
                                                                          16)),
                                                          color: isPhotoVisage
                                                              ? kgreencolor
                                                                  .withOpacity(
                                                                      0.05)
                                                              : colorBackground,
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            SvgPicture.asset(
                                                                'assets/icons/UserFocus.svg'),
                                                            spaceHeight(4),
                                                            Text(
                                                                getTranslated(
                                                                    context,
                                                                    "Ajoutez une photo de votre visage")!,
                                                                textScaleFactor:
                                                                    1.0,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: maintextstyle.copyWith(
                                                                    fontSize:
                                                                        getProportionateScreenWidth(
                                                                            11),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        kBlackColor)),
                                                          ],
                                                        ),
                                                      ),
                                                      isPhotoVisage
                                                          ? Positioned(
                                                              top: 5,
                                                              right: 5,
                                                              child:
                                                                  SvgPicture
                                                                      .asset(
                                                                'assets/icons/CheckCircle.svg',
                                                                colorFilter: const ColorFilter.mode(
                                                                    kgreencolor,
                                                                    BlendMode
                                                                        .srcIn),
                                                              ),
                                                            )
                                                          : Container()
                                                    ],
                                                  )),
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                var pickedFile =
                                                    await openCamera();
      
                                                if (pickedFile
                                                    .path.isNotEmpty) {
                                                  setState(() {
                                                    photoIdentite =
                                                        File(pickedFile.path);
                                                    isPhotoIdentite = true;
                                                  });
                                                  print(photoIdentite.path);
                                                }
                                              },
                                              child: DottedBorder(
                                                  color: isPhotoIdentite
                                                      ? kgreencolor
                                                      : colorBorder,
                                                  radius: Radius.circular(
                                                      getProportionateScreenWidth(
                                                          16)),
                                                  padding:
                                                      EdgeInsets.all(0.5),
                                                  borderType:
                                                      BorderType.RRect,
                                                  strokeWidth:
                                                      isPhotoIdentite ? 2 : 1,
                                                  dashPattern: isPhotoIdentite
                                                      ? [8, 0]
                                                      : [8, 6],
                                                  child: Stack(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.symmetric(
                                                            horizontal:
                                                                getProportionateScreenWidth(
                                                                    12),
                                                            vertical:
                                                                getProportionateScreenHeight(
                                                                    12)),
                                                        width:
                                                            getProportionateScreenWidth(
                                                                145),
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        getProportionateScreenWidth(
                                                                            16)),
                                                            color: isPhotoIdentite
                                                                ? kgreencolor
                                                                    .withOpacity(
                                                                        0.05)
                                                                : colorBackground),
                                                        child: Column(
                                                          children: [
                                                            SvgPicture.asset(
                                                                'assets/icons/Camera.svg'),
                                                            spaceHeight(4),
                                                            Text(
                                                                getTranslated(
                                                                    context,
                                                                    "Photo de votre pièce d'identité")!,
                                                                textScaleFactor:
                                                                    1.0,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: maintextstyle.copyWith(
                                                                    fontSize:
                                                                        getProportionateScreenWidth(
                                                                            11),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        kBlackColor)),
                                                          ],
                                                        ),
                                                      ),
                                                      isPhotoIdentite
                                                          ? Positioned(
                                                              top: 5,
                                                              right: 5,
                                                              child:
                                                                  SvgPicture
                                                                      .asset(
                                                                'assets/icons/CheckCircle.svg',
                                                                colorFilter: const ColorFilter.mode(
                                                                    kgreencolor,
                                                                    BlendMode
                                                                        .srcIn),
                                                              ),
                                                            )
                                                          : Container()
                                                    ],
                                                  )),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height:
                                              getProportionateScreenHeight(
                                                  10),
                                        ),
                                        (isPhotoIdentite || isPhotoVisage)
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      getTranslated(context,
                                                          "Vous pouvez cliquer sur la carte pour changer l'image.")!,
                                                      textScaleFactor: 1.0,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: maintextstyle.copyWith(
                                                          fontSize:
                                                              getProportionateScreenWidth(
                                                                  10),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              colorTextSubt)),
                                                  spaceHeight(10)
                                                ],
                                              )
                                            : Container(),
                                        loading
                                            ? spiner()
                                            : Defaultbutton(
                                                height:
                                                    getProportionateScreenHeight(
                                                        45),
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
                                                color: (isPhotoIdentite &&
                                                        isPhotoVisage)
                                                    ? pcolor
                                                    : colorBorder,
                                                textcolor: kWhiteColor,
                                                hasIcon: true,
                                                suffixIcon: Icon(
                                                  Icons.arrow_forward,
                                                  color: kWhiteColor,
                                                  size:
                                                      getProportionateScreenWidth(
                                                          24),
                                                ),
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
                                    backgroundColor: secondgreencolor,
                                    maxRadius:
                                        getProportionateScreenWidth(16),
                                    child: Icon(
                                      Icons.check,
                                      color: kWhiteColor,
                                      size: getProportionateScreenWidth(20),
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
                                        style: maintextstyle.copyWith(
                                            fontSize:
                                                getProportionateScreenWidth(
                                                    10),
                                            fontWeight: FontWeight.w600,
                                            color: kgrey400)),
                                    Text(
                                        getTranslated(context,
                                            "Informations d'identification")!,
                                        textScaleFactor: 1.0,
                                        style: maintextstyle.copyWith(
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
                                  left: getProportionateScreenWidth(15),
                                  right: getProportionateScreenWidth(15),
                                  top: getProportionateScreenHeight(5)),
                              height: getProportionateScreenHeight(15),
                              width: getProportionateScreenWidth(20),
                              child: VerticalDivider(
                                color: secondgreencolor,
                                width: getProportionateScreenWidth(11),
                                thickness: 2,
                              ),
                            ),
                          ],
                        ),
                  spaceHeight(6),
      
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
                                          getProportionateScreenWidth(3)),
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: colorBorder),
                                          shape: BoxShape.circle,
                                          color: kWhiteColor),
                                      child: SvgPicture.asset(
                                        "assets/icons/profile_plus.svg",
                                        colorFilter: const ColorFilter.mode(
                                            colorBorder, BlendMode.srcIn),
                                        width:
                                            getProportionateScreenWidth(22),
                                      ),
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
                                            style: maintextstyle.copyWith(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        10),
                                                fontWeight: FontWeight.w600,
                                                color: colorTextMuted)),
                                        Text(
                                            getTranslated(context,
                                                "Informations personnelles")!,
                                            textScaleFactor: 1.0,
                                            style: maintextstyle.copyWith(
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
                                      left: getProportionateScreenWidth(14),
                                      right: getProportionateScreenWidth(14),
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
                                        Container(
                                          padding: EdgeInsets.all(
                                              getProportionateScreenWidth(5)),
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: kBlackColor),
                                          child: SvgPicture.asset(
                                            "assets/icons/profile_plus.svg",
                                            colorFilter: const ColorFilter.mode(
                                                kWhiteColor, BlendMode.srcIn),
                                            width:
                                                getProportionateScreenWidth(
                                                    22),
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
                                                style: maintextstyle.copyWith(
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
                                                style: maintextstyle.copyWith(
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
                                    spaceHeight(8),
                                    Form(
                                      key: _formKey2,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          spaceWidth(5),
                                          SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    240),
                                            width:
                                                getProportionateScreenWidth(
                                                    20),
                                            child: VerticalDivider(
                                              color: kgrey300,
                                              width:
                                                  getProportionateScreenWidth(
                                                      11),
                                              thickness: 2,
                                            ),
                                          ),
                                          spaceWidth(10),
                                          SizedBox(
                                            width:
                                                getProportionateScreenWidth(
                                                    300),
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      getProportionateScreenWidth(
                                                          3)),
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: kgrey300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              getProportionateScreenWidth(
                                                                  12))),
                                                  child: TextFormField(
                                                      onChanged: (v) {
                                                        setState(() {
                                                          prenom = v;
                                                        });
                                                      },
                                                      validator: (v) =>
                                                          v!.isEmpty
                                                              ? getTranslated(
                                                                  context,
                                                                  "videerror")
                                                              : null,
                                                      decoration: textformdecoration
                                                          .copyWith(
                                                              labelText:
                                                                  getTranslated(
                                                                      context,
                                                                      "Prénom")!)),
                                                ),
                                                spaceHeight(8),
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      getProportionateScreenWidth(
                                                          3)),
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: kgrey300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              getProportionateScreenWidth(
                                                                  12))),
                                                  child: TextFormField(
                                                      onChanged: (v) {
                                                        setState(() {
                                                          nom = v;
                                                        });
                                                      },
                                                      validator: (v) =>
                                                          v!.isEmpty
                                                              ? getTranslated(
                                                                  context,
                                                                  "videerror")
                                                              : null,
                                                      decoration: textformdecoration
                                                          .copyWith(
                                                              labelText:
                                                                  getTranslated(
                                                                      context,
                                                                      "Nom")!)),
                                                ),
                                                spaceHeight(8),
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      getProportionateScreenWidth(
                                                          3)),
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: kgrey300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              getProportionateScreenWidth(
                                                                  12))),
                                                  child: TextFormField(
                                                    maxLength: 8,
                                                    inputFormatters: <
                                                        TextInputFormatter>[
                                                      FilteringTextInputFormatter
                                                          .allow(RegExp(
                                                              '[0-9]')),
                                                    ],
                                                    validator: (value) {
                                                      String pattern =
                                                          r'^[0-9]*$';
                                                      RegExp regExp =
                                                          new RegExp(pattern);
      
                                                      if (value!.isEmpty) {
                                                        return getTranslated(
                                                            context,
                                                            "telobligatoire");
                                                      } else {
                                                        if (value.startsWith('2') ||
                                                            value.startsWith(
                                                                '3') ||
                                                            value.startsWith(
                                                                '4')) {
                                                          if (value.length ==
                                                              8) {
                                                            if (regExp
                                                                .hasMatch(
                                                                    value)) {
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
                                                    decoration: textformdecoration.copyWith(
                                                        // prefixIcon:
                                                        //     Padding(
                                                        //   padding: EdgeInsets.symmetric(
                                                        //       vertical:
                                                        //           getProportionateScreenHeight(
                                                        //               10),
                                                        //       horizontal:
                                                        //           getProportionateScreenWidth(
                                                        //               6)),
                                                        //   child:
                                                        //       SvgPicture
                                                        //           .asset(
                                                        //     "assets/icons/phone.svg",
                                                        //     colorFilter: ColorFilter.mode(
                                                        //         kgrey800,
                                                        //         BlendMode
                                                        //             .srcIn),
                                                        //     height: 8,
                                                        //   ),
                                                        // ),
                                                        labelText: getTranslated(context, "Numéro de Téléphone")!),
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
                                                    : Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Defaultbutton(
                                                            height:
                                                                getProportionateScreenHeight(
                                                                    45),
                                                            width:
                                                                getProportionateScreenWidth(
                                                                    100),
                                                            text:
                                                                getTranslated(
                                                                    context,
                                                                    "Retour"),
                                                            onTap: () async {
                                                              setState(() {
                                                                _currentStep =
                                                                    _currentStep -
                                                                        1;
                                                                nniValid =
                                                                    false;
                                                              });
                                                            },
                                                            color:
                                                                kWhiteColor,
                                                            textcolor:
                                                                kBlackColor,
                                                            hasborder: true,
                                                            borderColor:
                                                                colorBorder,
                                                          ),
                                                          Defaultbutton(
                                                            height:
                                                                getProportionateScreenHeight(
                                                                    45),
                                                            width:
                                                                getProportionateScreenWidth(
                                                                    190),
                                                            text:
                                                                getTranslated(
                                                                    context,
                                                                    "suivant"),
                                                            onTap: () async {
                                                              setState(() {
                                                                _currentStep =
                                                                    _currentStep +
                                                                        1;
                                                                phoneValid =
                                                                    true;
                                                              });
                                                              // if (_formKey2
                                                              //     .currentState!
                                                              //     .validate()) {
                                                              //   telValidate();
                                                              // }
                                                            },
                                                            color: pcolor,
                                                            textcolor:
                                                                kWhiteColor,
                                                            hasIcon: true,
                                                            suffixIcon: Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              color:
                                                                  kWhiteColor,
                                                              size:
                                                                  getProportionateScreenWidth(
                                                                      22),
                                                            ),
                                                          ),
                                                        ],
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                            backgroundColor: secondgreencolor,
                                            maxRadius:
                                                getProportionateScreenWidth(
                                                    16),
                                            child: Icon(
                                              Icons.check,
                                              color: kWhiteColor,
                                              size:
                                                  getProportionateScreenWidth(
                                                      20),
                                            )),
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
                                                style: maintextstyle.copyWith(
                                                    fontSize:
                                                        getProportionateScreenWidth(
                                                            10),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: kgrey400)),
                                            Text(
                                                getTranslated(context,
                                                    "Informations Informations personnelles")!,
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
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
                                    Container(
                                      padding: EdgeInsets.only(
                                          left:
                                              getProportionateScreenWidth(15),
                                          right:
                                              getProportionateScreenWidth(15),
                                          top: getProportionateScreenHeight(
                                              5)),
                                      height:
                                          getProportionateScreenHeight(15),
                                      width: getProportionateScreenWidth(20),
                                      child: VerticalDivider(
                                        color: secondgreencolor,
                                        width:
                                            getProportionateScreenWidth(11),
                                        thickness: 2,
                                      ),
                                    ),
                                  ],
                                ),
                    ],
                  ),
      
                  // -------------- Otp ----------------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _currentStep != 2 && otpValid == false
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          getProportionateScreenWidth(8)),
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: colorBorder),
                                          shape: BoxShape.circle),
                                      child: Text('#',
                                          textScaleFactor: 1.0,
                                          style: maintextstyle.copyWith(
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
                                                context, "ÉTAPE 3")!,
                                            textScaleFactor: 1.0,
                                            style: maintextstyle.copyWith(
                                                fontSize:
                                                    getProportionateScreenWidth(
                                                        10),
                                                fontWeight: FontWeight.w600,
                                                color: colorTextMuted)),
                                        Text(
                                            getTranslated(context,
                                                "Confirmation numéro de téléphone")!,
                                            textScaleFactor: 1.0,
                                            style: maintextstyle.copyWith(
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
                                      left: getProportionateScreenWidth(14),
                                      right: getProportionateScreenWidth(14),
                                      top: getProportionateScreenHeight(0)),
                                  height: getProportionateScreenHeight(15),
                                  width: getProportionateScreenWidth(20),
                                  child: VerticalDivider(
                                    color: colorBorder,
                                    width: getProportionateScreenWidth(11),
                                    thickness: 2,
                                  ),
                                ),
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
                                          Container(
                                            padding: EdgeInsets.all(
                                                getProportionateScreenWidth(
                                                    11)),
                                            decoration: const BoxDecoration(
                                                color: kBlackColor,
                                                shape: BoxShape.circle),
                                            child: Text('#',
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
                                                    fontSize:
                                                        getProportionateScreenWidth(
                                                            18),
                                                    fontWeight:
                                                        FontWeight.w400,
                                                    color: kWhiteColor)),
                                          ),
                                          SizedBox(
                                            width:
                                                getProportionateScreenWidth(
                                                    10),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  getTranslated(
                                                      context, "ÉTAPE 3")!,
                                                  textScaleFactor: 1.0,
                                                  style: maintextstyle.copyWith(
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
                                                  style: maintextstyle.copyWith(
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
                                      spaceHeight(10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          spaceWidth(5),
                                          SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    220),
                                            width:
                                                getProportionateScreenWidth(
                                                    20),
                                            child: VerticalDivider(
                                              color: kgrey300,
                                              width:
                                                  getProportionateScreenWidth(
                                                      11),
                                              thickness: 2,
                                            ),
                                          ),
                                          spaceWidth(10),
                                          SizedBox(
                                            width:
                                                getProportionateScreenWidth(
                                                    300),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    text: getTranslated(
                                                        context,
                                                        'Bienvenue, '),
                                                    style: maintextstyle.copyWith(
                                                        fontSize:
                                                            getProportionateScreenWidth(
                                                                14),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: kBlackColor),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: getTranslated(
                                                            context,
                                                            'Mohamed Yahye El Joud'),
                                                        style: maintextstyle
                                                            .copyWith(
                                                                fontSize:
                                                                    getProportionateScreenWidth(
                                                                        14),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    pcolor),
                                                      ),
                                                      TextSpan(
                                                        text: getTranslated(
                                                            context,
                                                            ', Veuillez entrer le code OTP que nous avons envoyé à votre numéro 33 22 33 01'),
                                                        style: maintextstyle
                                                            .copyWith(
                                                                fontSize:
                                                                    getProportionateScreenWidth(
                                                                        14),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    kBlackColor),
                                                      ),
                                                    ],
                                                  ),
                                                  textScaleFactor: 1,
                                                  textAlign: TextAlign.center,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Container(
                                                        width:
                                                            getProportionateScreenWidth(
                                                                180),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal:
                                                              getProportionateScreenWidth(
                                                                  20),
                                                        ),
                                                        child:
                                                         CustomTimer(
                                                            controller:
                                                                _controller,
                                                            begin: Duration(
                                                                minutes:
                                                                    _duration),
                                                            end: const Duration(),
                                                            builder: (time) {
                                                              return Text(
                                                                  "${time.minutes}:${time.seconds}",
                                                                  textScaleFactor:
                                                                      1.0,
                                                                  style: maintextstyle.copyWith(
                                                                      fontSize:
                                                                          getProportionateScreenWidth(
                                                                              40),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color:
                                                                          kBlackColor));
                                                            },
                                                            stateBuilder:
                                                                (time,
                                                                    state) {
                                                              // If null is returned, "builder" is displayed.
                                                              return null;
                                                            },
                                                            animationBuilder:
                                                                (child) {
                                                              return AnimatedSwitcher(
                                                                duration: const Duration(
                                                                    milliseconds:
                                                                        250),
                                                                child: child,
                                                              );
                                                            },
                                                            onChangeState:
                                                                (state) {
                                                              if (state ==
                                                                  CustomTimerState
                                                                      .finished) {
                                                                setState(() {
                                                                  codeinvalid =
                                                                      true;
                                                                });
                                                              }
                                                              if (state ==
                                                                  CustomTimerState
                                                                      .reset) {
                                                                _controller
                                                                    .start();
                                                              }
                                                            }
                                                            )
                                                            ),
                                                  ],
                                                ),
                                                codeinvalid
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            getTranslated(
                                                                context,
                                                                "le code n'est plus valide")!,
                                                            textScaleFactor:
                                                                1.0,
                                                            style: maintextstyle
                                                                .copyWith(
                                                                    color:
                                                                        kredcolor),
                                                          ),
                                                          spaceWidth(3),
                                                          GestureDetector(
                                                              onTap:
                                                                  () async {
                                                                setState(() {
                                                                  codeinvalid =
                                                                      false;
                                                                });
                                                                _controller
                                                                    .reset();
                                                                var u = Uri.parse(
                                                                    "${NetworkService()
                                                                            .baseUrl}api/user/otp/verify/$phone/");
      
                                                                await get(u,
                                                                    headers: {
                                                                      'Content-Type':
                                                                          'application/json; charset=utf-8'
                                                                    });
                                                                // print(respone.statusCode);
                                                              },
                                                              child: Text(
                                                                getTranslated(
                                                                    context,
                                                                    "Ressayer")!,
                                                                textScaleFactor:
                                                                    1.0,
                                                                style: maintextstyle.copyWith(
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              SizedBox(
                                                                // width: SizeConfig
                                                                //         .screenWidth -
                                                                //     getProportionateScreenWidth(
                                                                //         100),
                                                                child:
                                                                    Directionality(
                                                                  textDirection:
                                                                      TextDirection
                                                                          .ltr,
                                                                  child:
                                                                      PinCodeTextField(
                                                                    enablePinAutofill:
                                                                        false,
                                                                    cursorHeight:
                                                                        getProportionateScreenWidth(
                                                                            20),
                                                                    appContext:
                                                                        context,
                                                                    pastedTextStyle:
                                                                        const TextStyle(
                                                                      color:
                                                                          kGreyColor,
                                                                      fontWeight:
                                                                          FontWeight.bold,
                                                                    ),
                                                                    length: 6,
                                                                    animationType:
                                                                        AnimationType
                                                                            .fade,
                                                                    validator:
                                                                        (v) {
                                                                      if (v!
                                                                          .isEmpty) {
                                                                        return "";
                                                                      } else {
                                                                        if (v.length ==
                                                                            6) {
                                                                          return null;
                                                                        }
                                                                        return "";
                                                                      }
                                                                    },
                                                                    pinTheme: PinTheme(
                                                                        borderWidth:
                                                                            1,
                                                                        selectedColor:
                                                                            kgrey100,
                                                                        inactiveColor:
                                                                            kgrey100,
                                                                        activeColor:
                                                                            kgrey100,
                                                                        selectedFillColor:
                                                                            kgrey100,
                                                                        inactiveFillColor:
                                                                            kgrey100,
                                                                        activeFillColor:
                                                                            kgrey100,
                                                                        shape: PinCodeFieldShape
                                                                            .box,
                                                                        borderRadius: BorderRadius.circular(getProportionateScreenWidth(
                                                                            10)),
                                                                        fieldHeight: getProportionateScreenHeight(
                                                                            48),
                                                                        fieldWidth: getProportionateScreenWidth(
                                                                            47),
                                                                        fieldOuterPadding:
                                                                            EdgeInsets.only(top: getProportionateScreenHeight(8))),
                                                                    obscuringWidget:
                                                                        Icon(
                                                                      Icons
                                                                          .circle,
                                                                      color:
                                                                          kBlackColor,
                                                                      size: getProportionateScreenWidth(
                                                                          22),
                                                                    ),
                                                                    cursorColor:
                                                                        kBlackColor,
                                                                    enableActiveFill:
                                                                        true,
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        msg =
                                                                            value;
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          spaceHeight(10),
                                                          loading
                                                              ? spiner()
                                                              : Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Defaultbutton(
                                                                      height:
                                                                          getProportionateScreenHeight(45),
                                                                      width: getProportionateScreenWidth(
                                                                          100),
                                                                      text: getTranslated(
                                                                          context,
                                                                          "Retour"),
                                                                      onTap:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          _currentStep =
                                                                              _currentStep - 1;
                                                                          phoneValid =
                                                                              false;
                                                                        });
                                                                      },
                                                                      color:
                                                                          kWhiteColor,
                                                                      textcolor:
                                                                          kBlackColor,
                                                                      hasborder:
                                                                          true,
                                                                      borderColor:
                                                                          colorBorder,
                                                                    ),
                                                                    Defaultbutton(
                                                                      height:
                                                                          getProportionateScreenHeight(45),
                                                                      width: getProportionateScreenWidth(
                                                                          190),
                                                                      text: getTranslated(
                                                                          context,
                                                                          "suivant"),
                                                                      onTap:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          _currentStep =
                                                                              _currentStep + 1;
                                                                          otpValid =
                                                                              true;
                                                                        });
                                                                        // if (_formKey2
                                                                        //     .currentState!
                                                                        //     .validate()) {
                                                                        //   otpValidate();
                                                                        // }
                                                                      },
                                                                      color:
                                                                          pcolor,
                                                                      textcolor:
                                                                          kWhiteColor,
                                                                      hasIcon:
                                                                          true,
                                                                      suffixIcon:
                                                                          Icon(
                                                                        Icons
                                                                            .arrow_forward,
                                                                        color:
                                                                            kWhiteColor,
                                                                        size:
                                                                            getProportionateScreenWidth(22),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                        ],
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    spaceHeight(5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                            backgroundColor: secondgreencolor,
                                            maxRadius:
                                                getProportionateScreenWidth(
                                                    16),
                                            child: Icon(
                                              Icons.check,
                                              color: kWhiteColor,
                                              size:
                                                  getProportionateScreenWidth(
                                                      20),
                                            )),
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
                                                    context, "ÉTAPE 3")!,
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
                                                    fontSize:
                                                        getProportionateScreenWidth(
                                                            10),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: kgrey400)),
                                            Text(
                                                getTranslated(context,
                                                    "Confirmation numéro de téléphone")!,
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
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
                                    Container(
                                      padding: EdgeInsets.only(
                                          left:
                                              getProportionateScreenWidth(15),
                                          right:
                                              getProportionateScreenWidth(15),
                                          top: getProportionateScreenHeight(
                                              5)),
                                      height:
                                          getProportionateScreenHeight(15),
                                      width: getProportionateScreenWidth(20),
                                      child: VerticalDivider(
                                        color: secondgreencolor,
                                        width:
                                            getProportionateScreenWidth(11),
                                        thickness: 2,
                                      ),
                                    ),
                                  ],
                                ),
                    ],
                  ),
                  spaceHeight(5),
      
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
                                      getProportionateScreenWidth(5)),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: colorBorder),
                                      shape: BoxShape.circle,
                                      color: kWhiteColor),
                                  child: SvgPicture.asset(
                                    "assets/icons/password.svg",
                                    colorFilter: const ColorFilter.mode(
                                        colorBorder, BlendMode.srcIn),
                                    width: getProportionateScreenWidth(20),
                                  ),
                                ),
                                SizedBox(
                                  width: getProportionateScreenWidth(10),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(getTranslated(context, "ÉTAPE 4")!,
                                        textScaleFactor: 1.0,
                                        style: maintextstyle.copyWith(
                                            fontSize:
                                                getProportionateScreenWidth(
                                                    10),
                                            fontWeight: FontWeight.w600,
                                            color: colorTextMuted)),
                                    Text(
                                        getTranslated(context,
                                            "Création mot de passe")!,
                                        textScaleFactor: 1.0,
                                        style: maintextstyle.copyWith(
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              getProportionateScreenWidth(5)),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBlackColor),
                                              shape: BoxShape.circle,
                                              color: kBlackColor),
                                          child: SvgPicture.asset(
                                            "assets/icons/password.svg",
                                            colorFilter: const ColorFilter.mode(
                                                kWhiteColor, BlendMode.srcIn),
                                            width:
                                                getProportionateScreenWidth(
                                                    20),
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
                                                    context, "ÉTAPE 4")!,
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
                                                    fontSize:
                                                        getProportionateScreenWidth(
                                                            10),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: colorTextMuted)),
                                            Text(
                                                getTranslated(context,
                                                    "Création mot de passe")!,
                                                textScaleFactor: 1.0,
                                                style: maintextstyle.copyWith(
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
                                    Form(
                                      key: _formKey3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Container(
                                              width:
                                                  getProportionateScreenWidth(
                                                      300),
                                              margin: EdgeInsets.symmetric(
                                                vertical:
                                                    getProportionateScreenHeight(
                                                        10),
                                              ),
                                              padding: EdgeInsets.only(
                                                  right:
                                                      getProportionateScreenWidth(
                                                          3),
                                                  left:
                                                      getProportionateScreenWidth(
                                                          10)),
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: kgrey300),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          getProportionateScreenWidth(
                                                              12))),
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/icons/password.svg",
                                                    colorFilter:
                                                        const ColorFilter.mode(
                                                            pcolor,
                                                            BlendMode.srcIn),
                                                    width:
                                                        getProportionateScreenWidth(
                                                            26),
                                                  ),
                                                  spaceWidth(5),
                                                  SizedBox(
                                                    width:
                                                        getProportionateScreenWidth(
                                                            250),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        spaceHeight(3),
                                                        Text(
                                                            getTranslated(
                                                                context,
                                                                "Mot de passe")!,
                                                            textScaleFactor:
                                                                1.0,
                                                            style: maintextstyle.copyWith(
                                                                fontSize:
                                                                    getProportionateScreenWidth(
                                                                        12),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    colorTextMuted)),
                                                        Directionality(
                                                          textDirection:
                                                              TextDirection
                                                                  .ltr,
                                                          child:
                                                              PinCodeTextField(
                                                            enablePinAutofill:
                                                                false,
                                                            cursorHeight:
                                                                getProportionateScreenWidth(
                                                                    20),
                                                            appContext:
                                                                context,
                                                            pastedTextStyle:
                                                                const TextStyle(
                                                              color:
                                                                  kGreyColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            length: 4,
                                                            animationType:
                                                                AnimationType
                                                                    .fade,
                                                            validator: (v) {
                                                              if (v!
                                                                  .isEmpty) {
                                                                return "";
                                                              } else {
                                                                if (v.length ==
                                                                    4) {
                                                                  return null;
                                                                }
                                                                return "";
                                                              }
                                                            },
                                                            pinTheme: PinTheme(
                                                                borderWidth:
                                                                    1,
                                                                selectedColor:
                                                                    kgrey100,
                                                                inactiveColor:
                                                                    kgrey100,
                                                                activeColor:
                                                                    kgrey100,
                                                                selectedFillColor:
                                                                    kgrey100,
                                                                inactiveFillColor:
                                                                    kgrey100,
                                                                activeFillColor:
                                                                    kgrey100,
                                                                shape:
                                                                    PinCodeFieldShape
                                                                        .box,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        getProportionateScreenWidth(
                                                                            10)),
                                                                fieldHeight:
                                                                    getProportionateScreenHeight(
                                                                        48),
                                                                fieldWidth:
                                                                    getProportionateScreenWidth(
                                                                        59),
                                                                fieldOuterPadding:
                                                                    EdgeInsets.only(
                                                                        top: getProportionateScreenHeight(
                                                                            8))),
                                                            obscuringWidget:
                                                                Icon(
                                                              Icons.circle,
                                                              color:
                                                                  kBlackColor,
                                                              size:
                                                                  getProportionateScreenWidth(
                                                                      22),
                                                            ),
                                                            cursorColor:
                                                                kBlackColor,
                                                            enableActiveFill:
                                                                true,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            onChanged:
                                                                (value) {
                                                              setState(() {
                                                                password =
                                                                    value;
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )),
                                          Container(
                                              width:
                                                  getProportionateScreenWidth(
                                                      300),
                                              padding: EdgeInsets.only(
                                                  right:
                                                      getProportionateScreenWidth(
                                                          3),
                                                  left:
                                                      getProportionateScreenWidth(
                                                          10)),
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: kgrey300),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          getProportionateScreenWidth(
                                                              12))),
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/icons/password.svg",
                                                    colorFilter:
                                                        const ColorFilter.mode(
                                                            pcolor,
                                                            BlendMode.srcIn),
                                                    width:
                                                        getProportionateScreenWidth(
                                                            26),
                                                  ),
                                                  spaceWidth(5),
                                                  SizedBox(
                                                    width:
                                                        getProportionateScreenWidth(
                                                            250),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        spaceHeight(3),
                                                        Text(
                                                            getTranslated(
                                                                context,
                                                                "Confirmation mot de passe")!,
                                                            textScaleFactor:
                                                                1.0,
                                                            style: maintextstyle.copyWith(
                                                                fontSize:
                                                                    getProportionateScreenWidth(
                                                                        12),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    colorTextMuted)),
                                                        Directionality(
                                                          textDirection:
                                                              TextDirection
                                                                  .ltr,
                                                          child:
                                                              PinCodeTextField(
                                                            enablePinAutofill:
                                                                false,
                                                            cursorHeight:
                                                                getProportionateScreenWidth(
                                                                    20),
                                                            appContext:
                                                                context,
                                                            pastedTextStyle:
                                                                const TextStyle(
                                                              color:
                                                                  kGreyColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            length: 4,
                                                            animationType:
                                                                AnimationType
                                                                    .fade,
                                                            validator: (v) {
                                                              if (v!
                                                                  .isEmpty) {
                                                                return "";
                                                              } else {
                                                                if (v.length ==
                                                                    4) {
                                                                  return null;
                                                                }
                                                                return "";
                                                              }
                                                            },
                                                            pinTheme: PinTheme(
                                                                borderWidth:
                                                                    1,
                                                                selectedColor:
                                                                    kgrey100,
                                                                inactiveColor:
                                                                    kgrey100,
                                                                activeColor:
                                                                    kgrey100,
                                                                selectedFillColor:
                                                                    kgrey100,
                                                                inactiveFillColor:
                                                                    kgrey100,
                                                                activeFillColor:
                                                                    kgrey100,
                                                                shape:
                                                                    PinCodeFieldShape
                                                                        .box,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        getProportionateScreenWidth(
                                                                            10)),
                                                                fieldHeight:
                                                                    getProportionateScreenHeight(
                                                                        48),
                                                                fieldWidth:
                                                                    getProportionateScreenWidth(
                                                                        59),
                                                                fieldOuterPadding:
                                                                    EdgeInsets.only(
                                                                        top: getProportionateScreenHeight(
                                                                            8))),
                                                            obscuringWidget:
                                                                Icon(
                                                              Icons.circle,
                                                              color:
                                                                  kBlackColor,
                                                              size:
                                                                  getProportionateScreenWidth(
                                                                      22),
                                                            ),
                                                            cursorColor:
                                                                kBlackColor,
                                                            enableActiveFill:
                                                                true,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            onChanged:
                                                                (value) {
                                                              setState(() {
                                                                newpassword =
                                                                    value;
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )),
                                          spaceHeight(10),
                                          loading
                                              ? spiner()
                                              : SizedBox(
                                                  width:
                                                      getProportionateScreenWidth(
                                                          300),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Defaultbutton(
                                                        height:
                                                            getProportionateScreenHeight(
                                                                45),
                                                        width:
                                                            getProportionateScreenWidth(
                                                                100),
                                                        text: getTranslated(
                                                            context,
                                                            "Retour"),
                                                        onTap: () async {
                                                          setState(() {
                                                            _currentStep =
                                                                _currentStep -
                                                                    1;
                                                            otpValid = false;
                                                          });
                                                        },
                                                        color: kWhiteColor,
                                                        textcolor:
                                                            kBlackColor,
                                                        hasborder: true,
                                                        borderColor:
                                                            colorBorder,
                                                      ),
                                                      Defaultbutton(
                                                        height:
                                                            getProportionateScreenHeight(
                                                                45),
                                                        width:
                                                            getProportionateScreenWidth(
                                                                190),
                                                        text: getTranslated(
                                                            context,
                                                            "confirmer"),
                                                        onTap: () async {
                                                          setState(() {});
                                                          // if (_formKey3
                                                          //     .currentState!
                                                          //     .validate()) {
                                                          //   continued();
                                                          // }
                                                        },
                                                        color: pcolor,
                                                        textcolor:
                                                            kWhiteColor,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ],
                                      ),
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
      
                  //-----------------------------------
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  continued() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        var url = Uri.parse(
            '${NetworkService().baseUrl}api/bmi/client_digiPay/get-nni/$nni/');

        setState(() {
          loading = true;
        });
        try {
          var response = await http.get(
            url,
            headers: {
              "Authorization":
                  "Api-Key PjfmiR38.WhxQ2EfxpJ3FB12HlyivYLH2FHnlmhRC"
            },
          ).timeout(const Duration(seconds: 60));
          // print(response.statusCode);
          // print(response.body);
          Map<String, dynamic>? map = json.decode(response.body);
          if (response.statusCode == 200) {
            if (map!.containsKey("msg")) {
              showToast(
                map['msg'],
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
                duration: const Duration(seconds: 7),
                animDuration: const Duration(milliseconds: 350),
                fullWidth: false,
                isHideKeyboard: false,
              );
              setState(() {
                loading = false;
              });
            } else {
              await storage.write(
                  key: "dateNaissance", value: map["dateNaissance"]);
              await storage.write(
                  key: "lieuNaissanceAr", value: map["lieuNaissanceAr"]);
              await storage.write(
                  key: "lieuNaissanceFr", value: map["lieuNaissanceFr"]);
              await storage.write(
                  key: "nationaliteIso", value: map["nationaliteIso"]);
              await storage.write(key: "nni", value: map["nni"]);
              await storage.write(
                  key: "nomFamilleAr", value: map["nomFamilleAr"]);
              await storage.write(
                  key: "nomFamilleFr", value: map["nomFamilleFr"]);
              await storage.write(key: "prenomAr", value: map["prenomAr"]);
              await storage.write(key: "prenomFr", value: map["prenomFr"]);
              await storage.write(
                  key: "prenomPereAr", value: map["prenomPereAr"]);
              await storage.write(
                  key: "prenomPereFr", value: map["prenomPereFr"]);
              await storage.write(key: "sexeFr", value: map["sexeFr"]);

              var startTime = DateTime.parse(map["dateNaissance"]);

              var currentTime = DateTime.now();
              var diff = currentTime.difference(startTime).inDays;

              if (diff > fiftenyears) {
                setState(() {
                  prenom = map["prenomFr"];
                  nom = map["nomFamilleFr"];
                  loading = false;
                  nniValid = true;
                  _currentStep += 1;
                });
              } else {
                showToast(
                  getTranslated(context, "Age minimum 15 ans"),
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
                  duration: const Duration(seconds: 7),
                  animDuration: const Duration(milliseconds: 350),
                  fullWidth: false,
                  isHideKeyboard: false,
                );
              }
            }
          } else {
            showToast(
              getTranslated(context, "Service non disponible"),
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
              duration: const Duration(seconds: 7),
              animDuration: const Duration(milliseconds: 350),
              fullWidth: false,
              isHideKeyboard: false,
            );
            setState(() {
              loading = false;
            });
          }
        } catch (e) {
          showToast(
            getTranslated(context, "Service non disponible"),
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
            duration: const Duration(seconds: 7),
            animDuration: const Duration(milliseconds: 350),
            fullWidth: false,
            isHideKeyboard: false,
          );
          setState(() {
            loading = false;
          });
        }
      }
    }
    if (_currentStep == 3) {
      if (_formKey3.currentState!.validate()) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Term(
                    password: newpassword,
                    tel: phone,
                  )),
        );
      }
    }
  }

  void telValidate() async {
    if (_currentStep == 1) {
      if (_formKey2.currentState!.validate()) {
        setState(() {
          loading = true;
        });
        Map body = {"nni": nni, "username": phone};
        var url = Uri.parse("${NetworkService().baseUrl}api/func/client_digiPay/register-validation/");
        try {
          var response = await post(url,
                  headers: {'Content-Type': 'application/json; charset=utf-8'},
                  body: jsonEncode(body))
              .timeout(const Duration(seconds: 20));
          // print(response.statusCode);
          if (response.statusCode == 200) {
            Map res = jsonDecode(response.body);
            if (res['status']) {
              var u = Uri.parse(
                  "${NetworkService().baseUrl}api/user/otp/verify/$phone/");

              var respone = await get(u,
                  headers: {'Content-Type': 'application/json; charset=utf-8'});
              // print(respone.statusCode);
              if (respone.statusCode == 200) {
                setState(() {
                  loading = false;
                  phoneValid = true;
                  _currentStep += 1;
                });
                _controller.start();
              } else {
                setState(() {
                  loading = false;
                });
                showToast(
                  getTranslated(context, "Envoi de le sms non effectué"),
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
                  duration: const Duration(seconds: 7),
                  animDuration: const Duration(milliseconds: 350),
                  fullWidth: false,
                  isHideKeyboard: false,
                );
              }
            } else {
              setState(() {
                loading = false;
              });
              showToast(
                res['msg'],
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
                duration: const Duration(seconds: 7),
                animDuration: const Duration(milliseconds: 350),
                fullWidth: false,
                isHideKeyboard: false,
              );
            }
          } else {
            setState(() {
              loading = false;
            });
            showToast(
              getTranslated(context, "nonetwork"),
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
              duration: const Duration(seconds: 7),
              animDuration: const Duration(milliseconds: 350),
              fullWidth: false,
              isHideKeyboard: false,
            );
          }
        } catch (e) {
          setState(() {
            loading = false;
          });
          showToast(
            getTranslated(context, "nonetwork"),
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
            duration: const Duration(seconds: 7),
            animDuration: const Duration(milliseconds: 350),
            fullWidth: false,
            isHideKeyboard: false,
          );
        }
      }
    }
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

          var respone = await post(u,
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
              duration: const Duration(seconds: 7),
              animDuration: const Duration(milliseconds: 350),
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
            duration: const Duration(seconds: 7),
            animDuration: const Duration(milliseconds: 350),
            fullWidth: false,
            isHideKeyboard: false,
          );
        }
      }
    }
  }
}
