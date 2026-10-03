import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/map_property.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:akarina/data/services/geo_service.dart';
import 'package:akarina/presentations/components/map/filter_sheet.dart';
import 'package:akarina/presentations/components/map/map_property_card.dart';
import 'package:akarina/presentations/components/map/price_marker.dart';
import 'package:akarina/presentations/components/map/property_filter.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';

/// Accueil cartographique : tous les biens géolocalisés sur Google Maps, avec
/// recherche, filtres et carrousel de fiches synchronisé avec les marqueurs.
class MapHome extends StatefulWidget {
  /// Appelé quand l'utilisateur bascule vers la vue liste.
  final VoidCallback? onSwitchToList;

  const MapHome({super.key, this.onSwitchToList});

  @override
  State<MapHome> createState() => _MapHomeState();
}

class _MapHomeState extends State<MapHome> {
  static const String _baseUrl = 'https://admin-akarina.akarina.shop/api/biens/';
  static const int _pageSize = 20;

  /// Hauteur de la fiche du carrousel. Assez généreuse pour absorber les
  /// réglages d'accessibilité (police système agrandie) sans faire déborder
  /// le contenu de [MapPropertyCard].
  static const double _hauteurCarrousel = 172;

  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.88);
  final _markerFactory = PriceMarkerFactory();

  /// Tous les biens chargés, y compris ceux sans position exploitable.
  List<MapProperty> _tous = [];

  /// Biens correspondant au filtre courant ET positionnables sur la carte.
  List<MapProperty> _visibles = [];

  Set<Marker> _markers = {};
  PropertyFilter _filtre = const PropertyFilter();

  int? _selectionId;
  double _zoom = 12.5;

  /// Palier de regroupement appliqué au dernier rendu des marqueurs.
  double _celluleCourante = -1;
  bool _isLoading = true;
  bool _chargementComplet = false;
  bool _hasInternetConnection = true;
  bool _carrouselVisible = true;
  bool _suggestionsVisibles = false;

  /// Jeton de la dernière reconstruction de marqueurs : évite qu'une passe
  /// asynchrone obsolète n'écrase le résultat de la plus récente.
  int _markerToken = 0;

  Timer? _debounceRecherche;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _debounceRecherche?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  // ---------------------------------------------------------------- données

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (!mounted) return;
    setState(() => _hasInternetConnection = hasConnection);
    if (!hasConnection) return;
    await _chargerBiens();
  }

  Future<void> _chargerBiens() async {
    setState(() {
      _isLoading = true;
      _chargementComplet = false;
    });

    try {
      final premiere = await _chargerPage(1);
      if (!mounted) return;

      final count = premiere.count;
      _appliquerResultats(premiere.items, remplacer: true);
      setState(() => _isLoading = false);

      final totalPages = (count / _pageSize).ceil();
      if (totalPages <= 1) {
        setState(() => _chargementComplet = true);
        return;
      }

      // Les pages restantes arrivent par lots : la carte reste utilisable
      // pendant le chargement au lieu d'attendre les 15 requêtes.
      const tailleLot = 5;
      for (var debut = 2; debut <= totalPages; debut += tailleLot) {
        final fin = math.min(debut + tailleLot - 1, totalPages);
        final lots = await Future.wait([
          for (var page = debut; page <= fin; page++) _chargerPage(page),
        ]);
        if (!mounted) return;
        _appliquerResultats(
          [for (final lot in lots) ...lot.items],
          remplacer: false,
        );
      }

      if (!mounted) return;
      setState(() => _chargementComplet = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _chargementComplet = true;
      });
      _showError('${_t("Erreur lors du chargement")}: $e');
    }
  }

  Future<({int count, List<MapProperty> items})> _chargerPage(int page) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?page=$page'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MapProperty.fromJson)
        .toList();

    return (count: (data['count'] as int?) ?? results.length, items: results);
  }

  void _appliquerResultats(List<MapProperty> nouveaux, {required bool remplacer}) {
    final parId = <int, MapProperty>{
      if (!remplacer) for (final p in _tous) p.id: p,
      for (final p in nouveaux) p.id: p,
    };
    _tous = parId.values.toList();
    _rafraichirVisibles(recentrer: remplacer);
  }

  // ---------------------------------------------------------- filtre & carte

  List<MapProperty> _filtrer(PropertyFilter filtre) =>
      _tous.where((p) => p.position != null && filtre.matches(p)).toList();

  void _rafraichirVisibles({bool recentrer = false}) {
    final visibles = _filtrer(_filtre);

    // Les biens les moins chers d'abord : le carrousel s'ouvre sur les offres
    // les plus intéressantes, comme sur Zillow.
    visibles.sort((a, b) {
      final pa = a.prix ?? double.maxFinite;
      final pb = b.prix ?? double.maxFinite;
      return pa.compareTo(pb);
    });

    final selectionPerdue =
        _selectionId != null && !visibles.any((p) => p.id == _selectionId);

    setState(() {
      _visibles = visibles;
      if (selectionPerdue) _selectionId = null;
    });

    // La liste a changé de taille : on ramène le carrousel en tête pour que la
    // page courante ne pointe pas hors des nouvelles bornes.
    if (selectionPerdue && _pageController.hasClients && visibles.isNotEmpty) {
      _pageController.jumpToPage(0);
    }

    _reconstruireMarkers();
    if (recentrer) _ajusterCamera();
  }

  Future<void> _reconstruireMarkers() async {
    final token = ++_markerToken;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final groupes = _grouper(_visibles, _zoom);
    final markers = <Marker>{};

    for (final groupe in groupes) {
      if (groupe.length == 1) {
        final p = groupe.first;
        final selected = p.id == _selectionId;
        final icon = await _markerFactory.build(
          label: p.prixCourt,
          selected: selected,
          available: p.available,
          couleur: p.isVente ? const Color(0xFFE0552B) : pcolor,
          devicePixelRatio: dpr,
        );
        if (token != _markerToken) return;
        markers.add(
          Marker(
            markerId: MarkerId('bien_${p.id}'),
            position: p.position!,
            icon: icon,
            anchor: const Offset(0.5, 1.0),
            zIndexInt: selected ? 1000 : 1,
            onTap: () => _selectionner(p, recentrer: true),
          ),
        );
      } else {
        final centre = _centre(groupe);
        final icon = await _markerFactory.buildCluster(
          count: groupe.length,
          couleur: pcolor,
          devicePixelRatio: dpr,
        );
        if (token != _markerToken) return;
        markers.add(
          Marker(
            markerId: MarkerId('groupe_${centre.latitude}_${centre.longitude}'),
            position: centre,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            onTap: () => _zoomerSurGroupe(centre),
          ),
        );
      }
    }

    if (token != _markerToken || !mounted) return;
    setState(() => _markers = markers);
  }

  /// Regroupe les biens trop proches pour être lisibles au zoom courant.
  List<List<MapProperty>> _grouper(List<MapProperty> properties, double zoom) {
    final cellule = _tailleCellule(zoom);
    if (cellule <= 0) return properties.map((p) => [p]).toList();

    final grille = <String, List<MapProperty>>{};
    for (final p in properties) {
      final position = p.position!;
      final cle = '${(position.latitude / cellule).round()}'
          ':${(position.longitude / cellule).round()}';
      grille.putIfAbsent(cle, () => []).add(p);
    }
    return grille.values.toList();
  }

  double _tailleCellule(double zoom) {
    if (zoom >= 15.5) return 0;
    if (zoom >= 14) return 0.0015;
    if (zoom >= 12.5) return 0.004;
    if (zoom >= 11) return 0.012;
    return 0.05;
  }

  LatLng _centre(List<MapProperty> groupe) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in groupe) {
      lat += p.position!.latitude;
      lng += p.position!.longitude;
    }
    return LatLng(lat / groupe.length, lng / groupe.length);
  }

  void _selectionner(MapProperty property, {bool recentrer = false}) {
    final index = _visibles.indexWhere((p) => p.id == property.id);
    if (index < 0) return;

    setState(() {
      _selectionId = property.id;
      _carrouselVisible = true;
      _suggestionsVisibles = false;
    });
    FocusScope.of(context).unfocus();

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    if (recentrer) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(property.position!),
      );
    }
    _reconstruireMarkers();
  }

  Future<void> _zoomerSurGroupe(LatLng centre) async {
    final controller = _mapController;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(centre, math.min(zoom + 2.2, 18)),
    );
  }

  Future<void> _ajusterCamera() async {
    final controller = _mapController;
    if (controller == null || _visibles.isEmpty) return;

    if (_visibles.length == 1) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_visibles.first.position!, 16),
      );
      return;
    }

    var sudLat = 90.0, nordLat = -90.0, ouestLng = 180.0, estLng = -180.0;
    for (final p in _visibles) {
      final position = p.position!;
      sudLat = math.min(sudLat, position.latitude);
      nordLat = math.max(nordLat, position.latitude);
      ouestLng = math.min(ouestLng, position.longitude);
      estLng = math.max(estLng, position.longitude);
    }

    // Marge minimale : des points quasi confondus donneraient des bornes
    // dégénérées que la caméra refuse d'interpréter.
    const marge = 0.004;
    final bounds = LatLngBounds(
      southwest: LatLng(sudLat - marge, ouestLng - marge),
      northeast: LatLng(nordLat + marge, estLng + marge),
    );

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (_) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(GeoService.nouakchott, 12),
      );
    }
  }

  // ------------------------------------------------------ recherche & filtres

  void _onRechercheChanged(String valeur) {
    _debounceRecherche?.cancel();
    setState(() => _suggestionsVisibles = valeur.trim().isNotEmpty);
    _debounceRecherche = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _filtre = _filtre.copyWith(recherche: valeur);
      _rafraichirVisibles(recentrer: valeur.trim().isNotEmpty);
    });
  }

  void _appliquerSuggestion(String valeur) {
    _debounceRecherche?.cancel();
    _searchController.text = valeur;
    FocusScope.of(context).unfocus();
    setState(() => _suggestionsVisibles = false);
    _filtre = _filtre.copyWith(recherche: valeur);
    _rafraichirVisibles(recentrer: true);
  }

  void _effacerRecherche() {
    _debounceRecherche?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _suggestionsVisibles = false);
    _filtre = _filtre.copyWith(recherche: '');
    _rafraichirVisibles(recentrer: true);
  }

  /// Quartiers et villes présents dans le catalogue, proposés sous la barre
  /// de recherche.
  List<String> get _suggestions {
    final terme = _searchController.text.trim().toLowerCase();
    if (terme.isEmpty) return const [];

    final libelles = <String>{};
    for (final p in _tous) {
      for (final candidat in [p.region, p.ville, p.adresse]) {
        if (candidat.isNotEmpty && candidat.toLowerCase().contains(terme)) {
          libelles.add(candidat);
        }
      }
    }
    final liste = libelles.toList()..sort();
    return liste.take(6).toList();
  }

  Future<void> _ouvrirFiltres() async {
    FocusScope.of(context).unfocus();
    final resultat = await FilterSheet.show(
      context,
      filtreInitial: _filtre,
      compter: (filtre) => _filtrer(filtre).length,
    );
    if (resultat == null || !mounted) return;
    _filtre = resultat;
    _rafraichirVisibles(recentrer: true);
  }

  void _basculerOperation(String? type) {
    _filtre = _filtre.copyWith(
      typeOperation: _filtre.typeOperation == type ? null : type,
      prixMin: null,
      prixMax: null,
    );
    _rafraichirVisibles(recentrer: true);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------------- vues

  @override
  Widget build(BuildContext context) {
    if (!_hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          if (!mounted) return;
          setState(() => _hasInternetConnection = hasConnection);
          if (hasConnection) _initializeData();
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          if (_isLoading) _buildLoader(),
          _buildTopBar(),
          if (!_isLoading && _visibles.isEmpty) _buildEmptyState(),
          _buildBoutonsFlottants(),
          _buildCarrousel(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: GeoService.nouakchott,
        zoom: 12.5,
      ),
      style: MapStyle.epure,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_visibles.isNotEmpty) _ajusterCamera();
      },
      onCameraMove: (position) => _zoom = position.zoom,
      onCameraIdle: () {
        // Le regroupement ne dépend que du palier de zoom : inutile de
        // reconstruire 150 marqueurs après un simple déplacement latéral.
        final cellule = _tailleCellule(_zoom);
        if (cellule == _celluleCourante || _visibles.isEmpty) return;
        _celluleCourante = cellule;
        _reconstruireMarkers();
      },
      onTap: (_) {
        FocusScope.of(context).unfocus();
        setState(() {
          _suggestionsVisibles = false;
          _selectionId = null;
        });
        _reconstruireMarkers();
      },
    );
  }

  Widget _buildLoader() {
    return Container(
      color: Colors.white.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: pcolor),
            const SizedBox(height: 14),
            Text(
              _t('Chargement de la carte...'),
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(),
            if (_suggestionsVisibles && _suggestions.isNotEmpty)
              _buildSuggestions()
            else
              _buildFilterChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[600], size: 22),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onRechercheChanged,
              onSubmitted: (valeur) => _appliquerSuggestion(valeur),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _t('Quartier, ville ou adresse'),
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
              onPressed: _effacerRecherche,
              tooltip: _t('Effacer'),
            ),
          if (widget.onSwitchToList != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildBoutonListe(),
            ),
        ],
      ),
    );
  }

  Widget _buildBoutonListe() {
    return Material(
      color: pcolor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onSwitchToList,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_list, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                _t('Liste'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions
            .map(
              (suggestion) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.place_outlined, size: 18, color: pcolor),
                title: Text(suggestion, style: const TextStyle(fontSize: 13)),
                onTap: () => _appliquerSuggestion(suggestion),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildChip(
            label: _t('Filtres'),
            icone: Icons.tune,
            actif: _filtre.nombreActifs > 0,
            badge: _filtre.nombreActifs,
            onTap: _ouvrirFiltres,
          ),
          _buildChip(
            label: _t('À louer'),
            actif: _filtre.typeOperation == 'alouer',
            onTap: () => _basculerOperation('alouer'),
          ),
          _buildChip(
            label: _t('À vendre'),
            actif: _filtre.typeOperation == 'vendre',
            onTap: () => _basculerOperation('vendre'),
          ),
          _buildChip(
            label: _t('Disponible'),
            actif: _filtre.uniquementDisponibles,
            onTap: () {
              _filtre = _filtre.copyWith(
                uniquementDisponibles: !_filtre.uniquementDisponibles,
              );
              _rafraichirVisibles();
            },
          ),
          _buildChip(
            label: '3+ ${_t('Chambres')}',
            actif: _filtre.chambresMin >= 3,
            onTap: () {
              _filtre = _filtre.copyWith(chambresMin: _filtre.chambresMin >= 3 ? 0 : 3);
              _rafraichirVisibles();
            },
          ),
          if (!_filtre.isEmpty)
            _buildChip(
              label: _t('Réinitialiser'),
              icone: Icons.refresh,
              actif: false,
              onTap: () {
                _searchController.clear();
                _filtre = const PropertyFilter();
                _rafraichirVisibles(recentrer: true);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool actif,
    required VoidCallback onTap,
    IconData? icone,
    int badge = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: actif ? pcolor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 16, color: actif ? Colors.white : Colors.grey[800]),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: actif ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pcolor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 46, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _t('Aucun bien trouvé'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _t('Essayez de modifier vos critères de recherche'),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _filtre = const PropertyFilter();
                _rafraichirVisibles(recentrer: true);
              },
              icon: const Icon(Icons.refresh, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: pcolor,
                foregroundColor: Colors.white,
              ),
              label: Text(_t('Réinitialiser la recherche')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonsFlottants() {
    final basCarrousel =
        _carrouselVisible && _visibles.isNotEmpty ? _hauteurCarrousel + 20 : 24.0;

    return Positioned(
      right: 14,
      bottom: basCarrousel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompteurResultats(),
          const SizedBox(height: 10),
          _buildMiniBouton(
            icone: _carrouselVisible ? Icons.expand_more : Icons.expand_less,
            tooltip: _carrouselVisible ? _t('Masquer les fiches') : _t('Afficher les fiches'),
            onTap: () => setState(() => _carrouselVisible = !_carrouselVisible),
          ),
          const SizedBox(height: 10),
          _buildMiniBouton(
            icone: Icons.center_focus_strong,
            tooltip: _t('Recentrer'),
            onTap: _ajusterCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildCompteurResultats() {
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_chargementComplet) ...[
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(strokeWidth: 2, color: pcolor),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            '${_visibles.length} ${_t(_visibles.length > 1 ? "biens" : "bien")}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: pcolor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBouton({
    required IconData icone,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icone, size: 21, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildCarrousel() {
    final visible = _carrouselVisible && _visibles.isNotEmpty && !_isLoading;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: visible ? 0 : -(_hauteurCarrousel + 20),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _hauteurCarrousel,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _visibles.length,
            onPageChanged: (index) {
              final property = _visibles[index];
              setState(() => _selectionId = property.id);
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(property.position!),
              );
              _reconstruireMarkers();
            },
            itemBuilder: (context, index) {
              final property = _visibles[index];
              return MapPropertyCard(
                property: property,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImmobDetails(reference: property.reference),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
