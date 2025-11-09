import 'package:akarina/presentations/components/country_select.dart';
import 'package:akarina/presentations/components/langue_select.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../business_logic/cubits/cubit/login_cubit.dart';
import '../../../business_logic/cubits/cubit/login_state.dart';
import '../../../data/localization/language_constants.dart';
import '../../../size_config.dart';
import '../../components/default_button.dart';
import '../../components/spiner.dart';
import '../../layout/layout.dart';
import 'dart:convert';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? password;
  String? uid;
  String? pays;
  final _formKey = GlobalKey<FormState>();
  final telephonecontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return  BlocProvider<LoginCubit>(
      create: (BuildContext context) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginStates>(
      listener: (context, state) {
          if (state is LoginSuccessState) {
            Fluttertoast.showToast(
              msg: state.loginModel.message ?? 'Connexion réussie',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            ).then((value) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Layout()),
                (route) => false,
              );
            });
          } else if (state is LoginErrorState) {
            Fluttertoast.showToast(
              msg: state.error ?? 'Erreur de connexion',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        },
        builder: (context, state) {
          return     Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin:
                            EdgeInsets.only(top: getProportionateScreenHeight(20)),
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding:
                                  EdgeInsets.all(getProportionateScreenWidth(3)),
                              decoration: BoxDecoration(
                                  border: Border.all(color: kgrey300),
                                  borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12))),
                              child: 
                              TextFormField(
                                maxLength: 8,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp('[0-9]')),
                                ],
                                controller: telephonecontroller,
                                validator: (value) {
                                  String pattern = r'^[0-9]*$';
                                  RegExp regExp = RegExp(pattern);
        
                                  if (value!.isEmpty) {
                                    return getTranslated(context, "telobligatoire");
                                  } else {
                                    if (value.startsWith('2') ||
                                        value.startsWith('3') ||
                                        value.startsWith('4')) {
                                      if (value.length == 8) {
                                        if (regExp.hasMatch(value)) {
                                          return null;
                                        } else {
                                          return getTranslated(
                                              context, "telnonvalide");
                                        }
                                      } else {
                                        return getTranslated(
                                            context, "telnonvalide");
                                      }
                                    } else {
                                      return getTranslated(context, "telnonvalide");
                                    }
                                  }
                                },
                                keyboardType: TextInputType.number,
                                decoration: textformdecoration.copyWith(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(20),
                                      vertical: getProportionateScreenHeight(10)),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: getProportionateScreenHeight(10),
                                        horizontal: getProportionateScreenWidth(6)),
                                    child: SvgPicture.asset(
                                      "assets/icons/phone.svg",
                                      colorFilter:
                                          const ColorFilter.mode(pcolor, BlendMode.srcIn),
                                      height: 8,
                                    ),
                                  ),
                                  // hintText:
                                  //     getTranslated(context, 'Numéro de Téléphone'),
                                  labelText:
                                      getTranslated(context, 'Numéro de Téléphone'),
                                ),
                              ),
                            
                            ),
                          ],
                        ),
                      ),
                      spaceHeight(10),
                      Container(
                          width: SizeConfig.screenWidth - getProportionateScreenWidth(40),
                          margin: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(20),
                          ),
                          padding: EdgeInsets.only(
                              right: getProportionateScreenWidth(10),
                              left: getProportionateScreenWidth(10)),
                          decoration: BoxDecoration(
                              border: Border.all(color: kgrey300),
                              borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(12))),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/password.svg",
                                colorFilter:
                                    const ColorFilter.mode(pcolor, BlendMode.srcIn),
                                width: getProportionateScreenWidth(28),
                              ),
                              spaceWidth(8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  spaceHeight(4),
                                  Text(getTranslated(context, "code")!,
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize: getProportionateScreenWidth(12),
                                          fontWeight: FontWeight.w400,
                                          color: kBlackColor)),
                                  SizedBox(
                                    width: SizeConfig.screenWidth -
                                        getProportionateScreenWidth(100),
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: PinCodeTextField(
                                        enablePinAutofill: false,
                                        cursorHeight:
                                            getProportionateScreenWidth(20),
                                        appContext: context,
                                        pastedTextStyle:  TextStyle(
                                          color: kgrey500,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        length: 4,
                                        animationType: AnimationType.fade,
                                        validator: (v) {
                                          if (v!.isEmpty) {
                                            return "";
                                          } else {
                                            if (v.length == 4) {
                                              return null;
                                            }
                                            return "";
                                          }
                                        },
                                        pinTheme: PinTheme(
                                            borderWidth: 1,
                                            selectedColor: colorSurfaceElement,
                                            inactiveColor: colorSurfaceElement,
                                            activeColor: colorSurfaceElement,
                                            selectedFillColor: colorSurfaceElement,
                                            inactiveFillColor: colorSurfaceElement,
                                            activeFillColor: colorSurfaceElement,
                                            shape: PinCodeFieldShape.box,
                                            borderRadius: BorderRadius.circular(
                                                getProportionateScreenWidth(10)),
                                            fieldHeight:
                                                getProportionateScreenHeight(48),
                                            fieldWidth:
                                                getProportionateScreenWidth(64),
                                            fieldOuterPadding: EdgeInsets.only(
                                                top: getProportionateScreenHeight(
                                                    8))),
                                        obscuringWidget: Icon(
                                          Icons.circle,
                                          color: kBlackColor,
                                          size: getProportionateScreenWidth(22),
                                        ),
                                        cursorColor: kBlackColor,
                                        enableActiveFill: true,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(),
                                        onChanged: (value) {
                                          setState(() {
                                            password = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                
                                ],
                              ),
                            ],
                          )
                          ),
                      // devTestBanner(),
                    ],
                  ),
                ),
                SizedBox(
                  height: getProportionateScreenHeight(10),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                           
                          // showDialog(
                          //     context: context,
                          //     builder: (context) => ForgetPassword());
                          // Navigator.of(context).pushNamed("restore_password",
                          //     arguments: telephonecontroller.text);
                        },
                        child: Text(
                          getTranslated(context, "Mot de passe oublié ?")!,
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: kgrey800,
                              fontSize: getProportionateScreenWidth(12),
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: getProportionateScreenHeight(20),
                ),
                
                state is !LoginLoadingState
                ? 
                 Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(20)),
                        child: 
                        Defaultbutton(
                          height: getProportionateScreenHeight(45),
                          text: getTranslated(context, "cnx"),
                          onTap: () async {

                            FocusScope.of(context)
                                            .requestFocus(FocusNode());
                                        if (_formKey.currentState!.validate()) {
                                          LoginCubit.get(context).userLogin(
                                            phone: telephonecontroller.text,
                                            password: password!,
                                          );
                                        }
                            
                          
                          },
                          color: pcolor,
                          textcolor: kWhiteColor,
                        ),
                      ):spiner(
                  
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet<String>(
                            context: context,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        getProportionateScreenHeight(20)),
                                    topRight: Radius.circular(
                                        getProportionateScreenHeight(20)))),
                            builder: (BuildContext context) {
                              return CountrySelect(
                                country: pays,
                              );
                            },
                          ).then((value) {
                            setState(() {
                              if (value != null && value != '') {
                                pays = value;
                              }
                            });
                            
                          });
                        },
                        child: Text(
                          getTranslated(context, "Changer le pays")!,
                          textScaleFactor: 1.0,
                          style: TextStyle(
                            color: kgrey700,
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      
                      Icon(
                        Icons.circle,
                        color: kgrey700,
                        size: getProportionateScreenWidth(4),
                      ),
        
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet<String>(
                            context: context,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        getProportionateScreenHeight(20)),
                                    topRight: Radius.circular(
                                        getProportionateScreenHeight(20)))),
                            builder: (BuildContext context) {
                              return const LangueSelect();
                            },
                          );
                        },
                        child: Text(
                          getTranslated(context, "Changer la langue")!,
                          textScaleFactor: 1.0,
                          style: TextStyle(
                            color: kgrey700,
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                spaceHeight(10),
                GestureDetector(
                  onTap: () {
                    // Navigator.push(
                    //     context, MaterialPageRoute(builder: (_) => Contactus()));
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(20)),
                    height: getProportionateScreenHeight(45),
                    decoration: BoxDecoration(
                        border: Border.all(color: kgrey300),
                        borderRadius:
                            BorderRadius.circular(getProportionateScreenWidth(12)),
                        color: kWhiteColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/icons/chat.svg",
                          colorFilter:
                              const ColorFilter.mode(kBlackColor, BlendMode.srcIn),
                          width: getProportionateScreenWidth(24),
                        ),
                        spaceWidth(10),
                        Text(
                          getTranslated(context, "Contactez-nous")!,
                          textScaleFactor: 1.0,
                          style: TextStyle(
                            color: kBlackColor,
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                spaceHeight(20),
              ],
            );
        },
      ),
    );
  
  
    

  }
}