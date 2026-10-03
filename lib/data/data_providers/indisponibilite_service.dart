import 'dart:convert';

import 'package:http/http.dart' as http;

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
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

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
}