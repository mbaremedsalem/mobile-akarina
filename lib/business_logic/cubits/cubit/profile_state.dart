part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class Profileloading extends ProfileState {}

class ProfileError extends ProfileState {}

class ProfileSucsses extends ProfileState {
  final Profil? profil;

  const ProfileSucsses({this.profil});
}
