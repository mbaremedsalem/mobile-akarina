import 'package:flutter/foundation.dart';

/// Critères de recherche pour l'API https://admin-akarina.akarina.shop/api/biens/.
class SearchCriteria {
  final String? typeTransaction;
  final String? typeBien;
  final int? villeId;
  final int? quartierId;
  final bool? meuble;
  /// Période de location : 'jour', '3jours' ou 'mois' (location uniquement).
  final String? unitePrix;
  final int? nbChambres;
  final num? prixMin;
  final num? prixMax;
  final DateTime? disponibleDu;
  final DateTime? disponibleAu;
  final String? search;
  final String? ordering;

  const SearchCriteria({
    this.typeTransaction,
    this.typeBien,
    this.villeId,
    this.quartierId,
    this.meuble,
    this.unitePrix,
    this.nbChambres,
    this.prixMin,
    this.prixMax,
    this.disponibleDu,
    this.disponibleAu,
    this.search,
    this.ordering,
  });

  bool get hasActiveFilters =>
      typeTransaction != null ||
      typeBien != null ||
      villeId != null ||
      quartierId != null ||
      meuble != null ||
      unitePrix != null ||
      nbChambres != null ||
      prixMin != null ||
      prixMax != null ||
      disponibleDu != null ||
      disponibleAu != null ||
      (search != null && search!.isNotEmpty) ||
      ordering != null;
}

/// Permet à la barre de recherche de l'AppBar (voir [Layout]) de publier de
/// nouveaux critères et de réveiller l'onglet Immobilier, même si ce dernier
/// est déjà construit (les onglets de la bottom nav restent montés).
class ImmobilierSearchBus {
  ImmobilierSearchBus._();

  static final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  static SearchCriteria? pendingCriteria;

  static void publish(SearchCriteria criteria) {
    pendingCriteria = criteria;
    _tick.value++;
  }

  static void addListener(VoidCallback listener) => _tick.addListener(listener);
  static void removeListener(VoidCallback listener) => _tick.removeListener(listener);
}
