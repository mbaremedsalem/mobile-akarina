import 'package:akarina/data/data_providers/exception.dart';
import 'package:akarina/data/models/profile.dart';
import 'package:akarina/data/services.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter/cupertino.dart';

import '../../../data/repositories/repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  Repository? repository;
  ProfileCubit({this.repository}) : super(ProfileInitial());

  void fetchprofiledata(BuildContext context) async {
    emit(Profileloading());
    try {
      final response = await repository!.profiledata();
      emit(ProfileSucsses(profil: response));
    } on Failure catch (f) {
      if (f.code == 1) {
        Services().getNewToken(context).then((value) {
          if (value) {
            fetchprofiledata(context);
          }
        }).onError((dynamic error, stackTrace) {
          emit(ProfileError());
        });
      } else {
        emit(ProfileError());
      }
    }
  }
}
