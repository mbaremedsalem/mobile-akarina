import 'dart:convert';
import 'package:akarina/business_logic/cubits/cubit/ottp_state.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class OtpCubit extends Cubit<OtpState> {
  final Repository? repository;
  
  OtpCubit({this.repository}) : super(OtpInitial());

  void requestOtp({required String phone}) async {
    emit(OtpLoading());

    try {
      final response = await repository!.requestOtp(phone);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        emit(OtpRequestSuccess(data["message"]));
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = _getOtpErrorMessage(errorData);
        emit(OtpRequestError(errorMessage));
      }
    } catch (e) {
      emit(OtpRequestError("Une erreur s'est produite: ${e.toString()}"));
    }
  }

  void verifyOtp({required String phone, required String otp}) async {
    emit(OtpVerificationLoading());

    try {
      final response = await repository!.verifyOtp(phone, otp);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["valid"] == true) {
        emit(OtpVerificationSuccess(data["message"]));
      } else {
        final errorMessage = data["message"] ?? "OTP invalide";
        print(errorMessage);
        emit(OtpVerificationError(errorMessage));
      }
    } catch (e) {
      emit(OtpVerificationError("Une erreur s'est produite: ${e.toString()}"));
    }
  }

  String _getOtpErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey("phone")) {
      return errorData["phone"][0];
    } else if (errorData.containsKey("message")) {
      return errorData["message"];
    } else {
      return "Erreur lors de l'envoi du code OTP";
    }
  }

  void resetOtpState() {
    emit(OtpInitial());
  }
}