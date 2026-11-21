import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:akarina/data/models/bien.dart';

/// Une période pendant laquelle le bien n'est pas disponible
/// (retournée par GET /api/indisponibilites/?bien=<id>).
class PeriodeIndisponibilite {
  final int? id;
  final DateTime debut;
  final DateTime fin;
  final String motif;

  PeriodeIndisponibilite({
    this.id,
    required DateTime debut,
    required DateTime fin,
    this.motif = '',
  })  : debut = DateTime(debut.year, debut.month, debut.day),
        fin = DateTime(fin.year, fin.month, fin.day);

  static PeriodeIndisponibilite? fromJson(Map<String, dynamic> json) {
    final debut = DateTime.tryParse('${json['date_debut'] ?? ''}');
    final fin = DateTime.tryParse('${json['date_fin'] ?? ''}');
    if (debut == null || fin == null) return null;
    return PeriodeIndisponibilite(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      debut: debut,
      fin: fin,
      motif: (json['motif'] ?? '').toString().trim(),
    );
  }

  /// Nombre de jours couverts (bornes incluses).
  int get nbJours => fin.difference(debut).inDays + 1;

  bool contient(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(debut) && !d.isAfter(fin);
  }
}

class IndisponibiliteService {
  static const String baseUrl = 'https://akarina-admin.duckdns.org/api';

  /// Récupère toutes les périodes d'indisponibilité d'un bien,
  /// en suivant la pagination (`next`) si l'API en renvoie plusieurs pages.
  Future<List<PeriodeIndisponibilite>> fetchPourBien(Object bienId) async {
    final periodes = <PeriodeIndisponibilite>[];
    Uri? url = Uri.parse('$baseUrl/indisponibilites/')
        .replace(queryParameters: {'bien': '$bienId'});

    var pages = 0;
    while (url != null && pages < 20) {
      pages++;
      final res = await http
          .get(url, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Indisponibilités : HTTP ${res.statusCode}');
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      List<dynamic> results;
      String? next;
      if (data is List) {
        results = data;
      } else if (data is Map<String, dynamic>) {
        results = (data['results'] as List?) ?? const [];
        next = data['next'] as String?;
      } else {
        results = const [];
      }

      for (final item in results) {
        if (item is Map<String, dynamic>) {
          final p = PeriodeIndisponibilite.fromJson(item);
          if (p != null) periodes.add(p);
        }
      }
      url = (next != null && next.isNotEmpty) ? Uri.parse(next) : null;
    }

    periodes.sort((a, b) => a.debut.compareTo(b.debut));
    return periodes;
  }

  // ------------------------------------------------------------------
  // Gestion du calendrier par le gestionnaire du bien (jeton "admin_token").
  // Le backend vérifie que l'utilisateur connecté est bien gestionnaire du
  // bien (ou staff) et refuse les périodes qui se chevauchent.
  // ------------------------------------------------------------------

  Map<String, String> _headers(String token) => {
        'Authorization': 'Token $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      };

  /// Biens dont l'utilisateur connecté est gestionnaire
  /// (GET /api/biens/?mes_biens=true[&type_bien=...]).
  Future<List<Bien>> fetchMesBiens(String token, {String? typeBien}) async {
    final biens = <Bien>[];
    Uri? url = Uri.parse('$baseUrl/biens/').replace(queryParameters: {
      'mes_biens': 'true',
      if (typeBien != null) 'type_bien': typeBien,
    });
    var pages = 0;
    while (url != null && pages < 20) {
      pages++;
      final res = await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Mes biens : HTTP ${res.statusCode}');
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      List<dynamic> results;
      String? next;
      if (data is List) {
        results = data;
      } else if (data is Map<String, dynamic>) {
        results = (data['results'] as List?) ?? const [];
        next = data['next'] as String?;
      } else {
        results = const [];
      }
      for (final item in results) {
        if (item is Map<String, dynamic>) biens.add(Bien.fromJson(item));
      }
      url = (next != null && next.isNotEmpty) ? Uri.parse(next) : null;
    }
    return biens;
  }

  Future<PeriodeIndisponibilite> creer(
    String token, {
    required int bienId,
    required DateTime debut,
    required DateTime fin,
    String motif = '',
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/indisponibilites/'),
          headers: _headers(token),
          body: jsonEncode({
            'bien': bienId,
            'date_debut': _iso(debut),
            'date_fin': _iso(fin),
            'motif': motif,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _lireReponse(res);
  }

  Future<PeriodeIndisponibilite> modifier(
    String token,
    int id, {
    required DateTime debut,
    required DateTime fin,
    String motif = '',
  }) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/indisponibilites/$id/'),
          headers: _headers(token),
          body: jsonEncode({'date_debut': _iso(debut), 'date_fin': _iso(fin), 'motif': motif}),
        )
        .timeout(const Duration(seconds: 15));
    return _lireReponse(res);
  }

  Future<void> supprimer(String token, int id) async {
    final res = await http
        .delete(Uri.parse('$baseUrl/indisponibilites/$id/'), headers: _headers(token))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(_messageErreur(res));
    }
  }

  PeriodeIndisponibilite _lireReponse(http.Response res) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_messageErreur(res));
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final p = data is Map<String, dynamic> ? PeriodeIndisponibilite.fromJson(data) : null;
    if (p == null) throw Exception('Réponse inattendue du serveur');
    return p;
  }

  /// Extrait le message lisible d'une erreur DRF
  /// ({"detail": ...} ou {"non_field_errors": [...]} ou {"champ": [...]}).
  String _messageErreur(http.Response res) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        final messages = <String>[];
        data.forEach((_, v) => messages.add(v is List ? v.join(' ') : v.toString()));
        if (messages.isNotEmpty) return messages.join('\n');
      } else if (data is List) {
        return data.join(' ');
      }
    } catch (_) {}
    return 'Erreur ${res.statusCode}';
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}