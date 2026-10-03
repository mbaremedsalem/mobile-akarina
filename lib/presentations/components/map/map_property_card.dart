import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/map_property.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/utils/price_utils.dart';

/// Carte compacte affichée dans le carrousel au bas de la carte, à la façon
/// des fiches Zillow : photo à gauche, prix et caractéristiques à droite.
class MapPropertyCard extends StatelessWidget {
  final MapProperty property;
  final VoidCallback onTap;

  const MapPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildMedia(context),
            Expanded(child: _buildInfos(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final url = property.mediaUrl;

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: SizedBox(
        width: 130,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null || property.isVideoPreview)
              Container(
                color: Colors.grey[200],
                child: Icon(
                  property.isVideoPreview ? Icons.videocam : Icons.home_outlined,
                  color: Colors.grey[500],
                  size: 34,
                ),
              )
            else
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.home_outlined, color: Colors.grey[500], size: 34),
                ),
              ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              top: 8,
              start: 8,
              child: _buildBadge(
                getTranslated(context, property.typeOperation) ??
                    property.typeOperation,
                property.isVente ? Colors.red.shade600 : pcolor,
              ),
            ),
            if (!property.available)
              Positioned.directional(
                textDirection: Directionality.of(context),
                bottom: 8,
                start: 8,
                child: _buildBadge(
                  getTranslated(context, 'Non disponible')!,
                  Colors.grey.shade800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texte,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfos(BuildContext context) {
    final periode = getTranslated(context, property.periode) ?? property.periode;
    final devise = getTranslated(context, 'MRU') ?? 'MRU';

    final contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PriceText(
          property.prixComplet(suffixePeriode: periode, devise: devise).isEmpty
              ? getTranslated(context, 'Prix sur demande')!
              : property.prixComplet(suffixePeriode: periode, devise: devise),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildCaracteristiques(context),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                [property.adresse, property.ville]
                    .where((e) => e.isNotEmpty)
                    .join(', '),
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!property.positionExacte) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Tooltip(
                message: getTranslated(context, 'Position approximative')!,
                child: Icon(
                  Icons.help_outline,
                  size: 13,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ],
      ],
    );

    // Le carrousel a une hauteur fixe ; sur un appareil réglé avec une grande
    // police système, ce contenu peut malgré tout dépasser. On l'encapsule
    // dans un défilement plutôt que de laisser Flutter le faire déborder.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.15,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Vertical : ne gêne pas le swipe horizontal du PageView parent.
              // En dernier recours (grande police système), le contenu défile
              // au lieu de déborder ou d'être tronqué.
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: contenu),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaracteristiques(BuildContext context) {
    final items = <Widget>[];

    void add(IconData icone, String texte) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 10));
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 13, color: Colors.grey[700]),
            const SizedBox(width: 3),
            Text(
              texte,
              style: TextStyle(fontSize: 11, color: Colors.grey[800]),
            ),
          ],
        ),
      );
    }

    if (property.chambres > 0) add(Icons.bed_outlined, '${property.chambres}');
    if (property.sallesDeBain > 0) {
      add(Icons.bathtub_outlined, '${property.sallesDeBain}');
    }

    if (items.isEmpty) {
      return Text(
        getTranslated(context, property.categorie) ?? property.categorie,
        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
      );
    }

    return Row(children: items);
  }
}
