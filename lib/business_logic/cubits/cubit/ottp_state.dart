abstract class OtpState {}

class OtpInitial extends OtpState {}

class OtpLoading extends OtpState {}
class OtpRequestSuccess extends OtpState {
  final String message;
  OtpRequestSuccess(this.message);
}
class OtpRequestError extends OtpState {
  final String error;
  OtpRequestError(this.error);
}

class OtpVerificationLoading extends OtpState {}
class OtpVerificationSuccess extends OtpState {
  final String message;
  OtpVerificationSuccess(this.message);
}
class OtpVerificationError extends OtpState {
  final String error;
  OtpVerificationError(this.error);
}