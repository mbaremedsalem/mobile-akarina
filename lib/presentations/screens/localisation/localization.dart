import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:akarina/data/services/plan_service.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/presentations/utils/price_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Plan de terrain : même plan que la page "Plan de terrain" du site
/// (lots colorés par statut + zones espace vert / mosquée / équipement...).

const _defaultCenter = LatLng(18.0858, -15.9785);

// Couleurs identiques au site (STATUT_COULEURS).
const _statutCouleurs = {
  'disponible': Color(0xFF10B981),
  'attribue': Color(0xFFF59E0B),
  'vendu': Color(0xFFEF4444),
};
const _statutLabels = {
  'disponible': 'Disponible',
  'attribue': 'Attribué',
  'vendu': 'Vendu',
};

// Zones non vendables (COULEURS_ZONES / ICONES_ZONES du site).
const _zoneCouleurs = {
  'espace_vert': Color(0xFF86EFAC),
  'espace_public': Color(0xFFFDE68A),
  'equipement_public': Color(0xFF93C5FD),
  'mosquee': Color(0xFFC4B5FD),
  'autre': Color(0xFFD1D5DB),
};
const _zoneIcones = {
  'espace_vert': '🌳',
  'espace_public': '🏞️',
  'equipement_public': '🏛️',
  'mosquee': '🕌',
  'autre': '📍',
};

const _lotStroke = Color(0xFF0B0B0F);
const _lotSelectedStroke = Colors.white;

typedef _ZoneAffichee = ({PlanZone zone, List<LatLng> paths, LatLng centre, String? espaceRef});

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  GoogleMapController? _mapController;
  bool _hasInternet = true;
  bool _loading = true;
  String? _error;
  PlanData? _data;

  int? _villeId;
  int? _quartierId;
  final _numeroController = TextEditingController();
  String _numeroRecherche = '';
  bool _notFound = false;

  PlanLot? _selectedLot;
  _ZoneAffichee? _selectedZone;
  bool _afficherLots = true;
  MapType _mapType = MapType.hybrid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (!mounted) return;
    setState(() {
      _hasInternet = hasConnection;
      _loading = hasConnection;
      _error = null;
    });
    if (!hasConnection) return;
    try {
      final data = await PlanService().fetchAll();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _lang => Localizations.localeOf(context).languageCode;
  String _tr(String key) => getTranslated(context, key) ?? key;

  // ---------- Données filtrées (mêmes règles que PlanTerrainPage) ----------

  List<PlanLot> get _lots {
    final data = _data;
    if (data == null) return const [];
    return data.lots.where((l) => _quartierId == null || l.quartierId == _quartierId).toList();
  }

  List<PlanQuartier> get _plans {
    final data = _data;
    if (data == null) return const [];
    return data.plans.where((p) => _quartierId == null || p.quartierId == _quartierId).toList();
  }

  List<_ZoneAffichee> get _zones {
    final data = _data;
    if (data == null) return const [];
    final planById = {for (final p in _plans) p.id: p};
    final result = <_ZoneAffichee>[];
    for (final z in data.zones) {
      final plan = planById[z.planId];
      if (plan == null) continue;
      final paths = z.polygoneLocal.map((p) => plan.localToLatLng(p.x, p.y)).toList();
      final ref = z.bienId == null ? null : data.espaceReferenceById[z.bienId];
      result.add((zone: z, paths: paths, centre: polygonCentroid(paths), espaceRef: ref));
    }
    return result;
  }

  List<Quartier> get _quartierOptions {
    final data = _data;
    if (data == null || _villeId == null) return const [];
    return data.quartiers.where((q) => q.villeId == _villeId).toList();
  }

  LatLng get _initialCenter {
    final plans = _plans;
    if (plans.isEmpty) return _defaultCenter;
    final p = plans.firstWhere((p) => p.actif, orElse: () => plans.first);
    return LatLng(p.centreLat, p.centreLng);
  }

  // ---------- Caméra ----------

  LatLngBounds? _boundsOf(Iterable<LatLng> points) {
    if (points.isEmpty) return null;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  void _fitAll() {
    final controller = _mapController;
    if (controller == null) return;
    final lots = _lots;
    final points = lots.isNotEmpty ? [for (final l in lots) ...l.polygone] : [for (final z in _zones) ...z.paths];
    final bounds = _boundsOf(points);
    if (bounds == null) return;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
  }

  void _focusLot(PlanLot lot) {
    setState(() {
      _selectedZone = null;
      _selectedLot = lot;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(lot.centre, 19));
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final search = _numeroController.text.trim().toLowerCase();
    if (search.isEmpty) {
      setState(() {
        _numeroRecherche = '';
        _notFound = false;
      });
      _fitAll();
      return;
    }
    PlanLot? match;
    for (final l in _lots) {
      if ((l.numeroLot ?? '').toLowerCase() == search) {
        match = l;
        break;
      }
    }
    setState(() {
      _numeroRecherche = search;
      _notFound = match == null;
    });
    if (match != null) _focusLot(match);
  }

  void _resetSelection() {
    _numeroController.clear();
    _numeroRecherche = '';
    _notFound = false;
    _selectedLot = null;
    _selectedZone = null;
  }

  // ---------- Carte ----------

  Set<Polygon> _buildPolygons(List<PlanLot> lots, List<_ZoneAffichee> zones) {
    if (!_afficherLots) return const {};
    final polygons = <Polygon>{};

    for (final z in zones) {
      final couleur = _zoneCouleurs[z.zone.typeZone] ?? _zoneCouleurs['autre']!;
      final publiee = z.espaceRef != null;
      polygons.add(Polygon(
        polygonId: PolygonId('zone-${z.zone.id}'),
        points: z.paths,
        fillColor: couleur.withValues(alpha: 0.45),
        strokeColor: _lotStroke,
        strokeWidth: 2,
        zIndex: 1,
        consumeTapEvents: publiee,
        onTap: publiee
            ? () => setState(() {
                  _selectedLot = null;
                  _selectedZone = z;
                })
            : null,
      ));
    }

    for (final lot in lots) {
      final selected = _selectedLot?.reference == lot.reference;
      final couleur = _statutCouleurs[lot.statut]!;
      polygons.add(Polygon(
        polygonId: PolygonId('lot-${lot.reference}'),
        points: lot.polygone,
        fillColor: selected ? _lotSelectedStroke.withValues(alpha: 0.3) : couleur.withValues(alpha: 0.18),
        strokeColor: selected ? _lotSelectedStroke : _lotStroke,
        strokeWidth: selected ? 4 : 2,
        zIndex: selected ? 3 : 2,
        consumeTapEvents: true,
        onTap: () => _focusLot(lot),
      ));
    }
    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) return NoInternetPage(onRetry: _load);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            _lang == 'ar' ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2,
            color: kBlackColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_tr('Plan de terrain'), style: const TextStyle(color: kBlackColor)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(_tr('Impossible de charger le plan'), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(_tr('Réessayer'))),
            ],
          ),
        ),
      );
    }

    final lots = _lots;
    final zones = _zones;

    return Column(
      children: [
        _buildFilters(),
        if (_notFound)
          _banner(_tr('Aucun terrain avec le numéro {numero}').replaceAll('{numero}', _numeroRecherche),
              Colors.red.shade50, Colors.red.shade700),
        if (lots.isEmpty && zones.isEmpty)
          _banner(_tr('Aucun plan de lotissement disponible pour ce quartier.'), Colors.grey.shade100,
              Colors.grey.shade700),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialCenter, zoom: 16),
                mapType: _mapType,
                polygons: _buildPolygons(lots, zones),
                onMapCreated: (c) {
                  _mapController = c;
                  _fitAll();
                },
                onTap: (_) => setState(() {
                  _selectedLot = null;
                  _selectedZone = null;
                }),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
              ),
              PositionedDirectional(top: 12, start: 12, child: _buildMapTypes()),
              PositionedDirectional(top: 12, end: 12, child: _buildControls()),
              if (_selectedLot == null && _selectedZone == null)
                PositionedDirectional(bottom: 16, start: 12, child: _buildLegend()),
              if (_selectedLot != null)
                Positioned(left: 12, right: 12, bottom: 16, child: _buildLotCard(_selectedLot!)),
              if (_selectedZone != null)
                Positioned(left: 12, right: 12, bottom: 16, child: _buildZoneCard(_selectedZone!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, Color bg, Color fg) => Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(text, style: TextStyle(color: fg, fontSize: 13)),
      );

  // ---------- Recherche ville / quartier / numéro ----------

  Widget _buildFilters() {
    final data = _data!;
    final decoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _villeId,
                  isExpanded: true,
                  decoration: decoration.copyWith(prefixIcon: const Icon(Icons.location_on_outlined, size: 18)),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text(_tr('Toutes les villes'))),
                    for (final v in data.villes)
                      DropdownMenuItem<int?>(
                          value: v.id, child: Text(v.nomFor(_lang), overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _villeId = v;
                      _quartierId = null;
                      _resetSelection();
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('quartier-$_villeId'),
                  value: _quartierId,
                  isExpanded: true,
                  decoration: decoration.copyWith(prefixIcon: const Icon(Icons.route_outlined, size: 18)),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text(_tr('Tous les quartiers'))),
                    for (final q in _quartierOptions)
                      DropdownMenuItem<int?>(
                          value: q.id, child: Text(q.nomFor(_lang), overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: _villeId == null
                      ? null
                      : (q) {
                          setState(() {
                            _quartierId = q;
                            _resetSelection();
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numeroController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: decoration.copyWith(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: _tr('Numéro de terrain (ex : 245)'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _search,
                child: Text(_tr('Rechercher')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Contrôles flottants ----------

  BoxDecoration get _floatingDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
      );

  Widget _buildMapTypes() {
    const types = [
      (MapType.satellite, 'Satellite'),
      (MapType.hybrid, 'Hybride'),
      (MapType.normal, 'Plan'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: _floatingDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (type, label) in types)
            GestureDetector(
              onTap: () => setState(() => _mapType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _mapType == type ? pcolor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tr(label),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _mapType == type ? Colors.white : kBlackColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    Widget btn(IconData icon, String tooltip, VoidCallback onTap, {bool active = false}) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: _floatingDecoration.copyWith(color: active ? pcolor : Colors.white),
          child: IconButton(
            tooltip: _tr(tooltip),
            icon: Icon(icon, size: 20, color: active ? Colors.white : kBlackColor),
            onPressed: onTap,
          ),
        );
    return Column(
      children: [
        btn(_afficherLots ? Icons.visibility : Icons.visibility_off, 'Afficher / masquer les lots',
            () => setState(() => _afficherLots = !_afficherLots),
            active: _afficherLots),
        btn(Icons.center_focus_strong, 'Recentrer sur tous les lots', _fitAll),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _floatingDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in _statutCouleurs.entries) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 4),
            Text(_tr(_statutLabels[e.key]!), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  // ---------- Fiche du lot / de la zone ----------

  /// Cotes façon cadastre : "35m 20m 35m 20m", ou base/hauteur/hypoténuse.
  String? _cotes({String? longueur, String? largeur, String? base, String? hauteur, String? hypotenuse}) {
    String m(String v) {
      final n = double.tryParse(v);
      if (n == null) return '${v}m';
      return '${n == n.roundToDouble() ? n.toInt() : n}m';
    }

    if (longueur != null && largeur != null) {
      return [longueur, largeur, longueur, largeur].map(m).join('  ');
    }
    final tri = [base, hauteur, hypotenuse].whereType<String>().toList();
    return tri.isEmpty ? null : tri.map(m).join('  ');
  }

  String? _nomQuartier(PlanLot lot) {
    if (lot.quartierNom != null) {
      return _lang == 'ar' && lot.quartierNomAr != null ? lot.quartierNomAr : lot.quartierNom;
    }
    for (final q in _data?.quartiers ?? const <Quartier>[]) {
      if (q.id == lot.quartierId) return q.nomFor(_lang);
    }
    return null;
  }

  Widget _buildLotCard(PlanLot lot) {
    final titreLocal = lot.titreFor(_lang);
    final titre = titreLocal.isNotEmpty ? titreLocal : '${_tr('Lot')} n°${lot.numeroLot ?? ''}';
    final prix = (lot.prix ?? 0) > 0
        ? '${formatAmount(lot.prix.toString())} ${_tr('MRU')}'
            '${lot.uniteprix.isNotEmpty && lot.uniteprix != 'forfait' ? ' / ${_tr(lot.uniteprix)}' : ''}'
        : null;
    return _InfoCard(
      titre: titre,
      statutLabel: _tr(_statutLabels[lot.statut]!),
      statutColor: _statutCouleurs[lot.statut],
      rows: [
        (_tr('Moughataa'), lot.moughataa),
        (_tr('Zone'), _nomQuartier(lot) ?? lot.adresse),
        (_tr('Lot'), lot.numeroLot),
        (_tr('Superficie'), lot.superficieM2 == null ? null : '${lot.superficieM2} m²'),
        (
          _tr('Cotes'),
          _cotes(
              longueur: lot.longueurM,
              largeur: lot.largeurM,
              base: lot.baseM,
              hauteur: lot.hauteurM,
              hypotenuse: lot.hypotenuseM)
        ),
        (_tr('Prix'), prix),
      ],
      onClose: () => setState(() => _selectedLot = null),
      onDirections: () => _openDirections(lot.centre),
      onDetails: lot.reference.isEmpty ? null : () => _openBien(lot.reference),
      onShare: () => _share(
        '${_tr('Lot')} n°${lot.numeroLot ?? ''}'
        '${lot.superficieM2 != null ? ' - ${lot.superficieM2} m²' : ''}'
        '${prix != null ? ' - $prix' : ''}\n${_mapsUrl(lot.centre)}',
      ),
      labels: _cardLabels,
    );
  }

  Widget _buildZoneCard(_ZoneAffichee z) {
    final zone = z.zone;
    return _InfoCard(
      titre: '${_zoneIcones[zone.typeZone] ?? _zoneIcones['autre']} ${zone.nom}',
      rows: [
        (_tr('Moughataa'), zone.moughataa),
        (_tr('Zone'), zone.adresse),
        (_tr('Superficie'), zone.superficieM2 == null ? null : '${zone.superficieM2} m²'),
        (_tr('Cotes'), _cotes(longueur: zone.longueurM, largeur: zone.largeurM)),
      ],
      onClose: () => setState(() => _selectedZone = null),
      onDirections: () => _openDirections(z.centre),
      onDetails: z.espaceRef == null ? null : () => _openBien(z.espaceRef!),
      onShare: () => _share('${zone.nom}\n${_mapsUrl(z.centre)}'),
      labels: _cardLabels,
    );
  }

  ({String directions, String details, String share}) get _cardLabels =>
      (directions: _tr('Itinéraire'), details: _tr('Voir la fiche'), share: _tr('Partager'));

  String _mapsUrl(LatLng p) => 'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}';

  Future<void> _openDirections(LatLng p) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _share(String text) async {
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openBien(String reference) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ImmobDetails(reference: reference)));
  }
}

/// Fiche "tableau" du lot ou de la zone sélectionné(e), comme le popup du site :
/// en-tête (titre + statut), lignes libellé/valeur, puis Itinéraire / fiche / Partager.
class _InfoCard extends StatelessWidget {
  final String titre;
  final String? statutLabel;
  final Color? statutColor;
  final List<(String, String?)> rows;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback? onDetails;
  final VoidCallback onShare;
  final ({String directions, String details, String share}) labels;

  const _InfoCard({
    required this.titre,
    this.statutLabel,
    this.statutColor,
    required this.rows,
    required this.onClose,
    required this.onDirections,
    required this.onDetails,
    required this.onShare,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kBlackColor),
                  ),
                ),
                if (statutLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statutColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(statutLabel!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
            if (visibleRows.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Table(
                  columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
                  children: [
                    for (final (label, value) in visibleRows)
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 12, top: 5, bottom: 5),
                          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(value!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBlackColor)),
                        ),
                      ]),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.navigation_outlined, size: 16),
                      label: Text(labels.directions, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (onDetails != null) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: pcolor, foregroundColor: Colors.white),
                        onPressed: onDetails,
                        child: Text(labels.details, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    tooltip: labels.share,
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF25D366)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
