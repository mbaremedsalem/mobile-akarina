import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/login_state.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/showToast.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/layout/layout.dart';
import 'package:akarina/presentations/screens/register/register.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/spiner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool? filledColor = false;

  String hintText = '';

  TextEditingController phoneController = TextEditingController();

  TextEditingController passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return  Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 50),
            child: Form(
              key: _formKey,
              child: Column(
              children: [
                 Center(
                child: 
                  SvgPicture.asset(
                      'assets/svg/logo.svg',
                  width: 180,
                  height: 180,
                ),
              ),
                SizedBox(height: getProportionateScreenHeight(20),),
                Text(
                getTranslated(context, 'Login to your Account')!
                ,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
               ) ,
               Text(
                getTranslated(context, 'Welcome back, please enter your details')!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:kgrey600,
                ),
               ),
               SizedBox(height: getProportionateScreenHeight(25)),
                defaultTextField(
                            controller: phoneController,
                            type: TextInputType.text,
                            text: getTranslated(context, 'Téléphone')!,
                            prefix: Icons.phone,
                          ),
                defaultTextField(
                            controller: passController,
                            type: TextInputType.text,
                            text: getTranslated(context, 'code')!,
                            
                            prefix: Icons.lock,
                            suffix: Icons.remove_red_eye,
                          ),
              Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: (){},
                  child: Text(
                    getTranslated(context, 'Mot de passe oublié ?')!,
                      style: const TextStyle(
                          color:
                              pcolor,
                                  fontSize: 18,
                                    fontWeight:
                                    FontWeight.w500)
                                    ),
                                  ),
                                        ],
                                      ),
              SizedBox(height: getProportionateScreenHeight(5),),
                            BlocConsumer<LoginCubit, LoginState>(
                listener: (context, state) {
                  if (state is LoginError) {
                    showToaster(context, state.msg, kredcolor);
                  }
                  if (state is LoginSuccess) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Layout()),
                      (route) => false,
                    );
                  }
                },
                builder: (context, state) {
                  return (state is LoginLoading)
                      ? spiner()
                      : 
                      Defaultbutton(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              BlocProvider.of<LoginCubit>(context).login(
                                context,
                                phoneController.text,
                                passController.text,
                              );
                            }
                          },
                          color: pcolor,
                          textcolor: kWhiteColor,
                          text: getTranslated(context, 'cnx')!,
                          borderRadius: getProportionateScreenWidth(5),
                          width: getProportionateScreenWidth(500),
                          height: getProportionateScreenHeight(45),
                        );
                },
              ),

                        
                         Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                               Text(
                                                getTranslated(context, 'Vous navez pas un compte?')!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const Register()));
                                                },
                                                child: Text(
                                                  getTranslated(context, 'register')!,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color:pcolor),
                                                ),
                                              ),
                                            ],
                                          ),
              ],
              ),
            ),
          ),
        )
        ),
    );
  }
}