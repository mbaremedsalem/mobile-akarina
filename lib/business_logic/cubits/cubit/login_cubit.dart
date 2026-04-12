import 'dart:convert';
import 'package:akarina/data/global.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/login_model.dart';
import '../../../data/repositories/repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginStates> {
  Repository? repository;
  LoginCubit({this.repository}) : super(LoginInitialState());

  static LoginCubit get(context) => BlocProvider.of(context);

  final storage = const FlutterSecureStorage();
  LoginModel? loginModel;

  Future<String?> getCurrentLanguage() async {
    // Récupérer la langue sélectionnée depuis le stockage local
    return await storage.read(key: "languageCode") ?? "ar"; // Par défaut, "ar"
  }

  void userLogin({
    required String phone,
    required String password,
  }) async {
    emit(LoginLoadingState());

    try {
      final currentLanguage = await getCurrentLanguage();
      final response = await http.post(
        Uri.parse('https://akarina.shop/user/api/login/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'login': '+222$phone', // Utilisation de "login" attendu par l'API
          'password': password,
          'lang': currentLanguage, // Ajout de la langue si nécessaire
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('access') && data.containsKey('refresh') && data.containsKey('id')) {
          await storage.write(key: "access", value: data["access"]);
          keySetion = data["access"];

          await storage.write(key: "role", value: data["role"]);
          await storage.write(key: "refresh", value: data["refresh"]);
          await storage.write(key: "id", value: data["id"].toString());

          loginModel = LoginModel.fromJason(data);
          final acces = await storage.read(key: "access");
        
          emit(LoginSuccessState(loginModel!));
        } else {
          emit(LoginErrorState("Invalid response structure"));
        }
      } 
      // Gestion spécifique du compte bloqué (403 Forbidden)
      else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        
        // Vérifier si c'est une erreur de compte bloqué
        if (errorData["error"] == "account_blocked") {
          emit(LoginAccountBlockedState(
            message: errorData["message"] ?? "Votre compte est bloqué",
            verificationStatus: errorData["verification_status"] ?? false,
          ));
        } 
        // Vérifier si c'est une erreur de compte inactif
        else if (errorData["error"] == "account_inactive") {
          emit(LoginAccountInactiveState(
            message: errorData["message"] ?? "Votre compte est inactif",
            activationStatus: errorData["activation_status"] ?? false,
          ));
        }
        // Autres erreurs 403
        else {
          emit(LoginErrorState(errorData["message"] ?? "Accès non autorisé"));
        }
      }
      // Autres erreurs (401, 404, 500, etc.)
      else {
        final errorData = json.decode(response.body);
        
        // Gérer les différents formats d'erreur possibles
        String errorMessage = "Erreur de connexion";
        if (errorData.containsKey("non_field_errors")) {
          errorMessage = errorData["non_field_errors"][0];
        } else if (errorData.containsKey("message")) {
          errorMessage = errorData["message"];
        } else if (errorData.containsKey("detail")) {
          errorMessage = errorData["detail"];
        } else {
          errorMessage = "Identifiants invalides";
        }
        
        emit(LoginErrorState(errorMessage));
      }
    } catch (e) {
      emit(LoginErrorState("Erreur de connexion: ${e.toString()}"));
    }
  }
}