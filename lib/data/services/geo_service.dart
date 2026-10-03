import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Résout la position d'un bien immobilier sur la carte.
///
/// L'API `akareena` expose bien les champs `x` (longitude) et `y` (latitude),
/// mais ils valent `null` pour la totalité des biens actuellement publiés.
/// La résolution se fait donc en cascade :
///
///   1. `x` / `y` renvoyés par l'API — dès que le backend les renseigne, ils
///      priment sur tout le reste ;
///   2. la table des points de repère (`region`) de Nouakchott ;
///   3. la table des moughataas (`ville`) ;
///   4. l'API Google Geocoding, dont le résultat est mis en cache sur
///      l'appareil (elle n'est pas encore activée sur le projet Cloud, l'appel
///      échoue alors silencieusement et on retombe sur les niveaux 2 et 3).
///
/// Les niveaux 2 et 3 donnent une précision au quartier, pas à la parcelle.
class GeoService {
  GeoService._internal();
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;

  /// Centre de Nouakchott, utilisé comme position initiale de la caméra.
  static const LatLng nouakchott = LatLng(18.0900, -15.9750);

  static const String _geocodeApiKey = 'AIzaSyCcTubNsHkaESRHsEh9Y2h11sYpWIM1shU';
  static const String _cacheKey = 'geo_cache_v1';

  final _storage = const FlutterSecureStorage();
  final Map<String, LatLng> _remoteCache = {};
  final Set<String> _failedLookups = {};
  bool _cacheLoaded = false;

  /// Moughataas et localités de Nouakchott.
  static const Map<String, LatLng> _villes = {
    'tevraghzeina': LatLng(18.0980, -15.9820),
    'tevraghzeinamauricentre': LatLng(18.0955, -15.9760),
    'ksar': LatLng(18.0870, -15.9540),
    'teyarett': LatLng(18.1180, -15.9700),
    'chahrazad': LatLng(18.1180, -15.9700),
    'darnaim': LatLng(18.1300, -15.9350),
    'aintalh': LatLng(18.1420, -15.9560),
    'sebkha': LatLng(18.0730, -15.9860),
    'arafat': LatLng(18.0530, -15.9430),
    'elmina': LatLng(18.0600, -15.9700),
    'riyad': LatLng(18.0100, -15.8900),
    'toujounine': LatLng(18.0900, -15.9080),
    'nouakchott': nouakchott,
    'nouadhibou': LatLng(20.9310, -17.0350),
    'rosso': LatLng(16.5138, -15.8050),
    'kiffa': LatLng(16.6200, -11.4050),
    'nema': LatLng(16.6170, -7.2560),
    'atar': LatLng(20.5170, -13.0490),
    'zouerate': LatLng(22.7350, -12.4730),
    'kaedi': LatLng(16.1500, -13.5060),
  };

  /// Points de repère utilisés comme `region` par les annonces existantes.
  /// Précision approximative : quartier / carrefour.
  static const Map<String, LatLng> _landmarks = {
    // --- Tevragh-Zeina ---
    'complexecommercial': LatLng(18.0955, -15.9760),
    'stadeolympique': LatLng(18.0937, -15.9808),
    'ambassadechine': LatLng(18.1010, -15.9880),
    'lambassadedesetatsunis': LatLng(18.1120, -15.9880),
    'ambassadedesetatsunis': LatLng(18.1120, -15.9880),
    'laresidencedelambassadeurduqatar': LatLng(18.1065, -15.9905),
    'ministeredesaffairesetrangeres': LatLng(18.0925, -15.9755),
    'ministeredelhabitat': LatLng(18.0940, -15.9740),
    'marchedesfemmes': LatLng(18.1040, -15.9840),
    'sahraoui': LatLng(18.1090, -15.9930),
    'citeplage': LatLng(18.1030, -16.0010),
    'djambour': LatLng(18.1000, -15.9950),
    'charmcheikh': LatLng(18.1010, -15.9930),
    'medinatv': LatLng(18.1050, -15.9760),
    'bigmarket': LatLng(18.0990, -15.9800),
    'carafourzeitouna': LatLng(18.0960, -15.9880),
    'zeitouna': LatLng(18.0960, -15.9880),
    'centreemetteur': LatLng(18.1150, -15.9800),
    'centredecardiologie': LatLng(18.0900, -15.9730),
    'hotelaziza': LatLng(18.0930, -15.9790),
    'pharmacieelysee': LatLng(18.0960, -15.9820),
    'avenuemoktaroulddaddah': LatLng(18.0880, -15.9700),
    'laroutedenouadhibou': LatLng(18.1080, -15.9900),
    'routedenouadhibou': LatLng(18.1080, -15.9900),
    'attaquelkheir1': LatLng(18.1005, -15.9855),
    'attaquelkheir': LatLng(18.1005, -15.9855),
    'elvowz': LatLng(18.1045, -15.9885),
    'maisontata': LatLng(18.0975, -15.9835),
    'secteur3': LatLng(18.0965, -15.9845),
    'secteur4': LatLng(18.0995, -15.9870),
    'secteur5': LatLng(18.1025, -15.9890),
    'secteur6': LatLng(18.1055, -15.9910),
    'secteur10': LatLng(18.1085, -15.9860),
    'extfnordsecteur10': LatLng(18.1085, -15.9860),
    'extentensionfnordsecteur': LatLng(18.1070, -15.9845),
    'notextmodmext': LatLng(18.1000, -15.9820),
    'tevraghzeina': LatLng(18.0980, -15.9820),

    // --- Ksar ---
    'mosqueeverte': LatLng(18.0895, -15.9575),
    'carrefourwelmah': LatLng(18.0850, -15.9530),
    'carrefourcinquiememosquee': LatLng(18.0920, -15.9600),

    // --- Teyarett ---
    'pharmaciecentrale': LatLng(18.1160, -15.9660),
    'mosqueeoumsalam': LatLng(18.1200, -15.9720),

    // --- Dar Naïm ---
    'stationtotaldarnaim': LatLng(18.1290, -15.9420),
    'stationstaroildarnaim': LatLng(18.1330, -15.9380),
    'virageelkhteira': LatLng(18.1250, -15.9400),

    // --- Aïn Talh ---
    'epicerieibadrahman3': LatLng(18.1400, -15.9500),
    'epicerieibadrahman': LatLng(18.1400, -15.9500),
    'guidrontaintane': LatLng(18.1380, -15.9520),
  };

  /// Normalise un libellé : minuscules, sans accents, sans ponctuation.
  static String normalize(String? value) {
    if (value == null) return '';
    var s = value.toLowerCase().trim();
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
      '’': '', '\'': '',
    };
    accents.forEach((from, to) => s = s.replaceAll(from, to));
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Convertit une valeur d'API (num, String, null) en double.
  static double? parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().replaceAll(',', '.').trim();
    if (cleaned.isEmpty || cleaned == 'null') return null;
    return double.tryParse(cleaned);
  }

  /// Résolution hors ligne (niveaux 1 à 3), sans appel réseau.
  ///
  /// [seed] sert à écarter légèrement les biens partageant le même repère pour
  /// qu'ils ne se superposent pas exactement sur la carte. Il n'est pas
  /// appliqué aux coordonnées réelles renvoyées par l'API.
  LatLng? resolveSync({
    dynamic x,
    dynamic y,
    String? ville,
    String? region,
    String? adresse,
    int seed = 0,
  }) {
    final lng = parseCoordinate(x);
    final lat = parseCoordinate(y);
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      return LatLng(lat, lng);
    }

    for (final candidate in [region, adresse]) {
      final key = normalize(candidate);
      if (key.isEmpty) continue;
      final hit = _landmarks[key] ?? _remoteCache[key];
      if (hit != null) return _scatter(hit, seed, 0.0022);
    }

    final villeKey = normalize(ville);
    if (villeKey.isNotEmpty) {
      final hit = _villes[villeKey] ?? _remoteCache[villeKey];
      if (hit != null) return _scatter(hit, seed, 0.0060);
    }

    return null;
  }

  /// Résolution complète : niveaux 1 à 3 puis Google Geocoding si nécessaire.
  Future<LatLng?> resolve({
    dynamic x,
    dynamic y,
    String? ville,
    String? region,
    String? adresse,
    int seed = 0,
  }) async {
    final local = resolveSync(
      x: x,
      y: y,
      ville: ville,
      region: region,
      adresse: adresse,
      seed: seed,
    );
    if (local != null) return local;

    final query = [region, adresse, ville]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(', ');
    if (query.isEmpty) return null;

    final geocoded = await _geocode(query, cacheKey: normalize(region ?? ville));
    if (geocoded == null) return null;
    return _scatter(geocoded, seed, 0.0012);
  }

  /// Décale une position d'au plus [spread] degrés, de façon déterministe :
  /// un même bien retombe toujours au même endroit d'une session à l'autre.
  LatLng _scatter(LatLng base, int seed, double spread) {
    if (seed == 0) return base;
    final angle = (seed * 137.508) % 360 * math.pi / 180;
    final radius = spread * (0.35 + ((seed * 2654435761) % 1000) / 1000 * 0.65);
    return LatLng(
      base.latitude + radius * math.sin(angle),
      base.longitude + radius * math.cos(angle) / math.cos(base.latitude * math.pi / 180),
    );
  }

  Future<LatLng?> _geocode(String query, {String? cacheKey}) async {
    final key = (cacheKey == null || cacheKey.isEmpty) ? normalize(query) : cacheKey;

    await _loadCache();
    if (_remoteCache.containsKey(key)) return _remoteCache[key];
    if (_failedLookups.contains(key)) return null;

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': '$query, Mauritanie',
        'region': 'mr',
        'key': _geocodeApiKey,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        _failedLookups.add(key);
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (body['status'] != 'OK' || results == null || results.isEmpty) {
        // Notamment REQUEST_DENIED tant que l'API Geocoding n'est pas activée.
        _failedLookups.add(key);
        return null;
      }

      final location = results.first['geometry']?['location'];
      final lat = parseCoordinate(location?['lat']);
      final lng = parseCoordinate(location?['lng']);
      if (lat == null || lng == null) {
        _failedLookups.add(key);
        return null;
      }

      final position = LatLng(lat, lng);
      _remoteCache[key] = position;
      await _persistCache();
      return position;
    } catch (_) {
      _failedLookups.add(key);
      return null;
    }
  }

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final raw = await _storage.read(key: _cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        final lat = parseCoordinate(value['lat']);
        final lng = parseCoordinate(value['lng']);
        if (lat != null && lng != null) _remoteCache[key] = LatLng(lat, lng);
      });
    } catch (_) {
      // Cache illisible : on repart d'un cache vide.
    }
  }

  Future<void> _persistCache() async {
    try {
      final payload = _remoteCache.map(
        (key, value) => MapEntry(key, {'lat': value.latitude, 'lng': value.longitude}),
      );
      await _storage.write(key: _cacheKey, value: json.encode(payload));
    } catch (_) {
      // L'échec d'écriture du cache ne doit pas casser la carte.
    }
  }
}
