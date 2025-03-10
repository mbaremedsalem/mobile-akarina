import 'package:akarina/business_logic/cubits/cubit/change_password_cubit.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';



class Passwordchange extends StatefulWidget {
  const Passwordchange({
    Key? key,
  }) : super(key: key);

  @override
  _PasswordchangeState createState() => _PasswordchangeState();
}

class _PasswordchangeState extends State<Passwordchange> {
  String? ref;

  void fetch() async {
    String? refresh = await storage.read(key: "refresh");

    setState(() {
      ref = refresh;
    });
  }

  @override
  void initState() {
    super.initState();
    fetch();
  }

  String? old;
  final storage = const FlutterSecureStorage();

  String? newpassword;
  bool obscure1 = true;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
                listener: (context, state) {
                  if (state is ChangePasswordError) {
                    showToast(
                      state.msg,
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
                  if (state is ChangePasswordSuccess) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, "login", (route) => false);
                  }
                },
                builder: (context, state) {
                  return Stack(children: [
                    Form(
                      key: _formKey,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: kWhiteColor),
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: ListView(shrinkWrap: true, children: [
                          SizedBox(
                            height: getProportionateScreenHeight(10),
                          ),
                          Text(
                            getTranslated(context, "changerpassword")!,
                            textScaleFactor: 1.0,
                            style: maintextstyle.copyWith(
                                color: kBlackColor,
                                fontWeight: FontWeight.bold,
                                fontSize: getProportionateScreenWidth(20)),
                          ),
                          SizedBox(
                            height: getProportionateScreenHeight(10),
                          ),
                          Text(getTranslated(context, "oldpassword")!,
                              textScaleFactor: 1.0,
                              style:
                                  maintextstyle.copyWith(color: kBlackColor)),
                          SizedBox(
                            height: getProportionateScreenHeight(5),
                          ),
                          TextFormField(
                              cursorHeight: getProportionateScreenHeight(18),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp('[0-9]')),
                              ],
                              keyboardType: TextInputType.number,
                              obscureText: obscure1,
                              validator: (v) {
                                if (v!.isEmpty) {
                                  return getTranslated(context, "pay2");
                                } else {
                                  if (v.length == 4) {
                                    return null;
                                  }
                                  return getTranslated(
                                      context, "courtmotdepasse");
                                }
                              },
                              onChanged: (v) {
                                setState(() {
                                  old = v;
                                });
                              },
                              decoration: textformdecoration.copyWith(
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      obscure1 = !obscure1;
                                    });
                                  },
                                  child: const Icon(
                                    Icons.visibility,
                                    color: pdarkcolor,
                                  ),
                                ),
                              )),
                          SizedBox(
                            height: getProportionateScreenHeight(8),
                          ),
                          Text(getTranslated(context, "new")!,
                              textScaleFactor: 1.0,
                              style:
                                  maintextstyle.copyWith(color: kBlackColor)),
                          SizedBox(
                            height: getProportionateScreenHeight(5),
                          ),
                          TextFormField(
                              cursorHeight: getProportionateScreenHeight(18),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp('[0-9]')),
                              ],
                              keyboardType: TextInputType.number,
                              obscureText: obscure1,
                              validator: (v) {
                                if (v!.isEmpty) {
                                  return getTranslated(context, "pay2");
                                } else {
                                  if (v.length == 4) {
                                    return null;
                                  }
                                  return getTranslated(
                                      context, "courtmotdepasse");
                                }
                              },
                              onChanged: (v) {
                                setState(() {
                                  newpassword = v;
                                });
                              },
                              decoration: textformdecoration.copyWith()),
                          SizedBox(
                            height: getProportionateScreenHeight(8),
                          ),
                          Text(getTranslated(context, "confirme")!,
                              textScaleFactor: 1.0,
                              style:
                                  maintextstyle.copyWith(color: kBlackColor)),
                          SizedBox(
                            height: getProportionateScreenHeight(5),
                          ),
                          TextFormField(
                              cursorHeight: getProportionateScreenHeight(18),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp('[0-9]')),
                              ],
                              keyboardType: TextInputType.number,
                              obscureText: obscure1,
                              validator: (v) => v != newpassword
                                  ? getTranslated(context, "identiquemot")
                                  : null,
                              decoration: textformdecoration.copyWith()),
                          SizedBox(
                            height: getProportionateScreenHeight(25),
                          ),
                          state is ChangePasswordLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SpinKitThreeBounce(
                                      color: kmaincolor,
                                      size: getProportionateScreenWidth(25),
                                    ),
                                  ],
                                )
                              // ignore: deprecated_member_use
                              : Defaultbutton(
                                  height: getProportionateScreenHeight(40),
                                  onTap: () async {
                                    if (_formKey.currentState!.validate()) {
                                      Map body = {
                                        "new_password": newpassword,
                                        "old_password": old
                                      };

                                      BlocProvider.of<ChangePasswordCubit>(
                                              context)
                                          .changepassword(body, ref, context);
                                    }
                                  },
                                  color: pdarkcolor,
                                  textcolor: klightgrey,
                                  text:
                                      getTranslated(context, "changerpassword"),
                                )
                        ]),
                      ),
                    ),
                    back(context)
                  ]);
                },
              ),
            ],
          ),
        ));
  }
}
