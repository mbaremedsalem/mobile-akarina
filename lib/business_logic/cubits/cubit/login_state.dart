import 'package:akarina/data/models/login_model.dart';

abstract class LoginStates {}

class LoginInitialState extends LoginStates {}

class LoginLoadingState extends LoginStates {}

class LoginSuccessState extends LoginStates {
  final LoginModel loginModel;
  LoginSuccessState(this.loginModel);
}

class LoginErrorState extends LoginStates {
  final String error;
  LoginErrorState(this.error);
}

// Nouveaux états pour les comptes bloqués/inactifs
class LoginAccountBlockedState extends LoginStates {
  final String message;
  final bool verificationStatus;
  
  LoginAccountBlockedState({
    required this.message,
    required this.verificationStatus,
  });
}

class LoginAccountInactiveState extends LoginStates {
  final String message;
  final bool activationStatus;
  
  LoginAccountInactiveState({
    required this.message,
    required this.activationStatus,
  });
}