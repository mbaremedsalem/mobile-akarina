

import 'package:akarina/business_logic/cubits/cubit/check_token_state.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_bloc/flutter_bloc.dart';


class CheckTokenCubit extends Cubit<CheckTokenState> {
  Repository repository;
  CheckTokenCubit({required this.repository}) : super(CheckTokenInitial());

  void checkLogin() async {
    bool firstrun = await checkFirstRun();

    if (firstrun) {
      emit(FirstRun());
    } else {
      FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.delete(key: "token");
      await storage.delete(key: "refresh");
      await storage.delete(key: "id");
      await storage.delete(key: "adresse");
      await storage.delete(key: "email");
      emit(NotFirstRun());
    }
  }

  Future<bool> checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('first_run') ?? true) {
      FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.deleteAll();
      prefs.setBool('first_run', false);
      await storage.write(key: 'country', value: 'Mauritania');
      return true;
    } else {
      return false;
    }
  }
}
