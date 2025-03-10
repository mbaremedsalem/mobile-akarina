import 'package:akarina/business_logic/cubits/cubit/change_password_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/logout_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/update_profile_cubit.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/divider.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/dialogs/passwordchange.dart';
import 'package:akarina/presentations/dialogs/success_dialog.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:package_info_plus/package_info_plus.dart';



// ignore: must_be_immutable
class Inforamtion extends StatefulWidget {
  Inforamtion(
      {Key? key,
      this.first,
      this.last,
      this.telephone,
      this.adresse,
      this.date,
      this.email,
      this.valide_en_agence})
      : super(key: key);

  String? first;
  String? last;
  String? telephone;
  String? email;
  String? adresse;
  String? date;
  String? valide_en_agence;

  @override
  _InforamtionState createState() => _InforamtionState();
}

class _InforamtionState extends State<Inforamtion> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();

  final storage = const FlutterSecureStorage();

  Repository repository = Repository(networkService: NetworkService());

  bool adresseeditable = false;
  bool emaileditable = false;

  String? originalemail;
  String? originaladress;
  String versionApp = "";
  String buildApp = "";

  void fetch() async {
    String? fetchedadresse = await storage.read(key: "adresse");
    String? fetchedemail = await storage.read(key: "email");

    setState(() {
      originaladress = fetchedadresse;
      originalemail = fetchedemail;
    });
  }

  void appInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String versionNumber = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    setState(() {
      buildApp = buildNumber;
      versionApp = versionNumber;
    });
  }

  @override
  void initState() {
    super.initState();
    fetch();
    appInfo();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateProfileCubit, UpdateProfileState>(
      listener: (context, state) {
        if (state is UpdateProfileerror) {
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
            duration: Duration(seconds: 7),
            animDuration: Duration(milliseconds: 350),
            fullWidth: false,
            isHideKeyboard: false,
          );
        }

        if (state is UpdateProfilesucsses) {
          Navigator.pop(context);
          showDialog(
              context: context,
              builder: (_) =>
                  Succesdialog(msag: getTranslated(context, "oper")));
        }
      },
      builder: (context, state) {
        return Container(
          margin: EdgeInsets.all(getProportionateScreenWidth(25)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "tel")!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    Text(
                      widget.telephone ?? "",
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(
                          color: kBlackColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "prenom")!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    Expanded(
                      child: Text(
                        widget.first ?? "",
                        textScaleFactor: 1.0,
                        textAlign: TextAlign.end,
                        style: maintextstyle.copyWith(
                            color: kBlackColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "nom")!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    Expanded(
                      child: Text(
                        widget.last ?? "",
                        textScaleFactor: 1.0,
                        textAlign: TextAlign.end,
                        style: maintextstyle.copyWith(
                            color: kBlackColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, 'Status du compte')!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.valide_en_agence == 'true'
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(6)),
                      ),
                      padding: EdgeInsets.symmetric(
                          // vertical:
                          //     getProportionateScreenHeight(3),
                          horizontal: getProportionateScreenWidth(15)),
                      child: Text(
                        widget.valide_en_agence == 'true'
                            ? getTranslated(context, "activee")!
                            : getTranslated(context, 'non active') ?? '',
                        textScaleFactor: 1.0,
                        style: maintextstyle.copyWith(
                            fontSize: getProportionateScreenWidth(14),
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "Compte bancaire")!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    Text(
                      "",
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(
                          color: kBlackColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "ID Client")!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(6),
                    ),
                    Text(
                      "",
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(
                          color: kBlackColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "Date de naissance")!,
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(color: kBlackColor),
                    ),
                    Text(
                      widget.date?.substring(0, 10) ?? '',
                      textScaleFactor: 1.0,
                      style: maintextstyle.copyWith(
                          color: kBlackColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          getTranslated(context, "Adresse")!,
                          textScaleFactor: 1.0,
                          style: maintextstyle.copyWith(color: kBlackColor),
                        ),
                        SizedBox(
                          width: getProportionateScreenWidth(8),
                        ),
                        // InkWell(
                        //   onTap: () {
                        //     setState(() {
                        //       adresseeditable = !adresseeditable;
                        //     });
                        //   },
                        //   child: SvgPicture.asset(
                        //     "assets/icons/pencil.svg",
                        //     color: kdarkgoldcolr,
                        //   ),
                        // )
                      ],
                    ),
                    adresseeditable
                        ? Container(
                            width: getProportionateScreenWidth(220),
                            child: TextFormField(
                              validator: (v) => v!.isEmpty
                                  ? getTranslated(context, "videerror")
                                  : null,
                              onChanged: (v) {
                                widget.adresse = v;
                              },
                              initialValue: widget.adresse,
                              textAlign: TextAlign.center,
                              // decoration: textformdecoration,
                            ),
                          )
                        : Flexible(
                            child: Text(
                              widget.adresse ?? '',
                              textScaleFactor: 1.0,
                              style: maintextstyle.copyWith(
                                  color: kBlackColor,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          getTranslated(context, "Email")!,
                          textScaleFactor: 1.0,
                          style: maintextstyle.copyWith(color: kBlackColor),
                        ),
                        SizedBox(
                          width: getProportionateScreenWidth(8),
                        ),
                        // InkWell(
                        //   onTap: () {
                        //     setState(() {
                        //       emaileditable = !emaileditable;
                        //     });
                        //   },
                        //   child: SvgPicture.asset(
                        //     "assets/icons/pencil.svg",
                        //     color: kdarkgoldcolr,
                        //   ),
                        // )
                      ],
                    ),
                    emaileditable
                        ? Container(
                            width: getProportionateScreenWidth(192),
                            child: TextFormField(
                              validator: (v) => v!.isEmpty
                                  ? getTranslated(context, "videerror")
                                  : null,
                              onChanged: (v) {
                                widget.email = v;
                              },
                              textAlign: TextAlign.center,
                              initialValue: widget.email,
                            ),
                          )
                        : Flexible(
                            child: Text(
                              widget.email ?? '',
                              textScaleFactor: 1.0,
                              style: maintextstyle.copyWith(
                                  color: kBlackColor,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                  ],
                ),
                defaultdivider(height: getProportionateScreenHeight(10)),
                SizedBox(
                  height: getProportionateScreenHeight(20),
                ),
                // state is UpdateProfileloading
                //     ? SpinKitThreeBounce(
                //         color: kmaincolor,
                //         size: getProportionateScreenWidth(25),
                //       )
                //     : Defaultbutton(
                //         height: getProportionateScreenHeight(40),
                //         color: Colors.green.shade50,
                //         onTap: () async {
                //           if (originaladress == widget.adresse &&
                //               originalemail == widget.email) {
                //             Toster.toaster(
                //               context,
                //               Colors.orange,
                //               getTranslated(
                //                   context, "Aucune modification détectée"),
                //             );
                //           } else {
                //             if (_formKey.currentState!.validate()) {
                //               Map body = {
                //                 "username": widget.telephone,
                //                 "first_name": widget.first,
                //                 "last_name": widget.last,
                //                 "adresse": widget.adresse,
                //                 "email": widget.email,
                //                 "role": "CLIENT",
                //                 "tel": widget.telephone
                //               };
                //               BlocProvider.of<UpdateProfileCubit>(context)
                //                   .updateprofile(body, context);
                //             }
                //           }
                //         },
                //         textcolor: pcolor,
                //         text: getTranslated(context, "save"),
                //       ),
                // SizedBox(
                //   height: getProportionateScreenHeight(20),
                // ),
                state is UpdateProfileloading
                    ? Container()
                    : Defaultbutton(
                        height: getProportionateScreenHeight(45),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => BlocProvider(
                              create: (context) => ChangePasswordCubit(
                                  repository: repository,
                                  logoutCubit:
                                      LogoutCubit(repository: repository)),
                              child: const Passwordchange(),
                            ),
                          );
                        },
                        color: klightgrey,
                        text: getTranslated(context, "changerpassword"),
                      ),
                SizedBox(
                  height: getProportionateScreenHeight(20),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Version : $versionApp",
                        textScaleFactor: 1.0,
                        style: maintextstyle.copyWith(
                            color: kBlackColor,
                            fontSize: getProportionateScreenWidth(12)),
                      ),
                      // SizedBox(
                      //   width: getProportionateScreenWidth(6),
                      // ),
                      // Text(
                      //   'Build : ' + buildApp,
                      //   textScaleFactor: 1.0,
                      //   style: maintextstyle.copyWith(
                      //       color: kBlackColor,
                      //       fontSize: getProportionateScreenWidth(12)),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
