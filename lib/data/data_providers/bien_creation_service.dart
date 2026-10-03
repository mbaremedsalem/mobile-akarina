import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:akarina/data/models/bien.dart';

/// Création de biens et ajout de médias sur
/// https://admin-akarina.akarina.shop/api/ — réservé aux gestionnaires
/// (`is_staff: true`), jeton DRF "Token <admin_token>".
class BienCreationService {
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

  Future<List<Equipement>> fetchEquipements(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipements/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => Equipement.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Crée le bien et retourne son id.
  Future<int> creerBien(String token, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/biens/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final id = data['id'];
    if (id is int) return id;
    throw Exception('Réponse inattendue : id manquant');
  }

  Future<void> ajouterMedia(
    String token, {
    required int bienId,
    required String typeMedia,
    String? legende,
    required File fichier,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/medias/'));
    request.headers['Authorization'] = 'Token $token';
    request.fields['bien'] = '$bienId';
    request.fields['type_media'] = typeMedia;
    if (legende != null && legende.isNotEmpty) request.fields['legende'] = legende;
    request.files.add(await http.MultipartFile.fromPath('fichier', fichier.path));

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception('Erreur ${response.statusCode}: $body');
    }
  }
}
