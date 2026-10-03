import 'dart:convert';

import 'package:http/http.dart' as http;

/// Version courte d'un bien, telle que renvoyée par GET /api/biens/ (liste).
class BienResume {
  final int id;
  final String reference;
  final String titre;
  final String titreAr;
  final String typeBien;
  final String typeTransaction;
  final double? prix;
  final String unitePrix;
  final bool meuble;
  final int? nbChambres;
  final int? nbSallesBain;
  final String villeNom;
  final String villeNomAr;
  final String quartierNom;
  final String quartierNomAr;
  final String? photoPrincipale;
  final bool vendu;

  const BienResume({
    required this.id,
    required this.reference,
    required this.titre,
    required this.titreAr,
    required this.typeBien,
    required this.typeTransaction,
    required this.prix,
    required this.unitePrix,
    required this.meuble,
    required this.nbChambres,
    required this.nbSallesBain,
    required this.villeNom,
    required this.villeNomAr,
    required this.quartierNom,
    required this.quartierNomAr,
    required this.photoPrincipale,
    required this.vendu,
  });

  static int? _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
  static String _str(dynamic v) => (v ?? '').toString().trim();

  factory BienResume.fromJson(Map<String, dynamic> json) {
    final ville = json['ville'] is Map<String, dynamic> ? json['ville'] as Map<String, dynamic> : const {};
    final quartier =
        json['quartier'] is Map<String, dynamic> ? json['quartier'] as Map<String, dynamic> : const {};
    final photo = _str(json['photo_principale']);

    return BienResume(
      id: _int(json['id']) ?? 0,
      reference: _str(json['reference']),
      titre: _str(json['titre']),
      titreAr: _str(json['titre_ar']),
      typeBien: _str(json['type_bien']),
      typeTransaction: _str(json['type_transaction']),
      prix: double.tryParse(_str(json['prix'])),
      unitePrix: _str(json['unite_prix']),
      meuble: json['meuble'] == true,
      nbChambres: _int(json['nb_chambres']),
      nbSallesBain: _int(json['nb_salles_bain']),
      villeNom: _str(ville['nom']),
      villeNomAr: _str(ville['nom_ar']),
      quartierNom: _str(quartier['nom']),
      quartierNomAr: _str(quartier['nom_ar']),
      photoPrincipale: photo.isEmpty ? null : photo,
      vendu: json['vendu'] == true,
    );
  }

  String titreFor(bool arabe) => arabe && titreAr.isNotEmpty ? titreAr : titre;

  String lieuFor(bool arabe) {
    final q = arabe && quartierNomAr.isNotEmpty ? quartierNomAr : quartierNom;
    final v = arabe && villeNomAr.isNotEmpty ? villeNomAr : villeNom;
    return [q, v].where((e) => e.isNotEmpty).join(', ');
  }
}

class BiensSimilairesService {
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

  Future<List<BienResume>> rechercher(Map<String, String> filtres) async {
    final url = Uri.parse('$baseUrl/biens/').replace(queryParameters: filtres);
    final res = await http
        .get(url, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Biens : HTTP ${res.statusCode}');

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final List<dynamic> results =
        data is List ? data : (data is Map<String, dynamic> ? (data['results'] as List?) ?? const [] : const []);
    return results.whereType<Map<String, dynamic>>().map(BienResume.fromJson).toList();
  }

  /// Biens proches du bien affiché : même transaction, même ville/quartier,
  /// même nombre de chambres, même ameublement, prix à ±50 %.
  /// Si trop peu de résultats, on élargit à la même transaction dans la même ville.
  Future<List<BienResume>> similairesA({
    required Object excludeId,
    required String typeTransaction,
    Object? villeId,
    Object? quartierId,
    bool? meuble,
    int? nbChambres,
    double? prix,
    int limite = 8,
  }) async {
    final base = <String, String>{
      'type_transaction': typeTransaction,
      if (villeId != null) 'ville': '$villeId',
      'ordering': 'prix',
    };

    final strict = <String, String>{
      ...base,
      if (quartierId != null) 'quartier': '$quartierId',
      if (meuble != null) 'meuble': meuble ? 'true' : 'false',
      if (nbChambres != null && nbChambres > 0) 'nb_chambres': '$nbChambres',
      if (prix != null && prix > 0) 'prix_min': '${(prix * 0.5).round()}',
      if (prix != null && prix > 0) 'prix_max': '${(prix * 1.5).round()}',
    };

    bool garder(BienResume r) => '${r.id}' != '$excludeId' && !r.vendu;

    final resultats = (await rechercher(strict)).where(garder).toList();

    if (resultats.length < 3) {
      final dejaVus = resultats.map((r) => r.id).toSet();
      final elargis = (await rechercher(base)).where((r) => garder(r) && !dejaVus.contains(r.id));
      resultats.addAll(elargis);
    }

    return resultats.take(limite).toList();
  }
}