import 'package:akarina/data/data_providers/exception.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/data/services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';


import 'logout_cubit.dart';

part 'change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  Repository? repository;
  LogoutCubit? logoutCubit;
  ChangePasswordCubit({this.logoutCubit, this.repository})
      : super(ChangePasswordInitial());

  void changepassword(Map body, String? ref, BuildContext context) async {
    emit(ChangePasswordLoading());

    try {
      final response = await repository!.changepassword(body);
      if (response['status'] == null) {
        // todo translate msg
        emit(ChangePasswordError(msg: 'Mot de passe actuel incorrect'));
      } else {
        Map body = {"refresh": ref};
        logoutCubit!.logout(body, context);
        emit(ChangePasswordSuccess());
      }
    } on Failure catch (f) {
      if (f.code == 1) {
        Services().getNewToken(context).then((value) {
          if (value) {
            changepassword(body, ref, context);
          }
        }).onError((dynamic error, stackTrace) {});
      } else {
        emit(ChangePasswordError(msg: 'Mot de passe actuel incorrect'));
      }
    }
  }
}
