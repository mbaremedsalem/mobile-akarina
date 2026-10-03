import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akarina/data/models/offre.dart';

/// Client pour l'API https://admin-akarina.akarina.shop/api/offres/.
class OffreService {
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

  Future<List<Offre>> fetchOffres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/offres/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du chargement des offres: ${response.statusCode}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes));
    final results = data is Map<String, dynamic>
        ? (data['results'] as List<dynamic>? ?? [])
        : <dynamic>[];
    return results
        .map((o) => Offre.fromJson(o as Map<String, dynamic>))
        .where((o) => o.actif)
        .toList();
  }
}
