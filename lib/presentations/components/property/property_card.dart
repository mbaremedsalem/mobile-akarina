import 'package:flutter/material.dart';

import 'package:akarina/data/data_providers/bien_detail_cache.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/presentations/utils/price_utils.dart';

/// Carte moderne pour un bien, utilisée dans toutes les grilles de
/// propriétés de l'app (accueil, recherche par catégorie...).
class PropertyCard extends StatefulWidget {
  final Bien property;

  const PropertyCard({super.key, required this.property});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _checkForVideo();
  }

  /// La liste `/api/biens/` ne renvoie pas les médias : on va chercher le
  /// détail (mis en cache, voir [BienDetailCache]) juste pour savoir si ce
  /// bien a une vidéo à proposer directement depuis la grille.
  Future<void> _checkForVideo() async {
    try {
      final detail = await BienDetailCache.fetch(widget.property.reference);
      if (!mounted) return;
      final videos = detail.medias.where((m) => m.isVideo);
      if (videos.isNotEmpty) {
        setState(() => _videoUrl = videos.first.fichier);
      }
    } catch (_) {
      // Best-effort : en cas d'échec on affiche simplement la photo.
    }
  }

  void _openVideo(BuildContext context) {
    final url = _videoUrl;
    if (url == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerWidget(videoUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final language = Localizations.localeOf(context).languageCode;
    final isVente = property.isVente;
    final title = property.titreFor(language);
    final lieu = [property.quartierNom, property.villeNom]
        .where((e) => e.isNotEmpty)
        .join(', ');
    final hasPrice = property.prix != null;
    final prixFormatted = formatAmount(property.prix);
    final unitLabel = property.uniteprix == 'forfait'
        ? ''
        : '/${getTranslated(context, property.uniteprix) ?? property.uniteprix}';
    final chambres = property.nbChambres ?? 0;
    final sdb = property.nbSallesBain ?? 0;
    final imageUrl = property.photoPrincipale;
    final hasVideo = _videoUrl != null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImmobDetails(reference: property.reference),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(color: const Color(0xFFF1F3F5));
                          },
                        )
                      : _placeholder(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.32), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                if (hasVideo)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withOpacity(0.18),
                      child: InkWell(
                        onTap: () => _openVideo(context),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: 10,
                  start: 10,
                  child: _badge(
                    text: getTranslated(context, isVente ? 'vendre' : 'alouer') ??
                        (isVente ? 'Vente' : 'Location'),
                    color: isVente ? const Color(0xFFE94057) : pcolor,
                  ),
                ),
                if (property.vendu)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                      alignment: Alignment.center,
                      child: _badge(
                        text: getTranslated(context, 'Unavailable') ?? 'Indisponible',
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PriceText(
                    hasPrice
                        ? '$prixFormatted ${getTranslated(context, "MRU")}'
                        : getTranslated(context, 'Prix sur demande')!,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: kBlackColor,
                      height: 1.0,
                    ),
                    suffix: hasPrice && unitLabel.isNotEmpty ? unitLabel : null,
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kBlackColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lieu.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            lieu,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (chambres > 0 || sdb > 0) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        if (chambres > 0) _featurePill(Icons.bed_rounded, '$chambres'),
                        if (chambres > 0 && sdb > 0) const SizedBox(width: 8),
                        if (sdb > 0) _featurePill(Icons.bathtub_rounded, '$sdb'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF1F3F5),
        alignment: Alignment.center,
        child: Icon(Icons.home_rounded, size: 32, color: Colors.grey[300]),
      );

  Widget _badge({required String text, required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      );

  Widget _featurePill(IconData icon, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ],
        ),
      );
}
