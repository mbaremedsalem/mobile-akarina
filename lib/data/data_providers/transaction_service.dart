import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:akarina/data/models/transaction.dart';

/// Client pour https://admin-akarina.akarina.shop/api/transactions/.
///
/// Authentification par jeton DRF (comme [AccountService]), stocké sous la
/// clé "admin_token" côté app : `Authorization: Token <jeton>`.
class TransactionService {
  static const String baseUrl = 'https://admin-akarina.akarina.shop/api';

  Future<Transaction> creerTransaction({
    required String adminToken,
    required int bienId,
    required String typeTransaction,
    required num montantTotal,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final body = <String, dynamic>{
      'bien': bienId,
      'type_transaction': typeTransaction,
      'montant_total': montantTotal,
      'statut': 'en_attente',
      if (dateDebut != null) 'date_debut': _formatDate(dateDebut),
      if (dateFin != null) 'date_fin': _formatDate(dateFin),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/transactions/'),
      headers: {
        'Authorization': 'Token $adminToken',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return Transaction.fromJson(data);
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
