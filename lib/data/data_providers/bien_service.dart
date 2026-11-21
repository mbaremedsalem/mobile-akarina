import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akarina/data/models/bien.dart';

class BienPage {
  final int count;
  final String? next;
  final String? previous;
  final List<Bien> results;

  const BienPage({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}

/// Client pour l'API https://akarina-admin.duckdns.org/api/.
class BienService {
  static const String baseUrl = 'https://akarina-admin.duckdns.org/api';

  Future<List<Ville>> fetchVilles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/villes/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du chargement des villes: ${response.statusCode}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes));
    final results = data is Map<String, dynamic>
        ? (data['results'] as List<dynamic>? ?? [])
        : <dynamic>[];
    return results.map((v) => Ville.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<BienPage> fetchBiens({
    String? typeBien,
    String? typeTransaction,
    int? villeId,
    int? quartierId,
    bool? meuble,
    String? unitePrix,
    int? nbChambres,
    num? prixMin,
    num? prixMax,
    DateTime? disponibleDu,
    DateTime? disponibleAu,
    String? search,
    String? ordering,
    int? pageSize,
    String? pageUrl,
    bool exclureTerrainsPlan = false,
  }) async {
    // Page suivante d'une recherche multi-types (voir plus bas).
    if (pageUrl != null && pageUrl.startsWith(_kCurseurHorsPlan)) {
      final urls = (json.decode(utf8.decode(base64Url.decode(
              pageUrl.substring(_kCurseurHorsPlan.length)))) as Map<String, dynamic>)
          .cast<String, String>();
      return _fusionner(urls, ordering: ordering);
    }

    Uri buildUri(String? type) => Uri.parse('$baseUrl/biens/').replace(queryParameters: {
          if (type != null) 'type_bien': type,
          if (typeTransaction != null) 'type_transaction': typeTransaction,
          if (villeId != null) 'ville': villeId.toString(),
          if (quartierId != null) 'quartier': quartierId.toString(),
          if (meuble != null) 'meuble': meuble.toString(),
          if (unitePrix != null) 'unite_prix': unitePrix,
          if (nbChambres != null) 'nb_chambres': nbChambres.toString(),
          if (prixMin != null) 'prix_min': prixMin.toString(),
          if (prixMax != null) 'prix_max': prixMax.toString(),
          if (disponibleDu != null) 'disponible_du': _formatDate(disponibleDu),
          if (disponibleAu != null) 'disponible_au': _formatDate(disponibleAu),
          if (search != null && search.isNotEmpty) 'search': search,
          if (ordering != null) 'ordering': ordering,
          if (pageSize != null) 'page_size': pageSize.toString(),
        });

    // L'API ne sait pas exclure un type : sans type choisi, on interroge
    // chaque type hors terrain en parallèle et on fusionne les résultats,
    // pour que les terrains du plan (carte) ne noient pas la liste.
    if (exclureTerrainsPlan && typeBien == null && pageUrl == null) {
      return _fusionner(
        {for (final t in _kTypesHorsTerrain) t: buildUri(t).toString()},
        ordering: ordering,
        limite: pageSize,
      );
    }

    final page = await _fetchPage(pageUrl != null ? Uri.parse(pageUrl) : buildUri(typeBien));
    if (!exclureTerrainsPlan) return page;
    final gardes = page.results.where((b) => !_estTerrainPlan(b)).toList();
    return BienPage(
      count: page.count - (page.results.length - gardes.length),
      next: page.next,
      previous: page.previous,
      results: gardes,
    );
  }

  static const _kTypesHorsTerrain = ['appartement', 'duplexe', 'commercial', 'ceremonie'];
  static const _kCurseurHorsPlan = 'horsplan:';

  /// Terrain dessiné sur le plan (carte des lots) : il a un polygone.
  static bool _estTerrainPlan(Bien b) {
    if (b.typeBien != 'terrain') return false;
    final polygone = b.detailTerrain?['polygone'];
    return polygone is List && polygone.length >= 3;
  }

  /// Charge une page par type, fusionne et trie ; `next` encode les pages
  /// suivantes de chaque type dans un curseur composite.
  Future<BienPage> _fusionner(Map<String, String> urlsParType,
      {String? ordering, int? limite}) async {
    final types = urlsParType.keys.toList();
    final pages = await Future.wait(types.map((t) => _fetchPage(Uri.parse(urlsParType[t]!))));

    final results = [for (final p in pages) ...p.results];
    double prix(Bien b) => double.tryParse(b.prix ?? '') ?? 0;
    switch (ordering) {
      case 'prix':
        results.sort((a, b) => prix(a).compareTo(prix(b)));
      case '-prix':
        results.sort((a, b) => prix(b).compareTo(prix(a)));
      case 'date_creation':
        results.sort((a, b) => a.id.compareTo(b.id));
      default: // '-date_creation' ou pas de tri : plus récents d'abord
        results.sort((a, b) => b.id.compareTo(a.id));
    }

    final suivantes = {
      for (var i = 0; i < types.length; i++)
        if (pages[i].next != null) types[i]: pages[i].next!,
    };
    return BienPage(
      count: pages.fold(0, (s, p) => s + p.count),
      next: suivantes.isEmpty
          ? null
          : _kCurseurHorsPlan + base64Url.encode(utf8.encode(json.encode(suivantes))),
      results: limite != null && results.length > limite ? results.sublist(0, limite) : results,
    );
  }

  Future<BienPage> _fetchPage(Uri uri) async {
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du chargement des biens: ${response.statusCode}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return BienPage(
      count: data['count'] as int? ?? 0,
      next: data['next'] as String?,
      previous: data['previous'] as String?,
      results: (data['results'] as List<dynamic>? ?? [])
          .map((b) => Bien.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Bien> fetchBienDetail(String reference) async {
    final response = await http.get(
      Uri.parse('$baseUrl/biens/$reference/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du chargement du bien: ${response.statusCode}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return Bien.fromJson(data);
  }
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
