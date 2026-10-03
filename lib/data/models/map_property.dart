import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:akarina/data/services/geo_service.dart';

/// Vue normalisée d'un bien pour la carte et les filtres, construite à partir
/// d'un item de liste de l'API https://admin-akarina.akarina.shop/api/biens/.
class MapProperty {
  final int id;
  final String reference;
  final String adresse;
  final String ville;

  /// Nom du quartier (l'API ne renvoie pas de notion de "région").
  final String region;
  final String description;

  /// `vendre` ou `alouer`.
  final String typeOperation;

  /// `appartement`, `duplexe`, `ceremonie`, `terrain` ou `commercial`.
  final String categorie;

  final double? montant;
  final double? loyerMensuel;
  final String periode;

  final int chambres;
  final int sallesDeBain;
  final bool meuble;

  final bool available;

  final String? imageUrl;

  final LatLng? position;

  /// `true` quand la position vient des vraies coordonnées de l'API, `false`
  /// quand elle est déduite du quartier (précision approximative).
  final bool positionExacte;

  final Map<String, dynamic> raw;

  const MapProperty({
    required this.id,
    required this.reference,
    required this.adresse,
    required this.ville,
    required this.region,
    required this.description,
    required this.typeOperation,
    required this.categorie,
    required this.montant,
    required this.loyerMensuel,
    required this.periode,
    required this.chambres,
    required this.sallesDeBain,
    required this.meuble,
    required this.available,
    required this.imageUrl,
    required this.position,
    required this.positionExacte,
    required this.raw,
  });

  bool get isVente => typeOperation == 'vendre';
  bool get isNuitee => periode.toLowerCase().contains('nuit');

  /// Prix servant aux filtres et au tri, quelle que soit l'opération.
  double? get prix => isVente ? montant : loyerMensuel;

  bool get hasMedia => imageUrl != null;

  String? get mediaUrl => (imageUrl != null && imageUrl!.isNotEmpty) ? imageUrl : null;

  bool get isVideoPreview => false;

  static MapProperty fromJson(Map<String, dynamic> json) {
    final villeJson = json['ville'];
    final quartierJson = json['quartier'];
    final ville = villeJson is Map ? _asString(villeJson['nom']) ?? '' : '';
    final quartier = quartierJson is Map ? _asString(quartierJson['nom']) ?? '' : '';

    final id = _asInt(json['id']) ?? 0;
    final reference = _asString(json['reference']) ?? '';
    final adresse = _asString(json['titre']) ?? '';

    final typeTransaction = _asString(json['type_transaction']) ?? 'location';
    final typeOperation = typeTransaction == 'vente' ? 'vendre' : 'alouer';

    final unitePrix = _asString(json['unite_prix']) ?? 'mois';
    final periode = switch (unitePrix) {
      'jour' => 'par Nuit',
      'mois' => 'Mensuelle',
      _ => unitePrix,
    };

    final prixValue = _asDouble(json['prix']);
    final estVente = typeOperation == 'vendre';

    final typeBien = _asString(json['type_bien']) ?? '';
    final categorie = switch (typeBien) {
      'appartement' => 'Appartement',
      'duplexe' => 'Duplex',
      'ceremonie' => 'Maisonceremonie',
      'terrain' => 'Terrain',
      'commercial' => 'Commercial',
      _ => typeBien,
    };

    final latitude = _asDouble(json['latitude']);
    final longitude = _asDouble(json['longitude']);
    final positionExacte = latitude != null && longitude != null;

    return MapProperty(
      id: id,
      reference: reference,
      adresse: adresse,
      ville: ville,
      region: quartier,
      description: '',
      typeOperation: typeOperation,
      categorie: categorie,
      montant: estVente ? prixValue : null,
      loyerMensuel: estVente ? null : prixValue,
      periode: periode,
      chambres: _asInt(json['nb_chambres']) ?? 0,
      sallesDeBain: _asInt(json['nb_salles_bain']) ?? 0,
      meuble: json['meuble'] == true,
      available: json['vendu'] != true,
      imageUrl: _asString(json['photo_principale']),
      position: positionExacte
          ? LatLng(latitude, longitude)
          : GeoService().resolveSync(
              x: null,
              y: null,
              ville: ville,
              region: quartier,
              adresse: adresse,
              seed: id,
            ),
      positionExacte: positionExacte,
      raw: json,
    );
  }

  MapProperty copyWithPosition(LatLng position) => MapProperty(
        id: id,
        reference: reference,
        adresse: adresse,
        ville: ville,
        region: region,
        description: description,
        typeOperation: typeOperation,
        categorie: categorie,
        montant: montant,
        loyerMensuel: loyerMensuel,
        periode: periode,
        chambres: chambres,
        sallesDeBain: sallesDeBain,
        meuble: meuble,
        available: available,
        imageUrl: imageUrl,
        position: position,
        positionExacte: positionExacte,
        raw: raw,
      );

  /// Étiquette compacte affichée sur le marqueur, ex. « 70K » ou « 3,6M ».
  String get prixCourt {
    final value = prix;
    if (value == null || value <= 0) return '—';
    if (value >= 1000000) {
      final millions = value / 1000000;
      final texte = millions >= 10
          ? millions.round().toString()
          : millions.toStringAsFixed(1).replaceAll('.', ',').replaceAll(',0', '');
      return '${texte}M';
    }
    if (value >= 1000) {
      final milliers = value / 1000;
      final texte = milliers >= 10
          ? milliers.round().toString()
          : milliers.toStringAsFixed(1).replaceAll('.', ',').replaceAll(',0', '');
      return '${texte}K';
    }
    return value.round().toString();
  }

  /// Prix complet, ex. « 70 000 MRU/Mensuelle ». [devise] est fourni par
  /// l'appelant (traduit via `getTranslated(context, 'MRU')`) car ce modèle
  /// n'a pas de BuildContext pour se traduire lui-même.
  String prixComplet({String? suffixePeriode, String devise = 'MRU'}) {
    final value = prix;
    if (value == null || value <= 0) return '';
    final formatted = _formatMillier(value);
    if (isVente) return '$formatted $devise';
    return '$formatted $devise/${suffixePeriode ?? periode}';
  }

  static String _formatMillier(double value) {
    final entier = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(entier[i]);
    }
    return buffer.toString();
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.').trim());
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ??
        double.tryParse(value.toString().trim())?.toInt();
  }
}
