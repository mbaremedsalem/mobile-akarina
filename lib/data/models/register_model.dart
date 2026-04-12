class RegisterModel {
  final String status;
  final String message;
  final UserData data;
  final String clientType;
  final bool accountCreated;

  RegisterModel({
    required this.status,
    required this.message,
    required this.data,
    required this.clientType,
    required this.accountCreated,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: UserData.fromJson(json['data'] ?? {}),
      clientType: json['client_type'] ?? '',
      accountCreated: json['account_created'] ?? false,
    );
  }
}

class UserData {
  final String email;
  final String nomComplet;
  final String numeroTelephone;
  final String clientType;

  UserData({
    required this.email,
    required this.nomComplet,
    required this.numeroTelephone,
    required this.clientType,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      email: json['email'] ?? '',
      nomComplet: json['nom_complet'] ?? '',
      numeroTelephone: json['numero_telephone'] ?? '',
      clientType: json['client_type'] ?? '',
    );
  }
}