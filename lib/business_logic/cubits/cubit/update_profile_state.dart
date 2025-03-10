part of 'update_profile_cubit.dart';

abstract class UpdateProfileState extends Equatable {
  const UpdateProfileState();

  @override
  List<Object> get props => [];
}

class UpdateProfileInitial extends UpdateProfileState {}

class UpdateProfileloading extends UpdateProfileState {}

class UpdateProfileerror extends UpdateProfileState {
  String? msg;

  UpdateProfileerror({this.msg});
}

class UpdateProfilesucsses extends UpdateProfileState {}
