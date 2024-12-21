
import 'package:akarina/business_logic/cubits/cubit/login_state.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';



class LoginCubit extends Cubit<LoginState> {
  Repository? repository;
  LoginCubit({this.repository}) : super(LoginInitial());

  void login(BuildContext context, String? phone, String? password) {
    FlutterSecureStorage storage = const FlutterSecureStorage();
    emit(LoginLoading());

    repository!.login(phone!, password).then((value) async {
      if (value['access'] == '') {
        emit(LoginError(msg: value['non_field_errors']));
      } else if (value['access'] != '') {
        await storage.write(key: "access", value: value["access"]);
        await storage.write(key: "id", value: value["id"].toString());
        await storage.write(key: "refresh", value: value["refresh"]);
        emit(LoginSuccess());
      }
    }).onError((dynamic error, stackTrace) {
      emit(LoginError(msg: getTranslated(context,'Assurer que vous avez connexion internet')!));
    });
  }
}

