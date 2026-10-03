import 'package:akarina/data/models/map_property.dart';

/// Critères de recherche appliqués localement sur la liste des biens chargés.
class PropertyFilter {
  /// `null` = toutes les opérations, sinon `vendre` / `alouer`.
  final String? typeOperation;

  /// `null` = toutes les catégories, sinon `appartement` / `duplexe` /
  /// `ceremonie` / `terrain` / `commercial`.
  final String? categorie;

  /// `null` = toutes les périodes, sinon `Mensuelle` / `par Nuit`.
  final String? periode;

  final double? prixMin;
  final double? prixMax;
  final int chambresMin;
  final int sallesDeBainMin;

  final bool meuble;
  final bool uniquementDisponibles;

  /// Texte libre : adresse, quartier ou ville.
  final String recherche;

  const PropertyFilter({
    this.typeOperation,
    this.categorie,
    this.periode,
    this.prixMin,
    this.prixMax,
    this.chambresMin = 0,
    this.sallesDeBainMin = 0,
    this.meuble = false,
    this.uniquementDisponibles = false,
    this.recherche = '',
  });

  /// Bornes de prix connues du catalogue, utilisées pour calibrer le slider.
  static const double prixLocationMax = 500000;
  static const double prixVenteMax = 40000000;

  double get borneMax =>
      typeOperation == 'vendre' ? prixVenteMax : prixLocationMax;

  PropertyFilter copyWith({
    Object? typeOperation = _unset,
    Object? categorie = _unset,
    Object? periode = _unset,
    Object? prixMin = _unset,
    Object? prixMax = _unset,
    int? chambresMin,
    int? sallesDeBainMin,
    bool? meuble,
    bool? uniquementDisponibles,
    String? recherche,
  }) {
    return PropertyFilter(
      typeOperation:
          identical(typeOperation, _unset) ? this.typeOperation : typeOperation as String?,
      categorie: identical(categorie, _unset) ? this.categorie : categorie as String?,
      periode: identical(periode, _unset) ? this.periode : periode as String?,
      prixMin: identical(prixMin, _unset) ? this.prixMin : prixMin as double?,
      prixMax: identical(prixMax, _unset) ? this.prixMax : prixMax as double?,
      chambresMin: chambresMin ?? this.chambresMin,
      sallesDeBainMin: sallesDeBainMin ?? this.sallesDeBainMin,
      meuble: meuble ?? this.meuble,
      uniquementDisponibles: uniquementDisponibles ?? this.uniquementDisponibles,
      recherche: recherche ?? this.recherche,
    );
  }

  static const Object _unset = Object();

  /// Nombre de critères actifs, affiché sur le badge du bouton Filtres.
  /// La recherche textuelle n'est pas comptée : elle a son propre champ.
  int get nombreActifs {
    var count = 0;
    if (typeOperation != null) count++;
    if (categorie != null) count++;
    if (periode != null) count++;
    if (prixMin != null || prixMax != null) count++;
    if (chambresMin > 0) count++;
    if (sallesDeBainMin > 0) count++;
    if (meuble) count++;
    if (uniquementDisponibles) count++;
    return count;
  }

  bool get isEmpty => nombreActifs == 0 && recherche.trim().isEmpty;

  bool matches(MapProperty p) {
    if (typeOperation != null && p.typeOperation != typeOperation) return false;
    if (categorie != null && p.categorie != categorie) return false;

    if (periode != null) {
      final attendu = periode!.toLowerCase().contains('nuit');
      if (p.isNuitee != attendu) return false;
    }

    final prix = p.prix;
    if (prixMin != null && (prix == null || prix < prixMin!)) return false;
    if (prixMax != null && (prix == null || prix > prixMax!)) return false;

    if (chambresMin > 0 && p.chambres < chambresMin) return false;
    if (sallesDeBainMin > 0 && p.sallesDeBain < sallesDeBainMin) return false;

    if (meuble && !p.meuble) return false;
    if (uniquementDisponibles && !p.available) return false;

    final terme = recherche.trim().toLowerCase();
    if (terme.isNotEmpty) {
      final haystack = [p.adresse, p.ville, p.region, p.description]
          .join(' ')
          .toLowerCase();
      final mots = terme.split(RegExp(r'\s+'));
      if (!mots.every(haystack.contains)) return false;
    }

    return true;
  }

  List<MapProperty> apply(List<MapProperty> properties) =>
      properties.where(matches).toList();
}
