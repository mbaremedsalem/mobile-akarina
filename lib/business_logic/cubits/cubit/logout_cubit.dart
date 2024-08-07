
import 'package:akarina/business_logic/cubits/cubit/logout_state.dart';
import 'package:akarina/data/data_providers/exception.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/data/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class LogoutCubit extends Cubit<LogoutState> {
  Repository? repository;
  LogoutCubit({this.repository}) : super(LogoutInitial());

  void logout(Map body, BuildContext context) async {
    emit(LogoutLoading());
    final storage = FlutterSecureStorage();
    try {
      await repository!.logout(body);
      await storage.delete(key: "token");
      await storage.delete(key: "refresh");
      await storage.delete(key: "role");
      await storage.delete(key: "firstname");
      await storage.delete(key: "lastname");
      await storage.delete(key: "id");
      await storage.delete(key: "adresse");
      await storage.delete(key: "email");
      await storage.delete(key: "valide_en_agence");
      emit(LogoutSuccess());
    } on Failure catch (f) {
      if (f.code == 1) {
        Services().getNewToken(context).then((value) {
          if (value) {
            logout(body, context);
          }
        }).onError((dynamic error, stackTrace) {
          emit(LogoutError());
        });
      } else {
        emit(LogoutError());
      }
    }

    // repository.logout(body).then((v) async {
    //   await storage.delete(key: "token");
    //   await storage.delete(key: "refresh");
    //   await storage.delete(key: "role");
    //   await storage.delete(key: "firstname");
    //   await storage.delete(key: "lastname");
    //   await storage.delete(key: "id");
    //   await storage.delete(key: "adresse");
    //   await storage.delete(key: "email");
    //   emit(LogoutSuccess());
    // }).onError((error, stackTrace) {
    //   emit(LogoutError());
    // });
  }
}
