import 'package:equatable/equatable.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginError extends LoginState {
  final String? msg;
  LoginError({this.msg});
}

class LoginSuccess extends LoginState {}
