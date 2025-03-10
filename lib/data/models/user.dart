class User {
  final int id;
  final String? nomComplet;
  final String email;
  final String? image;
  final String numeroTelephone;
  final String? nni;
  final bool verificationStatus;
  final bool activationStatus;
  final String? preference;

  User({
    required this.id,
    this.nomComplet,
    required this.email,
    this.image,
    required this.numeroTelephone,
    this.nni,
    required this.verificationStatus,
    required this.activationStatus,
    this.preference,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nomComplet: json['nom_complet'] ?? "", // Valeur par défaut vide si null
      email: json['email'],
      image: json['image'], // Peut être null
      numeroTelephone: json['numero_telephone'] ?? "",
      nni: json['nni'], // Peut être null
      verificationStatus: json['verification_status'] ?? false,
      activationStatus: json['activation_status'] ?? false,
      preference: json['preference'], // Peut être null
    );
  }
}
