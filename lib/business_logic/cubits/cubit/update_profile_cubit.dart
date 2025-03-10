import 'package:akarina/data/data_providers/exception.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/data/services.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'update_profile_state.dart';

class UpdateProfileCubit extends Cubit<UpdateProfileState> {
  Repository? repository;
  UpdateProfileCubit({this.repository}) : super(UpdateProfileInitial());

  void updateprofile(Map body, BuildContext context) async {
    final storage = FlutterSecureStorage();

    try {
      final response = await repository!.updateprofile(body);
      await storage.write(key: "email", value: response["email"]);
      await storage.write(key: "adresse", value: response["adresse"]);
      emit(UpdateProfilesucsses());
    } on Failure catch (f) {
      if (f.code == 1) {
        Services().getNewToken(context).then((value) {
          if (value) {
            updateprofile(body, context);
          }
        }).onError((dynamic error, stackTrace) {});
      } else {
        emit(UpdateProfileerror(msg: getTranslated(context, "nonetwork")));
      }
    }
  }
}
