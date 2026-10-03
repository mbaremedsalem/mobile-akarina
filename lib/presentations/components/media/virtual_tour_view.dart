import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';

/// Un média de la visite : soit une photo, soit une vidéo, déjà résolu en URL
/// absolue par l'appelant.
class TourMediaItem {
  final String url;
  final bool isVideo;

  const TourMediaItem({required this.url, required this.isVideo});
}

/// Visite immersive plein écran d'un bien : enchaîne toutes ses photos et
/// vidéos comme une visite guidée pièce par pièce — zoom pincer sur les
/// photos, lecture automatique des vidéos à l'arrivée sur leur page.
///
/// L'application ne dispose pas de vraies données 3D par bien (pas de photos
/// panoramiques ni de modèle 3D) : cette visite s'appuie donc sur les médias
/// déjà mis en ligne par le propriétaire, présentés de façon immersive.
class VirtualTourView extends StatefulWidget {
  final List<TourMediaItem> medias;
  final String titre;

  const VirtualTourView({
    super.key,
    required this.medias,
    required this.titre,
  });

  /// Ouvre la visite avec une transition en fondu-zoom, plus adaptée à
  /// l'idée d'« entrer » dans le bien qu'un simple slide horizontal.
  static Future<void> open(
    BuildContext context, {
    required List<TourMediaItem> medias,
    required String titre,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, __) =>
            VirtualTourView(medias: medias, titre: titre),
        transitionsBuilder: (context, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<VirtualTourView> createState() => _VirtualTourViewState();
}

class _VirtualTourViewState extends State<VirtualTourView> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  @override
  Widget build(BuildContext context) {
    final medias = widget.medias;

    if (medias.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            _t('Aucun média disponible.'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: medias.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => _buildPage(medias[index], index),
          ),
          _buildDegradeHaut(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Column(
                children: [
                  _buildBarresProgression(medias.length),
                  const SizedBox(height: 10),
                  _buildEntete(isArabic, medias.length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ne construit le lecteur vidéo (et donc n'en démarre la lecture) que sur
  /// la page active : garder plusieurs vidéos en mémoire en même temps
  /// gaspillerait batterie et bande passante pour rien.
  Widget _buildPage(TourMediaItem media, int index) {
    if (!media.isVideo) {
      return PhotoView(
        imageProvider: NetworkImage(media.url),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        initialScale: PhotoViewComputedScale.contained,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
        errorBuilder: (context, error, stack) => Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
        ),
      );
    }

    if (index != _index) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 56, color: Colors.white38),
        ),
      );
    }

    return Center(
      child: VideoPlayerWidget(key: ValueKey(media.url), videoUrl: media.url),
    );
  }

  Widget _buildDegradeHaut() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.55), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarresProgression(int total) {
    return Row(
      children: List.generate(total, (i) {
        final actif = i <= _index;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: actif ? Colors.white : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEntete(bool isArabic, int total) {
    return Row(
      children: [
        _buildBoutonRond(
          icone: Icons.close,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(IconBroken.Location, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.titre.isEmpty ? _t('Visite virtuelle') : widget.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${_index + 1} / $total',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoutonRond({required IconData icone, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icone, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Badge « Visite virtuelle » façon Zillow, à poser sur la galerie photo de
/// la page détails.
class VirtualTourBadge extends StatelessWidget {
  final VoidCallback onTap;

  const VirtualTourBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.72),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.threed_rotation, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                getTranslated(context, 'Visite virtuelle') ?? 'Visite virtuelle',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
