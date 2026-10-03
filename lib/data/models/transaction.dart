/// Réponse de POST https://admin-akarina.akarina.shop/api/transactions/.
class Transaction {
  final int id;
  final String reference;
  final int bien;
  final String bienReference;
  final int? client;
  final String typeTransaction;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final num montantTotal;
  final String statut;
  final DateTime? dateCreation;

  const Transaction({
    required this.id,
    required this.reference,
    required this.bien,
    required this.bienReference,
    this.client,
    required this.typeTransaction,
    this.dateDebut,
    this.dateFin,
    required this.montantTotal,
    required this.statut,
    this.dateCreation,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
    return Transaction(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      bien: json['bien'] as int,
      bienReference: json['bien_reference'] as String? ?? '',
      client: json['client'] as int?,
      typeTransaction: json['type_transaction'] as String? ?? '',
      dateDebut: parseDate(json['date_debut']),
      dateFin: parseDate(json['date_fin']),
      montantTotal: num.tryParse(json['montant_total'].toString()) ?? 0,
      statut: json['statut'] as String? ?? '',
      dateCreation: parseDate(json['date_creation']),
    );
  }
}
