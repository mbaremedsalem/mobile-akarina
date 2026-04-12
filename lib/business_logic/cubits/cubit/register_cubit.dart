// register_cubit.dart
import 'dart:convert';
import 'dart:io';
import 'package:akarina/data/models/register_model.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final Repository? repository;
  
  RegisterCubit({this.repository}) : super(RegisterInitialState());

  RegisterModel? registerModel;

  void userRegister({
    required String email,
    required String nomComplet,
    required String numeroTelephone,
    required String password,
    required String confirmPassword,
    required String clientType,
    required String nni,
    required String emplacement,
    File? carteIdentiteFile,
  }) async {
    emit(RegisterLoadingState());

    try {
      final response = await repository!.userSignup(
        email: email,
        nomComplet: nomComplet,
        numeroTelephone: numeroTelephone,
        password: password,
        confirmPassword: confirmPassword,
        clientType: clientType,
        nni: nni,
        emplacement: emplacement,
        carteIdentiteFile: carteIdentiteFile,
      );

      if (response != null) {
        final data = json.decode(response.body);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          registerModel = RegisterModel.fromJson(data);
          emit(RegisterSuccessState(registerModel!));
        } else if (response.statusCode == 400) {
          // Gestion des erreurs de validation
          final errorMessage = _getErrorMessage(data);
          emit(RegisterErrorState(errorMessage));
        } else {
          emit(RegisterErrorState(data['message'] ?? "Erreur lors de l'inscription"));
        }
      } else {
        emit(RegisterErrorState("Erreur de connexion au serveur"));
        print("Response is null");
      }
    } catch (e) {
      emit(RegisterErrorState("Une erreur s'est produite: ${e.toString()}"));
    }
  }

  String _getErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey('errors')) {
      final errors = errorData['errors'];
      if (errors.containsKey('email')) {
        return errors['email'][0];
      }
      if (errors.containsKey('numero_telephone')) {
        return errors['numero_telephone'][0];
      }
      if (errors.containsKey('nni')) {
        return errors['nni'][0];
      }
      return "Erreur de validation des données";
    }
    return errorData['message'] ?? "Erreur lors de l'inscription";
  }
}