import 'dart:convert';
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

  void userLogin({
    required String phone,
    required String password,
  }) async {
    emit(LoginLoadingState());

    try {
      final response = await http.post(
        Uri.parse('https://akarina.online/user/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': '+222$phone', // Utilisation de "login" attendu par l'API
          'password': password,
          'lang': 'ar', // Ajout de la langue si nécessaire
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('access') && data.containsKey('refresh') && data.containsKey('id')) {
          await storage.write(key: "access", value: data["access"]);
          await storage.write(key: "refresh", value: data["refresh"]);
          await storage.write(key: "id", value: data["id"].toString());

          loginModel = LoginModel.fromJason(data);
          
          emit(LoginSuccessState(loginModel!));
        } else {
          emit(LoginErrorState("Invalid response structure"));
        }
      } else {
        final errorData = json.decode(response.body);
        emit(LoginErrorState(errorData["non_field_errors"][0] ?? "Invalid credentials"));
      }
    } catch (e) {
      emit(LoginErrorState("An error occurred: ${e.toString()}"));
    }
  }
}
