import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client pour le compte utilisateur sur https://admin-akarina.akarina.shop/api/.
///
/// Backend d'authentification de l'app : jeton simple (DRF
/// TokenAuthentication), pas de refresh — voir LoginCubit.
class AccountService {
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connexion/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) return null;
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return data['token'] as String?;
  }

  /// Inscription (POST /api/inscription/). `codeParrain` est optionnel.
  /// Lève une [Exception] avec un message lisible en cas d'erreur de
  /// validation (ex. nom d'utilisateur déjà pris).
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String telephone,
    required bool estGestionnaire,
    String? codeParrain,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inscription/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'telephone': telephone,
        'est_gestionnaire': estGestionnaire,
        'code_parrain': codeParrain ?? '',
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception(_parseRegisterError(response));
  }

  String _parseRegisterError(http.Response response) {
    try {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is Map) {
        for (final entry in data.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String) return value;
        }
      }
    } catch (_) {}
    return 'Erreur ${response.statusCode}';
  }

  Future<Map<String, dynamic>?> fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profil/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
    );
    if (response.statusCode != 200) return null;
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Mise à jour partielle du profil (ex. {"telephone": ..., "first_name": ...}).
  /// Retourne le profil mis à jour renvoyé par l'API, ou `null` en cas d'échec.
  Future<Map<String, dynamic>?> updateProfile(String token, Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/profil/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(fields),
    );
    if (response.statusCode != 200) return null;
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Solde de points de fidélité + historique des mouvements
  /// (GET /api/mes-points/).
  Future<PointsSummary?> fetchPoints(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mes-points/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
    );
    if (response.statusCode != 200) return null;
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PointsSummary.fromJson(data);
  }
}

class MouvementPoints {
  final int id;
  final String typeMouvement;
  final int points;
  final String description;
  final DateTime? dateCreation;

  const MouvementPoints({
    required this.id,
    required this.typeMouvement,
    required this.points,
    required this.description,
    this.dateCreation,
  });

  factory MouvementPoints.fromJson(Map<String, dynamic> json) => MouvementPoints(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        typeMouvement: json['type_mouvement']?.toString() ?? '',
        points: json['points'] is int ? json['points'] as int : int.tryParse('${json['points']}') ?? 0,
        description: json['description']?.toString() ?? '',
        dateCreation: DateTime.tryParse(json['date_creation']?.toString() ?? ''),
      );

  bool get estGagne => points > 0;
}

class PointsSummary {
  final int soldePoints;
  final List<MouvementPoints> historique;

  const PointsSummary({required this.soldePoints, required this.historique});

  factory PointsSummary.fromJson(Map<String, dynamic> json) => PointsSummary(
        soldePoints: json['solde_points'] is int
            ? json['solde_points'] as int
            : int.tryParse('${json['solde_points']}') ?? 0,
        historique: (json['historique'] as List<dynamic>? ?? [])
            .map((e) => MouvementPoints.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
