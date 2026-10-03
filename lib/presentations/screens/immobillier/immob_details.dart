import 'package:akarina/data/data_providers/bien_detail_cache.dart';
import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/data_providers/biens_similaires_service.dart';
import 'package:akarina/data/data_providers/indisponibilite_service.dart';
import 'package:akarina/data/data_providers/transaction_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/data/models/transaction.dart' as tx_model;
import 'package:akarina/data/services/geo_service.dart';
import 'package:akarina/presentations/components/map/property_3d_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:akarina/presentations/components/media/virtual_tour_view.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';
import 'package:akarina/presentations/screens/immobillier/full_images.dart';
import 'package:akarina/presentations/screens/immobillier/reservation.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:akarina/presentations/utils/price_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class ImmobDetails extends StatefulWidget {
  final String reference;

  const ImmobDetails({super.key, required this.reference});

  @override
  State<ImmobDetails> createState() => _ImmobDetailsState();
}

class _ImmobDetailsState extends State<ImmobDetails> {
  final BienService _service = BienService();
  final IndisponibiliteService _indispoService = IndisponibiliteService();
  final BiensSimilairesService _similairesService = BiensSimilairesService();

  static const String _numeroParDefaut = '20203000';

  bool isLoading = true;
  Bien? bien;
  String? villeNom;
  String? quartierNom;
  String language = ARABIC;
  bool hasInternetConnection = true;

  List<PeriodeIndisponibilite> _periodes = const [];
  bool _periodesLoading = false;

  List<BienResume> _similaires = const [];
  bool _similairesLoading = false;

  bool _reservationEnCours = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  String _t(String key, [String? fallback]) => getTranslated(context, key) ?? fallback ?? key;

  bool get _isRtl => Localizations.localeOf(context).languageCode == 'ar';
  bool get _arabe => language == ARABIC;

  // ================================================================ data

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (!mounted) return;
    setState(() => hasInternetConnection = hasConnection);
    if (!hasConnection) return;

    language = await getCurrentLanguage(context);
    await _fetchBien();
  }

  Future<void> _fetchBien({bool silencieux = false}) async {
    if (!silencieux) setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _service.fetchBienDetail(widget.reference),
        _service.fetchVilles(),
      ]);
      final fetched = results[0] as Bien;
      final villes = results[1] as List<Ville>;

      Ville? matchedVille;
      for (final v in villes) {
        if (v.id == fetched.villeId) {
          matchedVille = v;
          break;
        }
      }
      Quartier? matchedQuartier;
      for (final q in matchedVille?.quartiers ?? const <Quartier>[]) {
        if (q.id == fetched.quartierId) {
          matchedQuartier = q;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        bien = fetched;
        villeNom = matchedVille?.nomFor(language);
        quartierNom = matchedQuartier?.nomFor(language);
        isLoading = false;
      });
      await Future.wait([
        _fetchIndisponibilites(fetched),
        _fetchSimilaires(fetched),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchIndisponibilites(Bien b) async {
    setState(() {
      _periodes = _periodesDepuisBien(b);
      _periodesLoading = true;
    });
    try {
      final periodes = await _indispoService.fetchPourBien(b.id);
      if (!mounted) return;
      setState(() {
        _periodes = periodes;
        _periodesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _periodesLoading = false);
    }
  }

  List<PeriodeIndisponibilite> _periodesDepuisBien(Bien b) => b.indisponibilites
      .where((i) => i.dateDebut != null && i.dateFin != null)
      .map((i) => PeriodeIndisponibilite(debut: i.dateDebut!, fin: i.dateFin!, motif: i.motif))
      .toList();

  Future<void> _fetchSimilaires(Bien b) async {
    setState(() => _similairesLoading = true);
    try {
      final liste = await _similairesService.similairesA(
        excludeId: b.id,
        typeTransaction: b.isVente ? 'vente' : 'location',
        villeId: b.villeId,
        quartierId: b.quartierId,
        meuble: b.meuble,
        nbChambres: b.nbChambres,
        prix: double.tryParse('${b.prix ?? ''}'),
      );
      if (!mounted) return;
      setState(() {
        _similaires = liste;
        _similairesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _similaires = const [];
        _similairesLoading = false;
      });
    }
  }

  // ================================================================ build

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          setState(() => hasInternetConnection = hasConnection);
          if (hasConnection) _initializeData();
        },
      );
    }

    if (isLoading) {
      return _buildEtatScaffold(body: Center(child: CircularProgressIndicator(color: pcolor)));
    }

    if (bien == null) {
      return _buildEtatScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_outlined, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(_t("Aucune donnée trouvée."), style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchBien,
                style: OutlinedButton.styleFrom(
                  foregroundColor: pcolor,
                  side: BorderSide(color: pcolor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_t('Réessayer')),
              ),
            ],
          ),
        ),
      );
    }

    final b = bien!;
    final sections = <Widget>[
      _buildGestionnairesSection(b),
      if ((b.descriptionFor(language) ?? '').trim().isNotEmpty)
        _section(
          icon: Icons.notes_rounded,
          title: _t("Description de la maison"),
          child: _ExpandableText(text: b.descriptionFor(language)!.trim()),
        ),
      if (b.equipements.isNotEmpty) _buildEquipementsSection(b),
      _section(
        icon: Icons.calendar_month_rounded,
        title: _t("Calendrier de disponibilité"),
        child: _AvailabilityCalendar(periodes: _periodes, loading: _periodesLoading),
      ),
      if (b.medias.any((m) => m.isVideo)) _buildVideoSection(b),
      _buildMapSection(b),
      if (_similairesLoading || _similaires.isNotEmpty) _buildSimilairesSection(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(b),
      body: RefreshableWidget(
        onRefresh: () => _fetchBien(silencieux: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0.6,
              leading: IconButton(
                icon: Icon(_isRtl ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2, color: kBlackColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _t("Détails de l'immobilier"),
                style: const TextStyle(color: kBlackColor, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _buildPhotoMosaic(b),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleBlock(b),
                        const SizedBox(height: 18),
                        _buildQuickFacts(b),
                        for (final s in sections) ...[_divider(), s],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtatScaffold({required Widget body}) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_isRtl ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2, color: kBlackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t("Détails de l'immobilier"),
          style: const TextStyle(color: kBlackColor, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: body,
    );
  }

  // ================================================================ helpers UI

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      );

  Widget _section({
    required String title,
    required Widget child,
    IconData? icon,
    String? subtitle,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 21, color: pcolor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _chip(String text, {required Color color, Color? background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _lieu(Bien b) =>
      b.adresseFor(language) ?? [quartierNom, villeNom].where((e) => (e ?? '').isNotEmpty).join(', ');

  String _typeBienLabel(String typeBien) {
    switch (typeBien) {
      case 'appartement':
        return 'Appartement';
      case 'duplexe':
        return 'Duplex';
      case 'commercial':
        return 'Commercial';
      case 'terrain':
        return 'Terrain';
      case 'ceremonie':
        return 'Maisonceremonie';
      default:
        return typeBien;
    }
  }

  String _prixTexte(Bien b) {
    final unitLabel = b.uniteprix == 'forfait' ? '' : '/${_t(b.uniteprix)}';
    return b.prix != null ? '${formatAmount(b.prix)} ${_t("MRU")}$unitLabel' : _t('Prix sur demande');
  }

  // ================================================================ photos

  /// Toutes les photos dans une seule carte : 1 grande + jusqu'à 3 petites.
  /// Chaque photo s'ouvre en plein écran ; « +N » s'il en reste d'autres.
  Widget _buildPhotoMosaic(Bien b) {
    final medias = b.medias
        .map((m) => TourMediaItem(url: m.fichier, isVideo: m.isVideo))
        .where((m) => m.url.isNotEmpty)
        .toList();
    final photosMedias = medias.where((m) => !m.isVideo).map((m) => m.url).toList();
    final hasVideo = medias.any((m) => m.isVideo);
    final photos = photosMedias.isNotEmpty
        ? photosMedias
        : (b.photoPrincipale != null ? [b.photoPrincipale!] : <String>[]);
    final n = photos.length;
    const gap = 3.0;

    Widget tile(int i, {int restant = 0}) {
      return GestureDetector(
        onTap: () => _openGallery(photos, i),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _networkImage(photos[i]),
            if (restant > 0)
              Container(
                color: Colors.black.withOpacity(0.5),
                alignment: Alignment.center,
                child: Text(
                  '+$restant',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      );
    }

    Widget contenu;
    if (n == 0) {
      contenu = _buildHeroFallback(hasVideo, medias);
    } else if (n == 1) {
      contenu = tile(0);
    } else if (n == 2) {
      contenu = Row(children: [
        Expanded(child: tile(0)),
        const SizedBox(width: gap),
        Expanded(child: tile(1)),
      ]);
    } else if (n == 3) {
      contenu = Row(children: [
        Expanded(flex: 2, child: tile(0)),
        const SizedBox(width: gap),
        Expanded(
          child: Column(children: [
            Expanded(child: tile(1)),
            const SizedBox(height: gap),
            Expanded(child: tile(2)),
          ]),
        ),
      ]);
    } else {
      contenu = Column(children: [
        Expanded(flex: 3, child: tile(0)),
        const SizedBox(height: gap),
        Expanded(
          flex: 2,
          child: Row(children: [
            Expanded(child: tile(1)),
            const SizedBox(width: gap),
            Expanded(child: tile(2)),
            const SizedBox(width: gap),
            Expanded(child: tile(3, restant: n - 4)),
          ]),
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: n >= 4 ? getProportionateScreenHeight(320) : getProportionateScreenHeight(250),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              contenu,
              if (hasVideo)
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: VirtualTourBadge(onTap: () => _ouvrirVisiteVirtuelle(medias)),
                ),
              if (n > 1)
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: Material(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openGallery(photos, 0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.grid_view_rounded, size: 14, color: Colors.black87),
                            const SizedBox(width: 5),
                            Text(
                              '$n ${_t('photos', 'photos')}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: Colors.grey[200]);
      },
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey[200],
        child: Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildHeroFallback(bool hasVideo, List<TourMediaItem> medias) {
    return GestureDetector(
      onTap: hasVideo ? () => _ouvrirVisiteVirtuelle(medias) : null,
      child: Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(hasVideo ? Icons.videocam_outlined : Icons.home_outlined, size: 60, color: Colors.grey[400]),
        ),
      ),
    );
  }

  void _openGallery(List<String> photos, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenImageView(imageUrls: photos, initialIndex: index)),
    );
  }

  void _ouvrirVisiteVirtuelle(List<TourMediaItem> medias) {
    VirtualTourView.open(context, medias: medias, titre: bien != null ? bien!.titreFor(language) : '');
  }

  // ================================================================ titre

  Widget _buildTitleBlock(Bien b) {
    final lieu = _lieu(b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(_t(_typeBienLabel(b.typeBien), b.typeBien), color: pcolor),
                  _chip(
                    b.isVente ? _t('vendre') : _t('alouer'),
                    color: Colors.blueGrey.shade700,
                    background: Colors.blueGrey.shade50,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusPill(b),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          b.titreFor(language),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
        ),
        if (lieu.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 17, color: pcolor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lieu,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (b.reference.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Clipboard.setData(ClipboardData(text: b.reference));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_t('Référence copiée')), duration: const Duration(seconds: 1)),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  b.reference,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 5),
                Icon(Icons.copy_rounded, size: 13, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusPill(Bien b) {
    final estVendu = b.vendu;
    final color = estVendu ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            estVendu ? _t('Unavailable', 'Indisponible') : _t('Available', 'Disponible'),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color.shade800),
          ),
        ],
      ),
    );
  }

  // ================================================================ caractéristiques

  /// Ligne simple, sans carte ni fond : icône + valeur + libellé.
  Widget _buildQuickFacts(Bien b) {
    final facts = <_Fact>[
      if ((b.nbChambres ?? 0) > 0) _Fact(Icons.king_bed_outlined, '${b.nbChambres}', _t("Chambres")),
      if ((b.nbSallesBain ?? 0) > 0) _Fact(Icons.bathtub_outlined, '${b.nbSallesBain}', _t("Salle de bain")),
      if ((b.nbEtages ?? 0) > 0) _Fact(Icons.stairs_outlined, '${b.nbEtages}', _t("avec")),
      _Fact(Icons.chair_outlined, b.meuble ? _t("Meubler") : _t("pas Meubler"), null),
    ];

    final children = <Widget>[];
    for (var i = 0; i < facts.length; i++) {
      if (i > 0) children.add(Container(width: 1, height: 34, color: Colors.grey.shade200));
      final f = facts[i];
      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.icon, size: 22, color: Colors.grey[800]),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  f.label == null ? f.valeur : '${f.valeur} ${f.label}',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(children: children);
  }

  // ================================================================ gestionnaires

  String _numeroWhatsApp(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 8 ? '222$digits' : digits;
  }

  Future<void> _launchWhatsApp(String phone) async {
    final message = Uri.encodeComponent("Bonjour, je vous contacte depuis l'application");
    final url = Uri.parse('https://wa.me/${_numeroWhatsApp(phone)}?text=$message');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchPhone(String phone) async {
    try {
      await launchUrl(Uri.parse('tel:$phone'));
    } catch (_) {}
  }

  Widget _buildGestionnairesSection(Bien b) {
    final gestionnaires = b.gestionnaires.where((g) => (g.telephone ?? '').trim().isNotEmpty).toList();

    return _section(
      icon: Icons.support_agent_rounded,
      title: gestionnaires.isEmpty ? _t("Contact") : _t("Gestionnaires"),
      child: gestionnaires.isEmpty
          ? _buildGestionnaireRow(nom: _t("Contact"), telephone: _numeroParDefaut)
          : Column(
              children: [
                for (var i = 0; i < gestionnaires.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildGestionnaireRow(
                    nom: gestionnaires[i].nomAffiche,
                    telephone: gestionnaires[i].telephone!.trim(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildGestionnaireRow({required String nom, required String telephone}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: pcolor.withOpacity(0.12),
          child: Text(
            nom.isNotEmpty ? nom[0].toUpperCase() : '?',
            style: TextStyle(color: pcolor, fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nom,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              PriceText(telephone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _circleButton(
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          onTap: () => _launchWhatsApp(telephone),
        ),
        const SizedBox(width: 8),
        _circleButton(icon: Icons.call_rounded, color: pcolor, onTap: () => _launchPhone(telephone)),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }

  // ================================================================ équipements

  static const Map<String, IconData> _equipementIcons = {
    'alarme': Icons.security_rounded,
    'ascenseur': Icons.elevator_rounded,
    'balcon': Icons.balcony_rounded,
    'camera': Icons.videocam_rounded,
    'chambre_service': Icons.meeting_room_rounded,
    'climatisation': Icons.ac_unit_rounded,
    'cour': Icons.deck_rounded,
    'garage': Icons.garage_rounded,
    'jardin': Icons.local_florist_rounded,
    'parking': Icons.local_parking_rounded,
    'piscine': Icons.pool_rounded,
  };

  Widget _buildEquipementsSection(Bien b) {
    return _section(
      icon: Icons.verified_outlined,
      title: _t("Équipements"),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: b.equipements.map((eq) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_equipementIcons[eq.icone] ?? Icons.check_circle_outline_rounded, size: 17, color: pcolor),
                const SizedBox(width: 7),
                Text(eq.nomFor(language), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================================================================ vidéo

  Widget _buildVideoSection(Bien b) {
    final video = b.medias.firstWhere((m) => m.isVideo);
    return _section(
      icon: Icons.play_circle_outline_rounded,
      title: _t("Vidéo de présentation"),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(key: ValueKey(video.fichier), videoUrl: video.fichier, embedded: true),
        ),
      ),
    );
  }

  // ================================================================ carte

  Widget _buildMapSection(Bien b) {
    final position = (b.latitude != null && b.longitude != null)
        ? LatLng(b.latitude!, b.longitude!)
        : GeoService.nouakchott;
    final lieu = _lieu(b);

    return _section(
      icon: Icons.map_outlined,
      title: _t("Localisation du maison"),
      subtitle: lieu,
      trailing: _chip(_t("Vue 3D"), color: pcolor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Property3DMap(
          position: position,
          titre: lieu.isNotEmpty ? lieu : b.titreFor(language),
          positionApproximative: b.latitude == null || b.longitude == null,
          hauteur: getProportionateScreenHeight(240),
        ),
      ),
    );
  }

  // ================================================================ biens similaires

  String _prixResume(BienResume r) {
    if (r.prix == null) return _t('Prix sur demande');
    final montant = NumberFormat('#,##0', 'en_US').format(r.prix).replaceAll(',', ' ');
    final unite = (r.unitePrix.isEmpty || r.unitePrix == 'forfait') ? '' : '/${_t(r.unitePrix)}';
    return '$montant ${_t("MRU")}$unite';
  }

  Widget _buildSimilairesSection() {
    const hauteur = 264.0;
    return _section(
      icon: Icons.holiday_village_outlined,
      title: _t('Biens similaires', 'Biens similaires'),
      child: SizedBox(
        height: hauteur,
        child: _similairesLoading
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, __) => SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(14)),
                      ),
                      const SizedBox(height: 12),
                      Container(height: 14, width: 120, color: Colors.grey[200]),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 170, color: Colors.grey[100]),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _similaires.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final r = _similaires[i];
                  return _SimilaireCard(
                    bien: r,
                    arabe: _arabe,
                    prixTexte: _prixResume(r),
                    meubleLabel: r.meuble ? _t("Meubler") : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ImmobDetails(reference: r.reference)),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ================================================================ barre du bas

  /// Plus de boutons WhatsApp/Appeler ici : le contact direct se fait
  /// désormais depuis la section Gestionnaires. La barre du bas ne propose
  /// que la réservation, qui exige d'être connecté.
  Widget _buildBottomBar(Bien b) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      b.isVente ? _t('vendre') : _t('alouer'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    PriceText(
                      _prixTexte(b),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (b.vendu || _reservationEnCours) ? null : () => _handleReserver(b),
                icon: _reservationEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.event_available_rounded, size: 19),
                label: Text(_t('Réserver'), style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================ réservation

  Future<void> _handleReserver(Bien b) async {
    if (_reservationEnCours) return;
    const storage = FlutterSecureStorage();
    final adminToken = await storage.read(key: 'admin_token');
    if (!mounted) return;

    if (adminToken == null || adminToken.isEmpty) {
      _showLoginRequiredDialog();
      return;
    }

    if (b.isVente) {
      await _reserverVente(b, adminToken);
    } else {
      await _reserverLocation(b, adminToken);
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t('Connexion requise')),
        content: Text(_t('Vous devez être connecté pour réserver ce bien.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Annuler')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pcolor, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IndexLogin()));
            },
            child: Text(_t('Se connecter')),
          ),
        ],
      ),
    );
  }

  Future<void> _reserverVente(Bien b, String adminToken) async {
    final montant = double.tryParse(b.prix ?? '') ?? 0;
    final confirme = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationVenteSheet(prixTexte: _prixTexte(b), titre: b.titreFor(language)),
    );
    if (confirme != true) return;
    await _envoyerTransaction(
      bienId: b.id,
      typeTransaction: 'vente',
      montant: montant,
      adminToken: adminToken,
    );
  }

  Future<void> _reserverLocation(Bien b, String adminToken) async {
    final periodesReservees = _periodes
        .map((p) => {
              'date_debut': p.debut.toIso8601String(),
              'date_fin': p.fin.toIso8601String(),
            })
        .toList();

    final resultat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReservationLocationSheet(bien: b, periodesReservees: periodesReservees),
    );
    if (resultat == null) return;

    await _envoyerTransaction(
      bienId: b.id,
      typeTransaction: 'location',
      montant: resultat['montant'] as num,
      adminToken: adminToken,
      dateDebut: resultat['debut'] as DateTime,
      dateFin: resultat['fin'] as DateTime,
    );
  }

  Future<void> _envoyerTransaction({
    required int bienId,
    required String typeTransaction,
    required num montant,
    required String adminToken,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    setState(() => _reservationEnCours = true);
    try {
      final transaction = await TransactionService().creerTransaction(
        adminToken: adminToken,
        bienId: bienId,
        typeTransaction: typeTransaction,
        montantTotal: montant,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );
      if (!mounted) return;
      setState(() => _reservationEnCours = false);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _TransactionConfirmationSheet(transaction: transaction),
      );
      if (bien != null) _fetchIndisponibilites(bien!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _reservationEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t("Erreur")}: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _Fact {
  final IconData icon;
  final String valeur;
  final String? label;

  const _Fact(this.icon, this.valeur, this.label);
}

// ==================================================================== carte bien similaire

class _SimilaireCard extends StatefulWidget {
  final BienResume bien;
  final bool arabe;
  final String prixTexte;
  final String? meubleLabel;
  final VoidCallback onTap;

  const _SimilaireCard({
    required this.bien,
    required this.arabe,
    required this.prixTexte,
    required this.meubleLabel,
    required this.onTap,
  });

  @override
  State<_SimilaireCard> createState() => _SimilaireCardState();
}

class _SimilaireCardState extends State<_SimilaireCard> {
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _checkForVideo();
  }

  /// La liste `/api/biens/` ne renvoie pas les médias : on va chercher le
  /// détail (mis en cache, voir [BienDetailCache]) pour savoir s'il y a une
  /// vidéo à proposer directement depuis cette carte.
  Future<void> _checkForVideo() async {
    try {
      final detail = await BienDetailCache.fetch(widget.bien.reference);
      if (!mounted) return;
      final videos = detail.medias.where((m) => m.isVideo);
      if (videos.isNotEmpty) {
        setState(() => _videoUrl = videos.first.fichier);
      }
    } catch (_) {
      // Best-effort : en cas d'échec on affiche simplement la photo.
    }
  }

  void _openVideo() {
    final url = _videoUrl;
    if (url == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerWidget(videoUrl: url)));
  }

  @override
  Widget build(BuildContext context) {
    final bien = widget.bien;
    final lieu = bien.lieuFor(widget.arabe);
    final hasVideo = _videoUrl != null;

    return SizedBox(
      width: 220,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    bien.photoPrincipale != null
                        ? Image.network(
                            bien.photoPrincipale!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                            loadingBuilder: (context, child, progress) =>
                                progress == null ? child : Container(color: Colors.grey[200]),
                          )
                        : _placeholder(),
                    if (hasVideo)
                      Positioned.fill(
                        child: Material(
                          color: Colors.black.withOpacity(0.18),
                          child: InkWell(
                            onTap: _openVideo,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.meubleLabel != null)
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.meubleLabel!,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            PriceText(
              widget.prixTexte,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              bien.titreFor(widget.arabe),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            if (lieu.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      lieu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if ((bien.nbChambres ?? 0) > 0) ...[
                  Icon(Icons.king_bed_outlined, size: 15, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text('${bien.nbChambres}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  const SizedBox(width: 12),
                ],
                if ((bien.nbSallesBain ?? 0) > 0) ...[
                  Icon(Icons.bathtub_outlined, size: 15, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text('${bien.nbSallesBain}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: Icon(Icons.home_outlined, size: 40, color: Colors.grey[400]),
      );
}

// ==================================================================== calendrier

class _AvailabilityCalendar extends StatefulWidget {
  final List<PeriodeIndisponibilite> periodes;
  final bool loading;

  const _AvailabilityCalendar({required this.periodes, required this.loading});

  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  final DateFormat _format = DateFormat('dd/MM/yyyy');
  late DateTime _focusedDay;

  DateTime get _aujourdhui {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = _aujourdhui;
  }

  String _t(String key, String fallback) => getTranslated(context, key) ?? fallback;

  bool _bloque(DateTime day) => widget.periodes.any((p) => p.contient(day));

  DateTime _prochaineDispo(DateTime from) {
    var d = from;
    for (var i = 0; i < 1000 && _bloque(d); i++) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final today = _aujourdhui;
    final firstDay = DateTime(today.year, today.month, 1);
    var lastDay = DateTime(today.year + 1, today.month + 1, 0);
    for (final p in widget.periodes) {
      if (p.fin.isAfter(lastDay)) lastDay = DateTime(p.fin.year, p.fin.month + 1, 0);
    }
    final focused = _focusedDay.isBefore(firstDay)
        ? firstDay
        : (_focusedDay.isAfter(lastDay) ? lastDay : _focusedDay);

    final aVenir = widget.periodes.where((p) => !p.fin.isBefore(today)).toList()
      ..sort((a, b) => a.debut.compareTo(b.debut));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBanner(today),
        if (widget.loading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(minHeight: 2, color: pcolor, backgroundColor: pcolor.withOpacity(0.1)),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TableCalendar(
            locale: Localizations.localeOf(context).languageCode,
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: ''},
            availableGestures: AvailableGestures.horizontalSwipe,
            rowHeight: 46,
            daysOfWeekHeight: 26,
            onPageChanged: (day) => _focusedDay = day,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.black87),
              headerPadding: const EdgeInsets.symmetric(vertical: 6),
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
              leftChevronIcon: _chevron(Icons.chevron_left_rounded),
              rightChevronIcon: _chevron(Icons.chevron_right_rounded),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
            ),
            calendarStyle: const CalendarStyle(outsideDaysVisible: false, cellMargin: EdgeInsets.zero),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _dayCell(day, today),
              todayBuilder: (context, day, _) => _dayCell(day, today),
              disabledBuilder: (context, day, _) => _dayCell(day, today),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(),
        if (aVenir.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            _t('Périodes indisponibles', 'Périodes indisponibles'),
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ...aVenir.map((p) => _buildPeriodeCard(p, today)),
        ],
      ],
    );
  }

  Widget _chevron(IconData icon) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black87),
      );

  Widget _dayCell(DateTime day, DateTime today) {
    final d = DateTime(day.year, day.month, day.day);
    final passe = d.isBefore(today);
    final estAujourdhui = isSameDay(d, today);

    if (_bloque(d)) {
      final prev = DateTime(d.year, d.month, d.day - 1);
      final next = DateTime(d.year, d.month, d.day + 1);
      final debutReel = !_bloque(prev);
      final finReel = !_bloque(next);
      final arrondiDebut = debutReel || d.weekday == DateTime.monday || d.day == 1;
      final arrondiFin = finReel || d.weekday == DateTime.sunday || next.month != d.month;
      const r = Radius.circular(12);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: passe ? Colors.red.shade50.withOpacity(0.5) : Colors.red.shade50,
          borderRadius: BorderRadiusDirectional.horizontal(
            start: arrondiDebut ? r : Radius.zero,
            end: arrondiFin ? r : Radius.zero,
          ),
        ),
        alignment: Alignment.center,
        child: (debutReel || finReel) && !passe
            ? Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle),
                child: Text(
                  '${d.day}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              )
            : Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: passe ? Colors.red.shade200 : Colors.red.shade700,
                ),
              ),
      );
    }

    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: estAujourdhui
            ? BoxDecoration(
                shape: BoxShape.circle,
                color: pcolor.withOpacity(0.08),
                border: Border.all(color: pcolor, width: 1.5),
              )
            : null,
        child: Text(
          '${d.day}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: estAujourdhui ? FontWeight.w800 : FontWeight.w500,
            color: passe ? Colors.grey.shade400 : (estAujourdhui ? pcolor : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(DateTime today) {
    final IconData icon;
    final Color color;
    final String titre;
    final String detail;

    if (_bloque(today)) {
      icon = Icons.event_busy_rounded;
      color = Colors.red.shade600;
      titre = _t('Indisponible actuellement', 'Indisponible actuellement');
      detail = '${_t('Disponible à partir du', 'Disponible à partir du')} ${_format.format(_prochaineDispo(today))}';
    } else {
      final prochaines = widget.periodes.where((p) => p.debut.isAfter(today)).toList()
        ..sort((a, b) => a.debut.compareTo(b.debut));
      icon = Icons.event_available_rounded;
      color = Colors.green.shade600;
      titre = _t('Disponible maintenant', 'Disponible maintenant');
      detail = prochaines.isEmpty
          ? _t('Aucune réservation prévue', 'Aucune réservation prévue')
          : '${_t('Prochaine indisponibilité le', 'Prochaine indisponibilité le')} ${_format.format(prochaines.first.debut)}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _legendItem(
          BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
          _t('Disponible', 'Disponible'),
        ),
        _legendItem(
          BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
          _t('Indisponible', 'Indisponible'),
        ),
        _legendItem(
          BoxDecoration(shape: BoxShape.circle, border: Border.all(color: pcolor, width: 1.5)),
          _t("Aujourd'hui", "Aujourd'hui"),
        ),
      ],
    );
  }

  Widget _legendItem(BoxDecoration decoration, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: decoration),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPeriodeCard(PeriodeIndisponibilite p, DateTime today) {
    final enCours = p.contient(today);
    final pillColor = enCours ? Colors.red : Colors.orange;
    final details = '${p.nbJours} ${_t('jours', 'jours')}${p.motif.isNotEmpty ? ' · ${p.motif}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(color: pillColor.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_format.format(p.debut)}  –  ${_format.format(p.fin)}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(details, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: pillColor.shade50, borderRadius: BorderRadius.circular(20)),
            child: Text(
              enCours ? _t('En cours', 'En cours') : _t('À venir', 'À venir'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pillColor.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== description

class _ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const _ExpandableText({required this.text, this.trimLines = 4});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 14.5, color: Colors.grey[800], height: 1.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.trimLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final depasse = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              alignment: AlignmentDirectional.topStart,
              child: Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : widget.trimLines,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
            if (depasse) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded
                            ? (getTranslated(context, "Voir moins") ?? "Voir moins")
                            : (getTranslated(context, "Voir plus") ?? "Voir plus"),
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: pcolor),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: pcolor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ==================================================================== réservation

class _ConfirmationVenteSheet extends StatelessWidget {
  final String prixTexte;
  final String titre;

  const _ConfirmationVenteSheet({required this.prixTexte, required this.titre});

  String _t(BuildContext context, String key) => getTranslated(context, key) ?? key;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(_t(context, 'Confirmer la réservation'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              titre,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.sell_rounded, color: pcolor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_t(context, 'Montant'), style: TextStyle(color: Colors.grey[700]))),
                  PriceText(prixTexte, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_t(context, 'Confirmer'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionConfirmationSheet extends StatelessWidget {
  final tx_model.Transaction transaction;

  const _TransactionConfirmationSheet({required this.transaction});

  String _t(BuildContext context, String key) => getTranslated(context, key) ?? key;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t(context, 'Référence copiée')), duration: const Duration(seconds: 1)),
    );
  }

  Widget _infoRow(BuildContext context, {required IconData icon, required String label, required Widget value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
          value,
        ],
      ),
    );
  }

  Widget _copiableRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _copy(context, value),
      child: _infoRow(
        context,
        icon: icon,
        label: label,
        value: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 5),
            Icon(Icons.copy_rounded, size: 13, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVente = transaction.typeTransaction == 'vente';
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.green.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t(context, 'Réservation envoyée'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _t(context, "Votre demande de réservation a bien été envoyée."),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _copiableRow(
                    context,
                    icon: Icons.receipt_long_rounded,
                    label: _t(context, 'Référence transaction'),
                    value: transaction.reference,
                  ),
                  const Divider(height: 1),
                  _copiableRow(
                    context,
                    icon: Icons.tag_rounded,
                    label: _t(context, 'Référence du bien'),
                    value: transaction.bienReference,
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    context,
                    icon: isVente ? Icons.sell_rounded : Icons.calendar_month_rounded,
                    label: _t(context, 'Type'),
                    value: Text(
                      isVente ? _t(context, 'Vente') : _t(context, 'Location'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    context,
                    icon: Icons.payments_rounded,
                    label: _t(context, 'Montant'),
                    value: PriceText(
                      '${formatAmount(transaction.montantTotal.toString())} MRU',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: pcolor),
                    ),
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    context,
                    icon: Icons.hourglass_top_rounded,
                    label: _t(context, 'Statut'),
                    value: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _t(context, 'En attente'),
                        style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w700, fontSize: 11.5),
                      ),
                    ),
                  ),
                  if (transaction.dateDebut != null) ...[
                    const Divider(height: 1),
                    _infoRow(
                      context,
                      icon: Icons.event_rounded,
                      label: _t(context, 'Date de début'),
                      value: Text(_formatDate(transaction.dateDebut!), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                  if (transaction.dateFin != null) ...[
                    const Divider(height: 1),
                    _infoRow(
                      context,
                      icon: Icons.event_busy_rounded,
                      label: _t(context, 'Date de fin'),
                      value: Text(_formatDate(transaction.dateFin!), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_t(context, 'Fermer'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationLocationSheet extends StatefulWidget {
  final Bien bien;
  final List<Map<String, String>> periodesReservees;

  const _ReservationLocationSheet({required this.bien, required this.periodesReservees});

  @override
  State<_ReservationLocationSheet> createState() => _ReservationLocationSheetState();
}

class _ReservationLocationSheetState extends State<_ReservationLocationSheet> {
  DateTime? _debut;
  DateTime? _fin;
  bool _editMontant = false;
  late final TextEditingController _montantController;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController();
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  double get _prixUnitaire => double.tryParse(widget.bien.prix ?? '') ?? 0;

  /// Nombre de périodes de tarification couvertes : jours inclus pour un
  /// prix par jour, tranches de 3 jours entamées pour « 3jours », mois
  /// calendaires touchés pour un loyer mensuel (01/10 → 31/10 = 1 mois).
  int _nbPeriodes(DateTime debut, DateTime fin) {
    final jours = fin.difference(debut).inDays + 1;
    switch (widget.bien.uniteprix) {
      case 'jour':
        return jours;
      case '3jours':
        return (jours / 3).ceil();
      case 'forfait':
        return 1;
      default:
        return ((fin.year * 12 + fin.month) - (debut.year * 12 + debut.month)) + 1;
    }
  }

  void _onRangeChanged(DateTime? debut, DateTime? fin) {
    setState(() {
      _debut = debut;
      _fin = fin;
      _editMontant = false;
      if (debut != null && fin != null) {
        _montantController.text = (_prixUnitaire * _nbPeriodes(debut, fin)).round().toString();
      } else {
        _montantController.clear();
      }
    });
  }

  String get _uniteLabel {
    final unite = widget.bien.uniteprix;
    return unite == 'forfait' ? '' : ' / ${_t(unite)}';
  }

  @override
  Widget build(BuildContext context) {
    final montant = double.tryParse(_montantController.text) ?? 0;
    final periodeComplete = _debut != null && _fin != null;
    final peutConfirmer = periodeComplete && montant > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  children: [
                    _buildDateSummary(),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ReservationCalendar(
                        reservations: widget.periodesReservees,
                        onRangeChanged: _onRangeChanged,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: periodeComplete
                          ? Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: _buildPriceDetails(),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
              _buildBottomBar(montant: montant, peutConfirmer: peutConfirmer),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final b = widget.bien;
    final photo = b.photoPrincipale;
    final langue = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: photo != null && photo.isNotEmpty
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoFallback(),
                        )
                      : _photoFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Choisir une période'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.titreFor(langue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kBlackColor),
                    ),
                    const SizedBox(height: 4),
                    if (b.prix != null)
                      PriceText(
                        '${formatAmount(b.prix)} ${_t("MRU")}$_uniteLabel',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pcolor),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                icon: const Icon(Icons.close_rounded, size: 20, color: kBlackColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoFallback() => Container(
        color: pcolor.withOpacity(0.1),
        child: const Icon(Icons.home_rounded, color: pcolor),
      );

  /// Deux cases « Arrivée » / « Départ » avec la durée au milieu.
  Widget _buildDateSummary() {
    final format = DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode);
    final jours = _debut != null && _fin != null ? _fin!.difference(_debut!).inDays + 1 : null;

    Widget dateBox(String label, DateTime? date, IconData icon, bool active) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: date != null ? pcolor.withOpacity(0.07) : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? pcolor : (date != null ? pcolor.withOpacity(0.4) : Colors.grey[200]!),
              width: active ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: date != null ? pcolor : Colors.grey[500]),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                date != null ? format.format(date) : '— — —',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: date != null ? kBlackColor : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            dateBox(_t('Date de début'), _debut, Icons.login_rounded, _debut == null),
            const SizedBox(width: 10),
            dateBox(_t('Date de fin'), _fin, Icons.logout_rounded, _debut != null && _fin == null),
          ],
        ),
        if (jours != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pcolor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '$jours ${_t(jours > 1 ? "jours" : "jour")}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceDetails() {
    final nb = _nbPeriodes(_debut!, _fin!);
    final unite = widget.bien.uniteprix;
    final sousTotal = (_prixUnitaire * nb).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 18, color: pcolor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t('Détails du prix'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kBlackColor),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _editMontant = !_editMontant),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _editMontant ? Icons.check_rounded : Icons.edit_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_prixUnitaire > 0)
            Row(
              children: [
                Expanded(
                  child: PriceText(
                    unite == 'forfait'
                        ? _t('forfait')
                        : '${formatAmount(widget.bien.prix)} ${_t("MRU")} × $nb ${_t(unite)}',
                    style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
                  ),
                ),
                PriceText(
                  '${formatAmount(sousTotal.toString())} ${_t("MRU")}',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey[800], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          if (_editMontant || _prixUnitaire <= 0) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              autofocus: _editMontant,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: _t('Montant total'),
                suffixText: _t('MRU'),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: pcolor, width: 1.5),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey[300]),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _t('Montant total'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kBlackColor),
                ),
              ),
              PriceText(
                '${formatAmount(_montantController.text)} ${_t("MRU")}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: pcolor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required double montant, required bool peutConfirmer}) {
    final format = DateFormat('dd/MM', Localizations.localeOf(context).languageCode);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (peutConfirmer) ...[
                  PriceText(
                    '${formatAmount(montant.round().toString())} ${_t("MRU")}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kBlackColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${format.format(_debut!)} → ${format.format(_fin!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ] else
                  Text(
                    _debut == null ? _t('Choisissez la date de début') : _t('Choisissez la date de fin'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: peutConfirmer
                  ? () => Navigator.pop(context, {
                        'debut': _debut,
                        'fin': _fin,
                        'montant': montant,
                      })
                  : null,
              icon: const Icon(Icons.event_available_rounded, size: 20),
              label: Text(_t('Réserver'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: pcolor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
