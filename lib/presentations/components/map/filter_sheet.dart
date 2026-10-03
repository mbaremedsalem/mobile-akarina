import 'package:flutter/material.dart';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/map/property_filter.dart';
import 'package:akarina/presentations/constants/constants.dart';

/// Panneau de filtres de la carte, ouvert en bottom sheet.
///
/// Renvoie le [PropertyFilter] validé, ou `null` si l'utilisateur ferme
/// la feuille sans appliquer.
class FilterSheet extends StatefulWidget {
  final PropertyFilter filtreInitial;

  /// Nombre de biens correspondant au filtre en cours d'édition, recalculé en
  /// direct par le parent pour afficher « Voir N biens ».
  final int Function(PropertyFilter) compter;

  const FilterSheet({
    super.key,
    required this.filtreInitial,
    required this.compter,
  });

  static Future<PropertyFilter?> show(
    BuildContext context, {
    required PropertyFilter filtreInitial,
    required int Function(PropertyFilter) compter,
  }) {
    return showModalBottomSheet<PropertyFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(filtreInitial: filtreInitial, compter: compter),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late PropertyFilter _filtre;

  @override
  void initState() {
    super.initState();
    _filtre = widget.filtreInitial;
  }

  void _update(PropertyFilter Function(PropertyFilter) transform) {
    setState(() => _filtre = transform(_filtre));
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  @override
  Widget build(BuildContext context) {
    final resultats = widget.compter(_filtre);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _buildOperationSection(),
                    const SizedBox(height: 24),
                    _buildCategorieSection(),
                    if (_filtre.typeOperation != 'vendre') ...[
                      const SizedBox(height: 24),
                      _buildPeriodeSection(),
                    ],
                    const SizedBox(height: 24),
                    _buildPrixSection(),
                    const SizedBox(height: 24),
                    _buildCompteurSection(
                      titre: _t('Chambres'),
                      valeur: _filtre.chambresMin,
                      onChanged: (v) => _update((f) => f.copyWith(chambresMin: v)),
                    ),
                    const SizedBox(height: 20),
                    _buildCompteurSection(
                      titre: _t('Salles de bain'),
                      valeur: _filtre.sallesDeBainMin,
                      onChanged: (v) => _update((f) => f.copyWith(sallesDeBainMin: v)),
                    ),
                    const SizedBox(height: 24),
                    _buildEquipementsSection(),
                  ],
                ),
              ),
              _buildFooter(resultats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Row(
        children: [
          Text(
            _t('Filtres'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_filtre.nombreActifs > 0)
            TextButton(
              onPressed: () => _update(
                (f) => PropertyFilter(recherche: f.recherche),
              ),
              child: Text(
                _t('Réinitialiser'),
                style: TextStyle(color: pcolor, fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titre,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOperationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_t('Type d\'opération')),
        Row(
          children: [
            _buildChoiceChip(
              label: _t('Tout'),
              selected: _filtre.typeOperation == null,
              onTap: () => _update((f) => f.copyWith(
                    typeOperation: null,
                    prixMin: null,
                    prixMax: null,
                  )),
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              label: _t('À louer'),
              selected: _filtre.typeOperation == 'alouer',
              onTap: () => _update((f) => f.copyWith(
                    typeOperation: 'alouer',
                    prixMin: null,
                    prixMax: null,
                  )),
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              label: _t('À vendre'),
              selected: _filtre.typeOperation == 'vendre',
              onTap: () => _update((f) => f.copyWith(
                    typeOperation: 'vendre',
                    periode: null,
                    prixMin: null,
                    prixMax: null,
                  )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorieSection() {
    const categories = <String, String>{
      'Appartement': 'Appartement',
      'Duplex': 'Duplex',
      'Commercial': 'Commercial',
      'Terrain': 'Terrain',
      'Maisonceremonie': 'Maisonceremonie',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_t('Catégorie')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: _t('Tout'),
              selected: _filtre.categorie == null,
              onTap: () => _update((f) => f.copyWith(categorie: null)),
            ),
            ...categories.entries.map(
              (e) => _buildChoiceChip(
                label: _t(e.value),
                selected: _filtre.categorie == e.key,
                onTap: () => _update((f) => f.copyWith(categorie: e.key)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_t('Période de location')),
        Row(
          children: [
            _buildChoiceChip(
              label: _t('Tout'),
              selected: _filtre.periode == null,
              onTap: () => _update((f) => f.copyWith(periode: null)),
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              label: _t('Mensuelle'),
              selected: _filtre.periode == 'Mensuelle',
              onTap: () => _update((f) => f.copyWith(periode: 'Mensuelle')),
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              label: _t('par Nuit'),
              selected: _filtre.periode == 'par Nuit',
              onTap: () => _update((f) => f.copyWith(periode: 'par Nuit')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrixSection() {
    final max = _filtre.borneMax;
    final min = _filtre.prixMin ?? 0;
    final maxSelectionne = (_filtre.prixMax ?? max).clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionTitle(_t('Prix (MRU)'))),
            Text(
              '${_formatPrix(min)} — ${_formatPrix(maxSelectionne)}'
              '${maxSelectionne >= max ? '+' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: pcolor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(min, maxSelectionne.toDouble()),
          min: 0,
          max: max,
          divisions: 40,
          activeColor: pcolor,
          inactiveColor: pcolor.withOpacity(0.2),
          labels: RangeLabels(_formatPrix(min), _formatPrix(maxSelectionne)),
          onChanged: (values) => _update(
            (f) => f.copyWith(
              prixMin: values.start <= 0 ? null : values.start,
              prixMax: values.end >= max ? null : values.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompteurSection({
    required String titre,
    required int valeur,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(titre),
        Row(
          children: List.generate(6, (index) {
            final selected = valeur == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChoiceChip(
                label: index == 0 ? _t('Tout') : '$index+',
                selected: selected,
                onTap: () => onChanged(index),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEquipementsSection() {
    final equipements = <String, ({bool valeur, ValueChanged<bool> onChanged, IconData icone})>{
      'Meublé': (
        valeur: _filtre.meuble,
        onChanged: (v) => _update((f) => f.copyWith(meuble: v)),
        icone: Icons.chair,
      ),
      'Disponible': (
        valeur: _filtre.uniquementDisponibles,
        onChanged: (v) => _update((f) => f.copyWith(uniquementDisponibles: v)),
        icone: Icons.check_circle_outline,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_t('Équipements')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: equipements.entries.map((entry) {
            return _buildChoiceChip(
              label: _t(entry.key),
              icone: entry.value.icone,
              selected: entry.value.valeur,
              onTap: () => entry.value.onChanged(!entry.value.valeur),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icone,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? pcolor : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? pcolor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 16, color: selected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(int resultats) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _filtre),
            style: ElevatedButton.styleFrom(
              backgroundColor: pcolor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              resultats == 0
                  ? _t('Aucun bien trouvé')
                  : '${_t('Voir')} $resultats ${_t(resultats > 1 ? 'biens' : 'bien')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrix(num value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m >= 10 ? m.round() : m.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k >= 10 ? k.round() : k.toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return value.round().toString();
  }
}
