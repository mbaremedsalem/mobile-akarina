// import 'package:equatable/equatable.dart';

// abstract class LoginState {}

// class LoginInitial extends LoginState {}

// class LoginLoading extends LoginState {}

// class LoginError extends LoginState {
//   final String? msg;
//   LoginError({this.msg});
// }

// class LoginSuccess extends LoginState {}


import 'package:akarina/data/models/login_model.dart';


abstract class LoginStates{}

class LoginInitialState extends LoginStates{}

class LoginLoadingState extends LoginStates{}

class LoginSuccessState extends LoginStates
{
  final LoginModel loginModel;
  LoginSuccessState(this.loginModel);
}

class LoginErrorState extends LoginStates
{
  final String error;
  LoginErrorState(this.error);
}

class ChangePasswordVisibilityState extends LoginStates{}



