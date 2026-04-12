// register_state.dart
import 'package:akarina/data/models/register_model.dart';

abstract class RegisterState {}

class RegisterInitialState extends RegisterState {}

class RegisterLoadingState extends RegisterState {}

class RegisterSuccessState extends RegisterState {
  final RegisterModel registerModel;
  RegisterSuccessState(this.registerModel);
}

class RegisterErrorState extends RegisterState {
  final String errorMessage;
  RegisterErrorState(this.errorMessage);
}