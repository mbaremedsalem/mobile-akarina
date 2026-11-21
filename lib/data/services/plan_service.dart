import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:akarina/data/models/bien.dart';

/// Données du "Plan de terrain" : exactement les mêmes endpoints que la page
/// PlanTerrainPage du site (agharina-frontend-client), pour que l'app affiche
/// le même plan que celui uploadé côté admin (lots + zones).
class PlanService {
  static const String baseUrl = 'https://akarina-admin.duckdns.org/api';
  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  /// Charge toutes les pages d'un endpoint paginé DRF. La 1re page donne le
  /// `count`, les suivantes sont ensuite chargées en parallèle.
  Future<List<Map<String, dynamic>>> _list(String endpoint, [Map<String, String>? params]) async {
    Future<Map<String, dynamic>> getPage(int page) async {
      final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: {
        ...?params,
        if (page > 1) 'page': '$page',
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode != 200) {
        throw Exception('Erreur $endpoint: ${res.statusCode}');
      }
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return {'results': data, 'count': data.length};
      return data as Map<String, dynamic>;
    }

    final first = await getPage(1);
    final results = <Map<String, dynamic>>[
      ...(first['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    ];
    final count = (first['count'] as num?)?.toInt() ?? results.length;
    if (first['next'] != null && results.isNotEmpty && count > results.length) {
      final pages = (count / results.length).ceil();
      final rest = await Future.wait([for (var p = 2; p <= pages; p++) getPage(p)]);
      for (final page in rest) {
        results.addAll((page['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      }
    }
    return results;
  }

  Future<PlanData> fetchAll() async {
    final responses = await Future.wait([
      _list('villes/'),
      _list('quartiers/'),
      _list('plans-quartier/'),
      _list('biens/', {'type_bien': 'terrain', 'actif': 'true'}),
      _list('biens/', {'type_bien': 'espace', 'actif': 'true'}),
      _list('zones-plan/'),
    ]);

    final villes = responses[0].map(Ville.fromJson).toList();
    final quartiers = responses[1].map(Quartier.fromJson).toList();
    final plans = responses[2].map(PlanQuartier.fromJson).whereType<PlanQuartier>().toList();
    final lots = responses[3].map(PlanLot.fromJson).whereType<PlanLot>().toList();
    final espaces = <int, String>{
      for (final e in responses[4])
        if (e['id'] is num && e['reference'] != null) (e['id'] as num).toInt(): e['reference'].toString(),
    };
    final zones = responses[5].map(PlanZone.fromJson).whereType<PlanZone>().toList();

    return PlanData(
      villes: villes,
      quartiers: quartiers,
      plans: plans,
      lots: lots,
      zones: zones,
      espaceReferenceById: espaces,
    );
  }
}

class PlanData {
  final List<Ville> villes;
  final List<Quartier> quartiers;
  final List<PlanQuartier> plans;
  final List<PlanLot> lots;
  final List<PlanZone> zones;

  /// id d'un bien "espace" -> sa référence (pour ouvrir la fiche d'une zone publiée).
  final Map<int, String> espaceReferenceById;

  const PlanData({
    required this.villes,
    required this.quartiers,
    required this.plans,
    required this.lots,
    required this.zones,
    required this.espaceReferenceById,
  });
}

double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');
String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

LatLng polygonCentroid(List<LatLng> points) {
  final lat = points.fold<double>(0, (s, p) => s + p.latitude) / points.length;
  final lng = points.fold<double>(0, (s, p) => s + p.longitude) / points.length;
  return LatLng(lat, lng);
}

/// Plan de lotissement positionné sur la carte (image uploadée côté admin).
class PlanQuartier {
  final int id;
  final int? quartierId;
  final bool actif;
  final double centreLat;
  final double centreLng;
  final double largeurM;
  final double hauteurM;
  final double rotationDeg;

  const PlanQuartier({
    required this.id,
    required this.quartierId,
    required this.actif,
    required this.centreLat,
    required this.centreLng,
    required this.largeurM,
    required this.hauteurM,
    required this.rotationDeg,
  });

  static PlanQuartier? fromJson(Map<String, dynamic> json) {
    final id = _i(json['id']);
    final lat = _d(json['centre_latitude']);
    final lng = _d(json['centre_longitude']);
    final w = _d(json['largeur_m']);
    final h = _d(json['hauteur_m']);
    if (id == null || lat == null || lng == null || w == null || h == null) return null;
    return PlanQuartier(
      id: id,
      quartierId: _i(json['quartier']),
      actif: json['actif'] == true,
      centreLat: lat,
      centreLng: lng,
      largeurM: w,
      hauteurM: h,
      rotationDeg: _d(json['rotation_deg']) ?? 0,
    );
  }

  /// Point local fractionnaire (0..1, coin haut-gauche de l'image) -> lat/lng.
  /// Même transformation que localPointToLatLng() du site / de l'éditeur admin.
  LatLng localToLatLng(double fx, double fy) {
    final dxLocal = (fx - 0.5) * largeurM;
    final dyLocal = (fy - 0.5) * hauteurM;
    final rad = rotationDeg * math.pi / 180;
    final dxScreen = dxLocal * math.cos(rad) - dyLocal * math.sin(rad);
    final dyScreen = dxLocal * math.sin(rad) + dyLocal * math.cos(rad);
    return LatLng(
      centreLat - dyScreen / 111320,
      centreLng + dxScreen / (111320 * math.cos(centreLat * math.pi / 180)),
    );
  }
}

/// Terrain (bien type_bien=terrain) dessiné par son polygone.
class PlanLot {
  final String reference;
  final String titre;
  final String titreAr;
  final double? prix;
  final String uniteprix;
  final bool vendu;
  final String? statutDisponibilite;
  final int? quartierId;
  final String? quartierNom;
  final String? quartierNomAr;
  final String? numeroLot;
  final String? superficieM2;
  final String? longueurM;
  final String? largeurM;
  final String? baseM;
  final String? hauteurM;
  final String? hypotenuseM;
  final String? moughataa;
  final String? adresse;
  final List<LatLng> polygone;
  final LatLng centre;

  const PlanLot({
    required this.reference,
    required this.titre,
    required this.titreAr,
    required this.prix,
    required this.uniteprix,
    required this.vendu,
    required this.statutDisponibilite,
    required this.quartierId,
    required this.quartierNom,
    required this.quartierNomAr,
    required this.numeroLot,
    required this.superficieM2,
    required this.longueurM,
    required this.largeurM,
    required this.baseM,
    required this.hauteurM,
    required this.hypotenuseM,
    required this.moughataa,
    required this.adresse,
    required this.polygone,
    required this.centre,
  });

  static PlanLot? fromJson(Map<String, dynamic> json) {
    final detail = json['detail_terrain'];
    if (detail is! Map) return null;
    final raw = detail['polygone'];
    if (raw is! List || raw.length < 3) return null;
    final points = <LatLng>[];
    for (final p in raw) {
      if (p is Map) {
        final lat = _d(p['lat']);
        final lng = _d(p['lng']);
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    if (points.length < 3) return null;

    final q = json['quartier'];
    return PlanLot(
      reference: json['reference']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      titreAr: json['titre_ar']?.toString() ?? '',
      prix: _d(json['prix']),
      uniteprix: json['unite_prix']?.toString() ?? '',
      vendu: json['vendu'] == true,
      statutDisponibilite: _s(json['statut_disponibilite']),
      quartierId: q is Map ? _i(q['id']) : _i(q),
      quartierNom: q is Map ? _s(q['nom']) : null,
      quartierNomAr: q is Map ? _s(q['nom_ar']) : null,
      numeroLot: _s(detail['numero_lot']),
      superficieM2: _s(detail['superficie_m2']),
      longueurM: _s(detail['longueur_m']),
      largeurM: _s(detail['largeur_m']),
      baseM: _s(detail['base_m']),
      hauteurM: _s(detail['hauteur_m']),
      hypotenuseM: _s(detail['hypotenuse_m']),
      moughataa: _s(detail['moughataa']),
      adresse: _s(json['adresse_complete']),
      polygone: points,
      centre: polygonCentroid(points),
    );
  }

  /// `disponible`, `attribue` ou `vendu` (même règle que statutLot() du site).
  String get statut {
    if (vendu) return 'vendu';
    if (statutDisponibilite == 'attribue') return 'attribue';
    return 'disponible';
  }

  String titreFor(String language) => language == 'ar' && titreAr.isNotEmpty ? titreAr : titre;
}

/// Zone non vendable du plan (espace vert, mosquée...), en coordonnées locales.
class PlanZone {
  final int id;
  final int planId;
  final String nom;
  final String typeZone;
  final String? moughataa;
  final String? adresse;
  final String? superficieM2;
  final String? longueurM;
  final String? largeurM;
  final int? bienId;
  final List<({double x, double y})> polygoneLocal;

  const PlanZone({
    required this.id,
    required this.planId,
    required this.nom,
    required this.typeZone,
    required this.moughataa,
    required this.adresse,
    required this.superficieM2,
    required this.longueurM,
    required this.largeurM,
    required this.bienId,
    required this.polygoneLocal,
  });

  static PlanZone? fromJson(Map<String, dynamic> json) {
    final id = _i(json['id']);
    final planId = _i(json['plan']);
    final raw = json['polygone_local'];
    if (id == null || planId == null || raw is! List || raw.length < 3) return null;
    final points = <({double x, double y})>[];
    for (final p in raw) {
      if (p is Map) {
        final x = _d(p['x']);
        final y = _d(p['y']);
        if (x != null && y != null) points.add((x: x, y: y));
      }
    }
    if (points.length < 3) return null;
    return PlanZone(
      id: id,
      planId: planId,
      nom: json['nom']?.toString() ?? '',
      typeZone: json['type_zone']?.toString() ?? 'autre',
      moughataa: _s(json['moughataa']),
      adresse: _s(json['adresse']),
      superficieM2: _s(json['superficie_m2']),
      longueurM: _s(json['longueur_m']),
      largeurM: _s(json['largeur_m']),
      bienId: _i(json['bien']),
      polygoneLocal: points,
    );
  }
}
