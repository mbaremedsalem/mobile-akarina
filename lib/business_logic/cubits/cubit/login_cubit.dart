import 'package:akarina/data/data_providers/account_service.dart';
import 'package:akarina/data/services/fcm_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../data/models/login_model.dart';
import '../../../data/repositories/repository.dart';
import 'login_state.dart';

/// Connexion via https://admin-akarina.akarina.shop/api/connexion/
/// (username + mot de passe, jeton DRF stocké sous "admin_token") — c'est
/// désormais le seul backend d'authentification de l'app.
class LoginCubit extends Cubit<LoginStates> {
  Repository? repository;
  LoginCubit({this.repository}) : super(LoginInitialState());

  static LoginCubit get(context) => BlocProvider.of(context);

  final storage = const FlutterSecureStorage();
  LoginModel? loginModel;

  void userLogin({
    required String username,
    required String password,
  }) async {
    emit(LoginLoadingState());

    try {
      final token = await AccountService().login(username, password);
      if (token == null || token.isEmpty) {
        emit(LoginErrorState("Identifiants invalides"));
        return;
      }

      await storage.write(key: "admin_token", value: token);
      FCMService.registerTokenAfterLogin();

      // Meilleur effort : récupère le prénom pour le message de bienvenue et
      // garde l'id utilisateur en cache. Ne doit jamais faire échouer la
      // connexion si le profil ne charge pas.
      String welcomeName = username;
      try {
        final profile = await AccountService().fetchProfile(token);
        if (profile != null) {
          final id = profile['id'];
          if (id != null) await storage.write(key: "id", value: id.toString());
          final firstName = profile['first_name']?.toString();
          if (firstName != null && firstName.isNotEmpty) welcomeName = firstName;
        }
      } catch (_) {}

      loginModel = LoginModel.fromJason({'message': welcomeName});
      emit(LoginSuccessState(loginModel!));
    } catch (e) {
      emit(LoginErrorState("Erreur de connexion: ${e.toString()}"));
    }
  }
}
