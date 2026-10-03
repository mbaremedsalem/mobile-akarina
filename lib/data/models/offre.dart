/// Modèle pour l'API https://admin-akarina.akarina.shop/api/offres/.
library;

class Offre {
  final int id;
  final String titre;
  final String titreAr;
  final String description;
  final String descriptionAr;

  /// promotion, reduction...
  final String typeOffre;

  final String? image;
  final int? bienId;
  final String? reductionPourcentage;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool actif;

  const Offre({
    required this.id,
    required this.titre,
    required this.titreAr,
    required this.description,
    required this.descriptionAr,
    required this.typeOffre,
    this.image,
    this.bienId,
    this.reductionPourcentage,
    this.dateDebut,
    this.dateFin,
    required this.actif,
  });

  factory Offre.fromJson(Map<String, dynamic> json) => Offre(
        id: _asInt(json['id']) ?? 0,
        titre: json['titre']?.toString() ?? '',
        titreAr: json['titre_ar']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        descriptionAr: json['description_ar']?.toString() ?? '',
        typeOffre: json['type_offre']?.toString() ?? '',
        image: json['image']?.toString(),
        bienId: _asInt(json['bien']),
        reductionPourcentage: json['reduction_pourcentage']?.toString(),
        dateDebut: DateTime.tryParse(json['date_debut']?.toString() ?? ''),
        dateFin: DateTime.tryParse(json['date_fin']?.toString() ?? ''),
        actif: json['actif'] == true,
      );

  String titreFor(String language) =>
      language == 'ar' && titreAr.isNotEmpty ? titreAr : titre;

  String descriptionFor(String language) =>
      language == 'ar' && descriptionAr.isNotEmpty ? descriptionAr : description;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
