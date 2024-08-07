import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class Loginloading extends LoginState {}

class LoginError extends LoginState {
  final String? msg;
  LoginError({this.msg});
}

class LoginSuccess extends LoginState {}
