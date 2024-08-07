import 'package:equatable/equatable.dart';

abstract class DevelopedbyState extends Equatable {
  const DevelopedbyState();

  @override
  List<Object> get props => [];
}

class DevelopedbyInitial extends DevelopedbyState {}

class DevelopedByError extends DevelopedbyState {}
class DevelopedByLoading extends DevelopedbyState {}

class DevelopedBySuccess extends DevelopedbyState {
  final String? developedBy;

  DevelopedBySuccess({this.developedBy});
}

