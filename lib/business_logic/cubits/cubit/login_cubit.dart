
import 'package:akarina/business_logic/cubits/cubit/login_state.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';




class LoginCubit extends Cubit<LoginState> {
  Repository? repository;
  LoginCubit({this.repository}) : super(LoginInitial());

  void login(
      String telephone, String? password, String? uid, BuildContext context) {
    final storage = FlutterSecureStorage();
    emit(Loginloading());
    // print(uid);
    repository!.login(telephone, password, uid).then((value) async {
      // print(value);

      if (value['detail'] != null) {
        if (value['detail'] == 'Téléphone non autorisé !') {
          emit(LoginError(
              msg: getTranslated(context, 'Téléphone non autorisé !')));
        } else if (value['detail'] ==
            "Compte bloqué. Merci de réinitialiser votre mot de passe") {
          emit(LoginError(
              msg: getTranslated(context,
                  'Compte bloqué. Merci de réinitialiser votre mot de passe')));
        } else {
          emit(LoginError(msg: getTranslated(context, "vérifiez")));
        }
        emit(LoginError(msg: value['detail']));
      } else {
        // print(value["access"]);
        await storage.write(
            key: "dateNaissance", value: value["date_naissance"]);
        await storage.write(key: "token", value: value["access"]);
        await storage.write(key: "refresh", value: value["refresh"]);
        await storage.write(key: "premium", value: value["premium"].toString());
        await storage.write(key: "firstname", value: value["first_name"]);
        await storage.write(key: "id", value: value["id"].toString());
        await storage.write(key: "lastname", value: value["last_name"]);
        await storage.write(key: "tel", value: value["tel"]);
        await storage.write(key: "email", value: value["email"]);
        await storage.write(key: "adresse", value: value["adresse"]);
        await storage.write(key: "identifiant", value: value["identifiant"]);
        await storage.write(
            key: "valide_en_agence",
            value: value["valide_en_agence"].toString());
        await storage.write(
            key: "langue", value: value["langue"].toString().toLowerCase());
        await storage.write(
            key: "langueLocal",
            value: Localizations.localeOf(context).languageCode);
        // Utilities.getfcmtoken();
        emit(LoginSuccess());
      }
    }).onError((dynamic error, stackTrace) {
      emit(LoginError(msg: getTranslated(context, "nonetwork")));
    });
  }
}
