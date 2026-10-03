import 'package:flutter/material.dart';

import 'package:akarina/business_logic/search/search_criteria.dart';
import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/presentations/constants/constants.dart';

/// Ouvre la feuille de critères de recherche et retourne les critères
/// choisis par l'utilisateur, ou `null` s'il a annulé.
///
/// Réutilisée à la fois par la barre de recherche de l'AppBar (voir
/// [Layout]) et par le bouton "Filtres" de l'écran Immobilier, pour que la
/// recherche puisse toujours être rouverte et modifiée.
///
/// [simple] affiche la version compacte, identique au panneau de recherche
/// du site web : "Rechercher" (vente/location), "Type de bien", "Ville",
/// "Mots-clés" puis un seul bouton "Rechercher". La version complète (avec
/// meublé, chambres, prix, disponibilité, tri) reste réservée au bouton
/// "Filtres" de l'écran Immobilier.
Future<SearchCriteria?> showSearchCriteriaSheet(
  BuildContext context, {
  SearchCriteria? initial,
  bool simple = false,
}) {
  return showModalBottomSheet<SearchCriteria>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SearchCriteriaSheet(initial: initial, simple: simple),
  );
}

class _SearchCriteriaSheet extends StatefulWidget {
  final SearchCriteria? initial;
  final bool simple;
  const _SearchCriteriaSheet({this.initial, this.simple = false});

  @override
  State<_SearchCriteriaSheet> createState() => _SearchCriteriaSheetState();
}

class _SearchCriteriaSheetState extends State<_SearchCriteriaSheet> {
  late final TextEditingController _searchController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  String? _typeTransaction;
  String? _typeBien;
  int? _villeId;
  int? _quartierId;
  bool _meubleOnly = false; // coché = uniquement les biens meublés
  String? _unitePrix; // 'jour', '3jours' ou 'mois' (location uniquement)
  int? _nbChambres;
  DateTime? _disponibleDu;
  DateTime? _disponibleAu;
  String? _ordering;

  List<Ville> _villes = [];
  bool _isLoadingVilles = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _searchController = TextEditingController(text: initial?.search ?? '');
    _minPriceController =
        TextEditingController(text: initial?.prixMin?.toString() ?? '');
    _maxPriceController =
        TextEditingController(text: initial?.prixMax?.toString() ?? '');
    _typeTransaction = initial?.typeTransaction;
    _typeBien = initial?.typeBien;
    _villeId = initial?.villeId;
    _quartierId = initial?.quartierId;
    _meubleOnly = initial?.meuble == true;
    _unitePrix = initial?.unitePrix;
    _nbChambres = initial?.nbChambres;
    _disponibleDu = initial?.disponibleDu;
    _disponibleAu = initial?.disponibleAu;
    _ordering = initial?.ordering;
    _loadVilles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadVilles() async {
    try {
      final villes = await BienService().fetchVilles();
      if (!mounted) return;
      setState(() {
        _villes = villes;
        _isLoadingVilles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingVilles = false);
    }
  }

  List<Quartier> get _quartiersDisponibles {
    if (_villeId == null) return [];
    final ville = _villes.firstWhere(
      (v) => v.id == _villeId,
      orElse: () => const Ville(id: 0, nom: '', nomAr: ''),
    );
    return ville.quartiers;
  }

  String _cityName(Ville ville) =>
      ville.nomFor(Localizations.localeOf(context).languageCode);

  String _quartierName(Quartier quartier) =>
      quartier.nomFor(Localizations.localeOf(context).languageCode);

  /// Traduction avec repli sur la clé si elle n'existe pas encore dans les
  /// fichiers de langue (évite un crash sur `!`).
  String _t(String key) => getTranslated(context, key) ?? key;

  void _clearAll() {
    setState(() {
      _typeTransaction = null;
      _typeBien = null;
      _villeId = null;
      _quartierId = null;
      _meubleOnly = false;
      _unitePrix = null;
      _nbChambres = null;
      _disponibleDu = null;
      _disponibleAu = null;
      _ordering = null;
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _submit() {
    final criteria = SearchCriteria(
      typeTransaction: _typeTransaction,
      typeBien: _typeBien,
      villeId: _villeId,
      quartierId: _quartierId,
      meuble: _meubleOnly ? true : null,
      unitePrix: _typeTransaction == 'location' ? _unitePrix : null,
      nbChambres: _nbChambres,
      prixMin: double.tryParse(_minPriceController.text),
      prixMax: double.tryParse(_maxPriceController.text),
      disponibleDu: _disponibleDu,
      disponibleAu: _disponibleAu,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      ordering: _ordering,
    );
    Navigator.pop(context, criteria);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = (isStart ? _disponibleDu : _disponibleAu) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _disponibleDu = picked;
      } else {
        _disponibleAu = picked;
      }
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  // ---------------------------------------------------------------------------
  // Version simple : même mise en page que le panneau de recherche du site web
  // ---------------------------------------------------------------------------

  Widget _buildSimple(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Rechercher : vente ou location
            _simpleLabel(_t('Rechercher')),
            _simpleDropdown(
              value: _typeTransaction,
              items: [
                {'value': null, 'label': _t('Vente ou location')},
                {'value': 'vente', 'label': _t('vendre')},
                {'value': 'location', 'label': _t('alouer')},
              ],
              onChanged: (v) => setState(() => _typeTransaction = v as String?),
            ),
            const SizedBox(height: 20),

            // Type de bien
            _simpleLabel(_t('Type de bien')),
            _simpleDropdown(
              value: _typeBien,
              items: [
                {'value': null, 'label': _t('Tous les types')},
                {'value': 'appartement', 'label': _t('Appartement')},
                {'value': 'duplexe', 'label': _t('Duplex')},
                {'value': 'commercial', 'label': _t('Commercial')},
                {'value': 'terrain', 'label': _t('Terrain')},
                {'value': 'ceremonie', 'label': _t('Maisonceremonie')},
              ],
              onChanged: (v) => setState(() => _typeBien = v as String?),
            ),
            const SizedBox(height: 20),

            // Ville
            _simpleLabel(_t('Ville')),
            _isLoadingVilles
                ? _simpleBox(
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _simpleDropdown(
                    value: _villeId,
                    leadingIcon: Icons.location_on_outlined,
                    items: [
                      {'value': null, 'label': _t('Toutes les villes')},
                      ..._villes.map((v) => {'value': v.id, 'label': _cityName(v)}),
                    ],
                    onChanged: (v) => setState(() {
                      _villeId = v as int?;
                      _quartierId = null;
                    }),
                  ),
            const SizedBox(height: 20),

            // Mots-clés
            _simpleLabel(_t('Mots-clés')),
            _simpleBox(
              child: Row(
                children: [
                  Icon(Icons.sell_outlined, size: 20, color: Colors.grey[500]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: _t('Quartier, référence...'),
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Bouton Rechercher pleine largeur
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _t('Rechercher'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }

  Widget _simpleBox({required Widget child}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: child,
    );
  }

  Widget _simpleDropdown({
    required dynamic value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<dynamic>? onChanged,
    IconData? leadingIcon,
  }) {
    return _simpleBox(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
          borderRadius: BorderRadius.circular(12),
          items: items
              .map((item) => DropdownMenuItem<dynamic>(
                    value: item['value'],
                    child: Row(
                      children: [
                        if (leadingIcon != null) ...[
                          Icon(leadingIcon, size: 20, color: Colors.grey[500]),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            item['label'],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Version complète (bouton "Filtres" de l'écran Immobilier)
  // ---------------------------------------------------------------------------

  /// Nombre de critères actifs, affiché sur le bouton de validation.
  int get _activeCount {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_typeTransaction != null) count++;
    if (_typeBien != null) count++;
    if (_villeId != null) count++;
    if (_quartierId != null) count++;
    if (_meubleOnly) count++;
    if (_typeTransaction == 'location' && _unitePrix != null) count++;
    if (_nbChambres != null) count++;
    if (_minPriceController.text.isNotEmpty || _maxPriceController.text.isNotEmpty) count++;
    if (_disponibleDu != null || _disponibleAu != null) count++;
    if (_ordering != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.simple) return _buildSimple(context);

    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          Divider(height: 1, color: Colors.grey[200]),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: 20,
                bottom: media.viewInsets.bottom + 24,
              ),
              children: [
                _padded(_buildSearchField()),
                _section(
                  title: _t('Type opération'),
                  child: _padded(_segmented(
                    options: [
                      {'value': null, 'label': _t('Tous')},
                      {'value': 'vente', 'label': _t('vendre')},
                      {'value': 'location', 'label': _t('alouer')},
                    ],
                    selected: _typeTransaction,
                    onChanged: (v) => setState(() {
                      _typeTransaction = v as String?;
                      if (_typeTransaction != 'location') _unitePrix = null;
                    }),
                  )),
                ),
                _buildRentalPeriod(),
                _section(
                  title: _t('Type de bien'),
                  child: _buildTypeTiles(),
                ),
                _section(
                  title: _t('Ville'),
                  child: _buildLocation(),
                ),
                _section(
                  title: _t('Prix'),
                  trailing: _t('MRU'),
                  child: _padded(_buildPriceRange()),
                ),
                _section(
                  title: _t('Chambres'),
                  child: _padded(_segmented(
                    options: [
                      {'value': null, 'label': _t('Tous')},
                      for (var i = 1; i <= 5; i++) {'value': i, 'label': '$i+'},
                    ],
                    selected: _nbChambres,
                    onChanged: (v) => setState(() => _nbChambres = v as int?),
                  )),
                ),
                _section(
                  title: _t('Équipement'),
                  child: _padded(_buildMeubleCheckbox()),
                ),
                _section(
                  title: _t('Disponibilité'),
                  child: _padded(_buildDates()),
                ),
                _section(
                  title: _t('Trier par'),
                  showDivider: false,
                  child: _padded(_buildSortChips()),
                ),
              ],
            ),
          ),
          _buildBottomBar(media),
        ],
      ),
    );
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                icon: const Icon(Icons.close_rounded, color: kBlackColor, size: 20),
              ),
              Expanded(
                child: Text(
                  _t('Filtres'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: _activeCount == 0 ? null : _clearAll,
                style: TextButton.styleFrom(foregroundColor: pcolor),
                child: Text(
                  _t('Effacer tout'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    String? trailing,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        child,
        if (showDivider) ...[
          const SizedBox(height: 24),
          Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey[200]),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey[600], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: _t('Rechercher par adresse, ville...'),
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.5),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(_searchController.clear),
              child: Icon(Icons.cancel_rounded, color: Colors.grey[400], size: 20),
            ),
        ],
      ),
    );
  }

  /// Contrôle segmenté : une "pilule" blanche glisse sur l'option choisie.
  Widget _segmented({
    required List<Map<String, dynamic>> options,
    required dynamic selected,
    required ValueChanged<dynamic> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option['value'];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(option['value']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option['label'],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? pcolor : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeTiles() {
    final types = [
      {'value': null, 'label': _t('Tous'), 'icon': Icons.grid_view_rounded},
      {'value': 'appartement', 'label': _t('Appartement'), 'icon': Icons.apartment_rounded},
      {'value': 'duplexe', 'label': _t('Duplex'), 'icon': Icons.home_work_rounded},
      {'value': 'commercial', 'label': _t('Commercial'), 'icon': Icons.storefront_rounded},
      {'value': 'terrain', 'label': _t('Terrain'), 'icon': Icons.landscape_rounded},
      {'value': 'ceremonie', 'label': _t('Maisonceremonie'), 'icon': Icons.celebration_rounded},
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = _typeBien == type['value'];
          return GestureDetector(
            onTap: () => setState(() => _typeBien = type['value'] as String?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? pcolor.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? pcolor : Colors.grey[200]!,
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    size: 28,
                    color: isSelected ? pcolor : Colors.grey[700],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? pcolor : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kBlackColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? kBlackColor : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horizontalPills(List<Widget> pills) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => pills[index],
      ),
    );
  }

  Widget _buildLocation() {
    if (_isLoadingVilles) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final quartiers = _quartiersDisponibles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _horizontalPills([
          _pill(
            label: _t('Toutes les villes'),
            icon: Icons.public_rounded,
            selected: _villeId == null,
            onTap: () => setState(() {
              _villeId = null;
              _quartierId = null;
            }),
          ),
          ..._villes.map((v) => _pill(
                label: _cityName(v),
                icon: Icons.location_on_rounded,
                selected: _villeId == v.id,
                onTap: () => setState(() {
                  _villeId = v.id;
                  _quartierId = null;
                }),
              )),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: quartiers.isEmpty
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: Text(
                        _t('Quartier'),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    _horizontalPills([
                      _pill(
                        label: _t('Tous les quartiers'),
                        selected: _quartierId == null,
                        onTap: () => setState(() => _quartierId = null),
                      ),
                      ...quartiers.map((q) => _pill(
                            label: _quartierName(q),
                            selected: _quartierId == q.id,
                            onTap: () => setState(() => _quartierId = q.id),
                          )),
                    ]),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPriceRange() {
    return Row(
      children: [
        Expanded(
          child: _priceField(controller: _minPriceController, label: _t('Min')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(width: 12, height: 2, color: Colors.grey[400]),
        ),
        Expanded(
          child: _priceField(controller: _maxPriceController, label: _t('Max')),
        ),
      ],
    );
  }

  Widget _priceField({required TextEditingController controller, required String label}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4),
            ),
          ),
        ],
      ),
    );
  }

  /// Période de location (par jour, par 3 jours, par mois) : n'apparaît que
  /// lorsque l'utilisateur a choisi « Location ».
  Widget _buildRentalPeriod() {
    final visible = _typeTransaction == 'location';
    final options = [
      {'value': null, 'label': _t('Tous'), 'icon': Icons.all_inclusive_rounded},
      {'value': 'jour', 'label': _t('Par jour'), 'icon': Icons.today_rounded},
      {'value': '3jours', 'label': _t('Par 3 jours'), 'icon': Icons.date_range_rounded},
      {'value': 'mois', 'label': _t('Par mois'), 'icon': Icons.calendar_month_rounded},
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : _section(
              title: _t('Durée de location'),
              child: _padded(Row(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _periodTile(options[i])),
                  ],
                ],
              )),
            ),
    );
  }

  Widget _periodTile(Map<String, dynamic> option) {
    final isSelected = _unitePrix == option['value'];
    return GestureDetector(
      onTap: () => setState(() => _unitePrix = option['value'] as String?),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [pcolor, pcolor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [BoxShadow(color: pcolor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              option['icon'] as IconData,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 6),
            Text(
              option['label'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeubleCheckbox() {
    return InkWell(
      onTap: () => setState(() => _meubleOnly = !_meubleOnly),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: _meubleOnly ? pcolor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _meubleOnly ? pcolor : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _meubleOnly ? pcolor : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.weekend_rounded,
                size: 20,
                color: _meubleOnly ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('Meublé'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kBlackColor),
              ),
            ),
            Checkbox(
              value: _meubleOnly,
              onChanged: (v) => setState(() => _meubleOnly = v ?? false),
              activeColor: pcolor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              side: BorderSide(color: Colors.grey[400]!, width: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDates() {
    return Row(
      children: [
        Expanded(
          child: _dateTile(
            label: _t('Disponible du'),
            value: _disponibleDu,
            onTap: () => _pickDate(isStart: true),
            onClear: () => setState(() => _disponibleDu = null),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateTile(
            label: _t('Disponible au'),
            value: _disponibleAu,
            onTap: () => _pickDate(isStart: false),
            onClear: () => setState(() => _disponibleAu = null),
          ),
        ),
      ],
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: hasValue ? pcolor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasValue ? pcolor : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: hasValue ? pcolor : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? _formatDate(value) : '--/--/----',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? kBlackColor : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.cancel_rounded, size: 18, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    final options = [
      {'value': null, 'label': _t('Pertinence'), 'icon': Icons.auto_awesome_rounded},
      {'value': '-date_creation', 'label': _t('Plus récents'), 'icon': Icons.schedule_rounded},
      {'value': 'prix', 'label': _t('Prix croissant'), 'icon': Icons.trending_up_rounded},
      {'value': '-prix', 'label': _t('Prix décroissant'), 'icon': Icons.trending_down_rounded},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => _pill(
                label: o['label'] as String,
                icon: o['icon'] as IconData,
                selected: _ordering == o['value'],
                onTap: () => setState(() => _ordering = o['value'] as String?),
              ))
          .toList(),
    );
  }

  Widget _buildBottomBar(MediaQueryData media) {
    final count = _activeCount;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, media.padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: pcolor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _t('Afficher les résultats'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: pcolor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
