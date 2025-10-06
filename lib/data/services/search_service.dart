import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  static const String baseUrl = 'https://akarina.online/akareena';

  // Recherche de propriétés
  Future<List<dynamic>> searchProperties({
    required String ville,
    String? region,
    String? adresse,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search/').replace(queryParameters: {
        'nom_ville': ville,
        if (region != null && region.isNotEmpty) 'region': region,
        if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return List<dynamic>.from(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de recherche: $e');
    }
  }

  // Récupérer les villes
  Future<List<Map<String, dynamic>>> getCities() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/villes/"),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          json.decode(utf8.decode(response.bodyBytes)),
        );
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur chargement villes: $e');
    }
  }

  // Récupérer les régions
  Future<List<Map<String, dynamic>>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/regions/"),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          json.decode(utf8.decode(response.bodyBytes)),
        );
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur chargement régions: $e');
    }
  }
}