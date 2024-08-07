
import 'package:equatable/equatable.dart';

abstract class CheckTokenState extends Equatable {
  const CheckTokenState();

  @override
  List<Object> get props => [];
}

class CheckTokenInitial extends CheckTokenState {}

// class Tokenvalid extends CheckTokenState {}

// class Tokeninvalid extends CheckTokenState {}

class FirstRun extends CheckTokenState {}

class NotFirstRun extends CheckTokenState {}
