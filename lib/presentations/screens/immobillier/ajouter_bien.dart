import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:akarina/data/data_providers/bien_creation_service.dart';
import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';

/// Formulaire de création d'un bien (réservé aux gestionnaires connectés,
/// `is_staff: true`) : type de bien → détails → médias, contre
/// https://admin-akarina.akarina.shop/api/biens/ puis /api/medias/.
class AjouterBienScreen extends StatefulWidget {
  final String adminToken;

  const AjouterBienScreen({super.key, required this.adminToken});

  @override
  State<AjouterBienScreen> createState() => _AjouterBienScreenState();
}

class _PendingMedia {
  final File file;
  final String typeMedia; // 'image' | 'video'
  const _PendingMedia({required this.file, required this.typeMedia});
}

class _AjouterBienScreenState extends State<AjouterBienScreen> {
  int _step = 0;
  String? _typeBien;

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _typeTransaction = 'location';
  final _prixController = TextEditingController();
  String _unitePrix = 'mois';
  final _uniteAutreController = TextEditingController();
  int? _villeId;
  int? _quartierId;
  final _adresseController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _nbProprietairesController = TextEditingController(text: '1');

  // appartement / duplexe
  bool _meuble = false;
  final _chambresController = TextEditingController();
  final _sallesBainController = TextEditingController();
  final _etagesController = TextEditingController();
  final Set<int> _equipementsChoisis = {};

  // terrain
  final _superficieController = TextEditingController();
  final _longueurController = TextEditingController();
  final _largeurController = TextEditingController();
  final _titreFoncierController = TextEditingController();
  bool _borne = false;

  // ceremonie
  bool _avecService = false;
  final _descriptionServiceController = TextEditingController();
  final _capaciteController = TextEditingController();

  List<Ville> _villes = [];
  List<Equipement> _equipements = [];
  bool _isLoadingRef = true;
  bool _isSubmitting = false;
  String? _erreur;

  int? _createdBienId;
  String? _createdBienReference;
  final List<_PendingMedia> _mediaEnAttente = [];
  bool _isUploadingMedia = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadReferentiels();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _uniteAutreController.dispose();
    _adresseController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _nbProprietairesController.dispose();
    _chambresController.dispose();
    _sallesBainController.dispose();
    _etagesController.dispose();
    _superficieController.dispose();
    _longueurController.dispose();
    _largeurController.dispose();
    _titreFoncierController.dispose();
    _descriptionServiceController.dispose();
    _capaciteController.dispose();
    super.dispose();
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  Future<void> _loadReferentiels() async {
    try {
      final results = await Future.wait([
        BienService().fetchVilles(),
        BienCreationService().fetchEquipements(widget.adminToken),
      ]);
      if (!mounted) return;
      setState(() {
        _villes = results[0] as List<Ville>;
        _equipements = results[1] as List<Equipement>;
        _isLoadingRef = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRef = false);
    }
  }

  List<Quartier> get _quartiersDisponibles {
    if (_villeId == null) return [];
    final ville = _villes.firstWhere((v) => v.id == _villeId, orElse: () => const Ville(id: 0, nom: '', nomAr: ''));
    return ville.quartiers;
  }

  bool get _aEquipements => _typeBien == 'appartement' || _typeBien == 'duplexe';
  bool get _aChambres => _typeBien == 'appartement' || _typeBien == 'duplexe';

  // ================================================================ nombres

  /// Convertit les chiffres arabes-indiens/persans et la virgule décimale
  /// (clavier numérique en locale ar/fr) vers le format attendu par `num.tryParse`.
  String _normaliserNombre(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final ai = arabicIndic.indexOf(ch);
      final pi = persian.indexOf(ch);
      if (ai != -1) {
        buffer.write(ai);
      } else if (pi != -1) {
        buffer.write(pi);
      } else if (ch == ',') {
        buffer.write('.');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  int? _toInt(String text) => int.tryParse(_normaliserNombre(text.trim()));
  double? _toDouble(String text) => double.tryParse(_normaliserNombre(text.trim()));
  num? _toNum(String text) => num.tryParse(_normaliserNombre(text.trim()));

  // ================================================================ soumission

  Map<String, dynamic> _construireBody() {
    final unite = _unitePrix == 'autre' ? _uniteAutreController.text.trim() : _unitePrix;
    final body = <String, dynamic>{
      'titre': _titreController.text.trim(),
      'type_bien': _typeBien,
      'type_transaction': _typeTransaction,
      'unite_prix': unite,
      'ville': _villeId,
      'nb_proprietaires': _toInt(_nbProprietairesController.text) ?? 1,
    };
    if (_descriptionController.text.trim().isNotEmpty) body['description'] = _descriptionController.text.trim();
    final prix = _toNum(_prixController.text);
    if (prix != null) body['prix'] = prix;
    if (_quartierId != null) body['quartier'] = _quartierId;
    if (_adresseController.text.trim().isNotEmpty) body['adresse_complete'] = _adresseController.text.trim();
    final lat = _toDouble(_latController.text);
    if (lat != null) body['latitude'] = lat;
    final lng = _toDouble(_lngController.text);
    if (lng != null) body['longitude'] = lng;

    if (_aChambres) {
      body['meuble'] = _meuble;
      final chambres = _toInt(_chambresController.text);
      if (chambres != null) body['nb_chambres'] = chambres;
      final sdb = _toInt(_sallesBainController.text);
      if (sdb != null) body['nb_salles_bain'] = sdb;
      final etages = _toInt(_etagesController.text);
      if (etages != null) body['nb_etages'] = etages;
    }
    if (_aEquipements) {
      body['equipements_ids'] = _equipementsChoisis.toList();
    }
    if (_typeBien == 'terrain') {
      body['detail_terrain'] = {
        if (_toDouble(_superficieController.text) != null) 'superficie_m2': _toDouble(_superficieController.text),
        if (_toDouble(_longueurController.text) != null) 'longueur_m': _toDouble(_longueurController.text),
        if (_toDouble(_largeurController.text) != null) 'largeur_m': _toDouble(_largeurController.text),
        if (_titreFoncierController.text.trim().isNotEmpty) 'titre_foncier': _titreFoncierController.text.trim(),
        'borne': _borne,
      };
    }
    if (_typeBien == 'ceremonie') {
      body['detail_ceremonie'] = {
        'avec_service': _avecService,
        if (_descriptionServiceController.text.trim().isNotEmpty)
          'description_service': _descriptionServiceController.text.trim(),
        if (_toInt(_capaciteController.text) != null) 'capacite_personnes': _toInt(_capaciteController.text),
      };
    }
    return body;
  }

  bool get _formulaireValide =>
      _titreController.text.trim().isNotEmpty && _villeId != null && _prixController.text.trim().isNotEmpty;

  Future<void> _soumettre() async {
    if (!_formulaireValide) {
      setState(() => _erreur = _t("Veuillez remplir au moins le titre, la ville et le prix."));
      return;
    }
    setState(() {
      _isSubmitting = true;
      _erreur = null;
    });
    try {
      final id = await BienCreationService().creerBien(widget.adminToken, _construireBody());
      if (!mounted) return;
      // On récupère la référence générée côté serveur pour l'affichage final.
      String? reference;
      try {
        final detail = await BienService().fetchBienDetail('$id');
        reference = detail.reference;
      } catch (_) {
        reference = null;
      }
      if (!mounted) return;
      setState(() {
        _createdBienId = id;
        _createdBienReference = reference;
        _isSubmitting = false;
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _erreur = '${_t("Erreur")}: $e';
      });
    }
  }

  // ================================================================ médias

  Future<void> _ajouterPhotos() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() {
      _mediaEnAttente.addAll(files.map((f) => _PendingMedia(file: File(f.path), typeMedia: 'image')));
    });
  }

  Future<void> _ajouterVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _mediaEnAttente.add(_PendingMedia(file: File(file.path), typeMedia: 'video')));
  }

  Future<void> _envoyerMediasEtTerminer() async {
    if (_createdBienId == null) return;
    setState(() => _isUploadingMedia = true);
    var echecs = 0;
    for (final media in _mediaEnAttente) {
      try {
        await BienCreationService().ajouterMedia(
          widget.adminToken,
          bienId: _createdBienId!,
          typeMedia: media.typeMedia,
          fichier: media.file,
        );
      } catch (_) {
        echecs++;
      }
    }
    if (!mounted) return;
    setState(() => _isUploadingMedia = false);
    if (echecs > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$echecs ${_t("média(s) n'ont pas pu être envoyés")}'), backgroundColor: Colors.orange),
      );
    }
    _terminer();
  }

  void _terminer() {
    final reference = _createdBienReference;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => reference != null
            ? ImmobDetails(reference: reference)
            : Scaffold(
                appBar: AppBar(title: Text(_t("Bien créé"))),
                body: Center(child: Text(_t("Le bien a été créé avec succès."))),
              ),
      ),
    );
  }

  // ================================================================ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_t("Ajouter une annonce"), style: const TextStyle(color: kBlackColor)),
        iconTheme: const IconThemeData(color: kBlackColor),
      ),
      body: _isLoadingRef
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _step,
              children: [
                _buildStepType(),
                _buildStepFormulaire(),
                _buildStepMedias(),
              ],
            ),
    );
  }

  // ---------------------------------------------------------- étape 0 : type

  Widget _buildStepType() {
    final types = <Map<String, dynamic>>[
      {'value': 'appartement', 'label': _t('Appartement'), 'icon': Icons.apartment_rounded},
      {'value': 'duplexe', 'label': _t('Duplex'), 'icon': Icons.home_work_rounded},
      {'value': 'commercial', 'label': _t('Commercial'), 'icon': Icons.store_rounded},
      {'value': 'terrain', 'label': _t('Terrain'), 'icon': Icons.landscape_rounded},
      {'value': 'ceremonie', 'label': _t('Maisonceremonie'), 'icon': Icons.celebration_rounded},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t("Quel type de bien souhaitez-vous ajouter ?"),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final t in types)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() {
                  _typeBien = t['value'] as String;
                  _step = 1;
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: pcolor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(t['icon'] as IconData, color: pcolor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(t['label'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- étape 1 : formulaire

  Widget _buildStepFormulaire() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(_t("Type de bien")),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 8),
          _champTexte(_titreController, _t("Titre"), obligatoire: true),
          const SizedBox(height: 14),
          _champTexte(_descriptionController, _t("Description de la maison"), lignes: 3),
          const SizedBox(height: 14),
          _sectionLabel(_t("Type opération")),
          _segments(
            options: [
              {'value': 'location', 'label': _t('alouer')},
              {'value': 'vente', 'label': _t('vendre')},
            ],
            selected: _typeTransaction,
            onChanged: (v) => setState(() => _typeTransaction = v as String),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _champTexte(_prixController, _t("Prix"), clavier: TextInputType.number, obligatoire: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _sectionDropdown<String>(
                  label: _t("Unité"),
                  value: _unitePrix,
                  items: const [
                    {'value': 'mois', 'label': 'mois'},
                    {'value': 'jour', 'label': 'jour'},
                    {'value': '3jours', 'label': '3 jours'},
                    {'value': 'forfait', 'label': 'forfait'},
                    {'value': 'autre', 'label': '…'},
                  ],
                  onChanged: (v) => setState(() => _unitePrix = v as String),
                ),
              ),
            ],
          ),
          if (_unitePrix == 'autre') ...[
            const SizedBox(height: 10),
            _champTexte(_uniteAutreController, _t("Ex: 3jours")),
          ],
          const SizedBox(height: 14),
          _sectionLabel(_t("Ville")),
          _sectionDropdown<int>(
            label: _t("Ville"),
            value: _villeId,
            items: [
              for (final v in _villes) {'value': v.id, 'label': v.nomFor(Localizations.localeOf(context).languageCode)},
            ],
            onChanged: (v) => setState(() {
              _villeId = v as int?;
              _quartierId = null;
            }),
            masquerLabel: true,
          ),
          if (_villeId != null && _quartiersDisponibles.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel(_t("Quartier")),
            _sectionDropdown<int>(
              label: _t("Quartier"),
              value: _quartierId,
              items: [
                for (final q in _quartiersDisponibles)
                  {'value': q.id, 'label': q.nomFor(Localizations.localeOf(context).languageCode)},
              ],
              onChanged: (v) => setState(() => _quartierId = v as int?),
              masquerLabel: true,
            ),
          ],
          const SizedBox(height: 14),
          _champTexte(_adresseController, _t("Adresse complète")),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _champTexte(_latController, _t("Latitude"), clavier: const TextInputType.numberWithOptions(decimal: true, signed: true))),
              const SizedBox(width: 10),
              Expanded(child: _champTexte(_lngController, _t("Longitude"), clavier: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            ],
          ),
          const SizedBox(height: 14),
          _champTexte(_nbProprietairesController, _t("Nombre de propriétaires"), clavier: TextInputType.number),

          if (_aChambres) ...[
            const SizedBox(height: 22),
            _sectionLabel(_t("Caractéristiques")),
            Row(
              children: [
                Expanded(child: Text(_t("Meublé"), style: const TextStyle(fontWeight: FontWeight.w600))),
                Switch(value: _meuble, activeColor: pcolor, onChanged: (v) => setState(() => _meuble = v)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _champTexte(_chambresController, _t("Chambres"), clavier: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _champTexte(_sallesBainController, _t("Salle de bain"), clavier: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _champTexte(_etagesController, _t("Étages"), clavier: TextInputType.number)),
              ],
            ),
          ],

          if (_aEquipements) ...[
            const SizedBox(height: 22),
            _sectionLabel(_t("Équipements")),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipements.map((eq) {
                final selectionne = _equipementsChoisis.contains(eq.id);
                return FilterChip(
                  label: Text(eq.nomFor(Localizations.localeOf(context).languageCode)),
                  selected: selectionne,
                  selectedColor: pcolor.withOpacity(0.15),
                  checkmarkColor: pcolor,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _equipementsChoisis.add(eq.id);
                    } else {
                      _equipementsChoisis.remove(eq.id);
                    }
                  }),
                );
              }).toList(),
            ),
          ],

          if (_typeBien == 'terrain') ...[
            const SizedBox(height: 22),
            _sectionLabel(_t("Détails du terrain")),
            Row(
              children: [
                Expanded(child: _champTexte(_superficieController, _t("Superficie (m²)"), clavier: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _champTexte(_longueurController, _t("Longueur (m)"), clavier: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _champTexte(_largeurController, _t("Largeur (m)"), clavier: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            _champTexte(_titreFoncierController, _t("Titre foncier")),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(_t("Borné"), style: const TextStyle(fontWeight: FontWeight.w600))),
                Switch(value: _borne, activeColor: pcolor, onChanged: (v) => setState(() => _borne = v)),
              ],
            ),
          ],

          if (_typeBien == 'ceremonie') ...[
            const SizedBox(height: 22),
            _sectionLabel(_t("Détails de la salle")),
            Row(
              children: [
                Expanded(child: Text(_t("Avec service (traiteur, décoration...)"), style: const TextStyle(fontWeight: FontWeight.w600))),
                Switch(value: _avecService, activeColor: pcolor, onChanged: (v) => setState(() => _avecService = v)),
              ],
            ),
            const SizedBox(height: 10),
            if (_avecService) _champTexte(_descriptionServiceController, _t("Description du service"), lignes: 2),
            const SizedBox(height: 10),
            _champTexte(_capaciteController, _t("Capacité (personnes)"), clavier: TextInputType.number),
          ],

          if (_erreur != null) ...[
            const SizedBox(height: 16),
            Text(_erreur!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _soumettre,
              style: ElevatedButton.styleFrom(
                backgroundColor: pcolor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_t("Publier l'annonce"), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      );

  Widget _champTexte(
    TextEditingController controller,
    String label, {
    bool obligatoire = false,
    int lignes = 1,
    TextInputType? clavier,
  }) {
    return TextField(
      controller: controller,
      maxLines: lignes,
      keyboardType: clavier,
      decoration: InputDecoration(
        labelText: obligatoire ? '$label *' : label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _segments({required List<Map<String, dynamic>> options, required dynamic selected, required ValueChanged<dynamic> onChanged}) {
    return Row(
      children: options.map((o) {
        final actif = selected == o['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(o['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: actif ? pcolor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: actif ? pcolor : Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(o['label'] as String, style: TextStyle(color: actif ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionDropdown<T>({
    required String label,
    required T? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<dynamic> onChanged,
    bool masquerLabel = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: TextStyle(color: Colors.grey[500])),
          items: items.map((i) => DropdownMenuItem<dynamic>(value: i['value'], child: Text(i['label'] as String))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------- étape 2 : médias

  Widget _buildStepMedias() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t("Bien créé avec succès. Ajoutez des photos et une vidéo (facultatif)."),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_createdBienReference != null) ...[
            const SizedBox(height: 8),
            Text('${_t("Référence")}: $_createdBienReference', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ajouterPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_t("Photos")),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ajouterVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(_t("Vidéo")),
                ),
              ),
            ],
          ),
          if (_mediaEnAttente.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _mediaEnAttente.map((m) {
                final index = _mediaEnAttente.indexOf(m);
                return Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                        image: m.typeMedia == 'image'
                            ? DecorationImage(image: FileImage(m.file), fit: BoxFit.cover)
                            : null,
                      ),
                      child: m.typeMedia == 'video'
                          ? const Icon(Icons.videocam_rounded, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: InkWell(
                        onTap: () => setState(() => _mediaEnAttente.removeAt(index)),
                        child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 13, color: Colors.white)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploadingMedia ? null : _envoyerMediasEtTerminer,
              style: ElevatedButton.styleFrom(
                backgroundColor: pcolor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isUploadingMedia
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_mediaEnAttente.isEmpty ? _t("Terminer") : _t("Envoyer et terminer"), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          if (_mediaEnAttente.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(onPressed: _terminer, child: Text(_t("Passer cette étape"))),
            ),
          ],
        ],
      ),
    );
  }
}
