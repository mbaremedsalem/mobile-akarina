/// Modèles pour l'API https://admin-akarina.akarina.shop/api/.
///
/// `Bien.fromJson` accepte aussi bien la forme "liste" (ville/quartier imbriqués
/// avec leur nom) que la forme "détail" (ville/quartier réduits à leur id) : le
/// détail ne renvoie pas les noms, donc les écrans qui en ont besoin doivent les
/// résoudre eux-mêmes via [BienService.fetchVilles].
library;

class Quartier {
  final int id;
  final int villeId;
  final String nom;
  final String nomAr;

  const Quartier({
    required this.id,
    required this.villeId,
    required this.nom,
    required this.nomAr,
  });

  factory Quartier.fromJson(Map<String, dynamic> json) => Quartier(
        id: _asInt(json['id']) ?? 0,
        villeId: _asInt(json['ville']) ?? 0,
        nom: json['nom']?.toString() ?? '',
        nomAr: json['nom_ar']?.toString() ?? '',
      );

  String nomFor(String language) =>
      language == 'ar' && nomAr.isNotEmpty ? nomAr : nom;
}

class Ville {
  final int id;
  final String nom;
  final String nomAr;
  final List<Quartier> quartiers;

  const Ville({
    required this.id,
    required this.nom,
    required this.nomAr,
    this.quartiers = const [],
  });

  factory Ville.fromJson(Map<String, dynamic> json) => Ville(
        id: _asInt(json['id']) ?? 0,
        nom: json['nom']?.toString() ?? '',
        nomAr: json['nom_ar']?.toString() ?? '',
        quartiers: (json['quartiers'] as List<dynamic>? ?? [])
            .map((q) => Quartier.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  String nomFor(String language) =>
      language == 'ar' && nomAr.isNotEmpty ? nomAr : nom;
}

class Equipement {
  final int id;
  final String nom;
  final String nomAr;
  final String icone;

  const Equipement({
    required this.id,
    required this.nom,
    required this.nomAr,
    required this.icone,
  });

  factory Equipement.fromJson(Map<String, dynamic> json) => Equipement(
        id: _asInt(json['id']) ?? 0,
        nom: json['nom']?.toString() ?? '',
        nomAr: json['nom_ar']?.toString() ?? '',
        icone: json['icone']?.toString() ?? '',
      );

  String nomFor(String language) =>
      language == 'ar' && nomAr.isNotEmpty ? nomAr : nom;
}

class BienMedia {
  final int id;
  final String typeMedia;
  final String fichier;
  final String legende;

  /// Ordre d'affichage voulu par le propriétaire/gestionnaire (0 = pas de
  /// préférence). Les médias sont triés dessus dans [Bien.fromJson].
  final int ordre;

  const BienMedia({
    required this.id,
    required this.typeMedia,
    required this.fichier,
    this.legende = '',
    this.ordre = 0,
  });

  factory BienMedia.fromJson(Map<String, dynamic> json) => BienMedia(
        id: _asInt(json['id']) ?? 0,
        typeMedia: json['type_media']?.toString() ?? 'image',
        fichier: json['fichier']?.toString() ?? '',
        legende: json['legende']?.toString() ?? '',
        ordre: _asInt(json['ordre']) ?? 0,
      );

  bool get isVideo => typeMedia == 'video';
}

class Indisponibilite {
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String motif;
  final DateTime? dateCreation;

  const Indisponibilite({
    this.dateDebut,
    this.dateFin,
    this.motif = '',
    this.dateCreation,
  });

  factory Indisponibilite.fromJson(Map<String, dynamic> json) =>
      Indisponibilite(
        dateDebut: DateTime.tryParse(json['date_debut']?.toString() ?? ''),
        dateFin: DateTime.tryParse(json['date_fin']?.toString() ?? ''),
        motif: json['motif']?.toString() ?? '',
        dateCreation: DateTime.tryParse(json['date_creation']?.toString() ?? ''),
      );
}

class Gestionnaire {
  final int id;
  final String username;
  final String? telephone;
  final String? firstName;
  final String? lastName;

  const Gestionnaire({
    required this.id,
    required this.username,
    this.telephone,
    this.firstName,
    this.lastName,
  });

  factory Gestionnaire.fromJson(Map<String, dynamic> json) => Gestionnaire(
        id: _asInt(json['id']) ?? 0,
        username: json['username']?.toString() ?? '',
        telephone: json['telephone']?.toString(),
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
      );

  /// Nom complet si disponible, sinon le nom d'utilisateur.
  String get nomAffiche {
    final full = [firstName, lastName]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' ')
        .trim();
    return full.isNotEmpty ? full : username;
  }
}

class Bien {
  final int id;
  final String reference;
  final String titre;
  final String titreAr;
  final String? description;
  final String? descriptionAr;

  /// appartement, duplexe, ceremonie, terrain, commercial.
  final String typeBien;

  /// location, vente.
  final String typeTransaction;

  final bool meuble;
  final int? nbChambres;
  final int? nbSallesBain;
  final int? nbEtages;

  final String? prix;
  final String uniteprix;

  final int villeId;
  final String villeNom;
  final String villeNomAr;
  final int quartierId;
  final String quartierNom;
  final String quartierNomAr;

  /// Adresse complète telle que renseignée par le gestionnaire (renvoyée par
  /// le détail d'un bien uniquement — absente de la liste). Préférable à
  /// villeNom/quartierNom quand présente : pas besoin de résoudre les id via
  /// [BienService.fetchVilles].
  final String? adresseComplete;
  final String? adresseCompleteAr;

  final int? nbProprietaires;

  final double? latitude;
  final double? longitude;

  final String? photoPrincipale;
  final bool actif;
  final bool vendu;

  final DateTime? dateCreation;
  final DateTime? dateModification;

  final List<Equipement> equipements;
  final List<BienMedia> medias;
  final List<Indisponibilite> indisponibilites;
  final List<Gestionnaire> gestionnaires;

  /// Détails spécifiques aux biens de type "ceremonie"/"terrain" : la forme
  /// exacte de ces objets n'est pas encore documentée par l'API, on les
  /// garde tels quels pour un usage futur.
  final Map<String, dynamic>? detailCeremonie;
  final Map<String, dynamic>? detailTerrain;

  const Bien({
    required this.id,
    required this.reference,
    required this.titre,
    required this.titreAr,
    this.description,
    this.descriptionAr,
    required this.typeBien,
    required this.typeTransaction,
    required this.meuble,
    this.nbChambres,
    this.nbSallesBain,
    this.nbEtages,
    this.prix,
    required this.uniteprix,
    required this.villeId,
    required this.villeNom,
    required this.villeNomAr,
    required this.quartierId,
    required this.quartierNom,
    required this.quartierNomAr,
    this.adresseComplete,
    this.adresseCompleteAr,
    this.nbProprietaires,
    this.latitude,
    this.longitude,
    this.photoPrincipale,
    required this.actif,
    required this.vendu,
    this.dateCreation,
    this.dateModification,
    this.equipements = const [],
    this.medias = const [],
    this.indisponibilites = const [],
    this.gestionnaires = const [],
    this.detailCeremonie,
    this.detailTerrain,
  });

  bool get isVente => typeTransaction == 'vente';

  factory Bien.fromJson(Map<String, dynamic> json) {
    final villeRaw = json['ville'];
    final quartierRaw = json['quartier'];

    int villeId = 0;
    String villeNom = '';
    String villeNomAr = '';
    if (villeRaw is Map) {
      villeId = _asInt(villeRaw['id']) ?? 0;
      villeNom = villeRaw['nom']?.toString() ?? '';
      villeNomAr = villeRaw['nom_ar']?.toString() ?? '';
    } else {
      villeId = _asInt(villeRaw) ?? 0;
    }

    int quartierId = 0;
    String quartierNom = '';
    String quartierNomAr = '';
    if (quartierRaw is Map) {
      quartierId = _asInt(quartierRaw['id']) ?? 0;
      quartierNom = quartierRaw['nom']?.toString() ?? '';
      quartierNomAr = quartierRaw['nom_ar']?.toString() ?? '';
    } else {
      quartierId = _asInt(quartierRaw) ?? 0;
    }

    return Bien(
      id: _asInt(json['id']) ?? 0,
      reference: json['reference']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      titreAr: json['titre_ar']?.toString() ?? '',
      description: json['description']?.toString(),
      descriptionAr: json['description_ar']?.toString(),
      typeBien: json['type_bien']?.toString() ?? '',
      typeTransaction: json['type_transaction']?.toString() ?? 'location',
      meuble: json['meuble'] == true,
      nbChambres: _asInt(json['nb_chambres']),
      nbSallesBain: _asInt(json['nb_salles_bain']),
      nbEtages: _asInt(json['nb_etages']),
      prix: json['prix']?.toString(),
      uniteprix: json['unite_prix']?.toString() ?? 'mois',
      villeId: villeId,
      villeNom: villeNom,
      villeNomAr: villeNomAr,
      quartierId: quartierId,
      quartierNom: quartierNom,
      quartierNomAr: quartierNomAr,
      adresseComplete: json['adresse_complete']?.toString(),
      adresseCompleteAr: json['adresse_complete_ar']?.toString(),
      nbProprietaires: _asInt(json['nb_proprietaires']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      photoPrincipale: json['photo_principale']?.toString(),
      actif: json['actif'] == true,
      vendu: json['vendu'] == true,
      dateCreation: DateTime.tryParse(json['date_creation']?.toString() ?? ''),
      dateModification: DateTime.tryParse(json['date_modification']?.toString() ?? ''),
      equipements: (json['equipements'] as List<dynamic>? ?? [])
          .map((e) => Equipement.fromJson(e as Map<String, dynamic>))
          .toList(),
      medias: ((json['medias'] as List<dynamic>? ?? [])
              .map((m) => BienMedia.fromJson(m as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.ordre.compareTo(b.ordre))),
      indisponibilites: (json['indisponibilites'] as List<dynamic>? ?? [])
          .map((i) => Indisponibilite.fromJson(i as Map<String, dynamic>))
          .toList(),
      gestionnaires: (json['gestionnaires'] as List<dynamic>? ?? [])
          .map((g) => Gestionnaire.fromJson(g as Map<String, dynamic>))
          .toList(),
      detailCeremonie: json['detail_ceremonie'] as Map<String, dynamic>?,
      detailTerrain: json['detail_terrain'] as Map<String, dynamic>?,
    );
  }

  String titreFor(String language) =>
      language == 'ar' && titreAr.isNotEmpty ? titreAr : titre;

  String? descriptionFor(String language) =>
      language == 'ar' && (descriptionAr?.isNotEmpty ?? false)
          ? descriptionAr
          : description;

  /// Adresse lisible pour l'affichage : préfère `adresse_complete` (renvoyée
  /// par le détail) à la concaténation quartier/ville (qui nécessite de
  /// résoudre leurs noms séparément via [BienService.fetchVilles]).
  String? adresseFor(String language) {
    final ar = adresseCompleteAr;
    if (language == 'ar' && ar != null && ar.isNotEmpty) return ar;
    final fr = adresseComplete;
    if (fr != null && fr.isNotEmpty) return fr;
    return null;
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
