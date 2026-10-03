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

/// Client pour l'API https://admin-akarina.akarina.shop/api/.
class BienService {
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

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
  }) async {
    final uri = pageUrl != null
        ? Uri.parse(pageUrl)
        : Uri.parse('$baseUrl/biens/').replace(queryParameters: {
            if (typeBien != null) 'type_bien': typeBien,
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
