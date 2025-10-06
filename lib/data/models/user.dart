// Modèle User
class User {
  final int id;
  final String? nomComplet;
  final String? email;
  final String? image;
  final String? numeroTelephone;
  final String? nni;
  final bool verificationStatus;
  final bool activationStatus;
  final String? preference;

  User({
    required this.id,
    this.nomComplet,
    this.email,
    this.image,
    this.numeroTelephone,
    this.nni,
    required this.verificationStatus,
    required this.activationStatus,
    this.preference,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nomComplet: json['nom_complet'],
      email: json['email'],
      image: json['image'],
      numeroTelephone: json['numero_telephone'],
      nni: json['nni'],
      verificationStatus: json['verification_status'],
      activationStatus: json['activation_status'],
      preference: json['preference'],
    );
  }
}