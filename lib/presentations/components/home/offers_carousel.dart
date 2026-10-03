import 'dart:async';

import 'package:flutter/material.dart';

import 'package:akarina/data/data_providers/offre_service.dart';
import 'package:akarina/data/models/offre.dart';
import 'package:akarina/presentations/constants/constants.dart';

/// Carrousel de bannières promotionnelles pour l'écran d'accueil, alimenté
/// par https://admin-akarina.akarina.shop/api/offres/.
class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  List<Offre>? _offres;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffres();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadOffres() async {
    try {
      final offres = await OffreService().fetchOffres();
      if (!mounted) return;
      setState(() {
        _offres = offres;
        _isLoading = false;
      });
      if (offres.length > 1) _startAutoPlay();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _offres = [];
        _isLoading = false;
      });
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _offres == null || _offres!.isEmpty) return;
      final next = (_currentPage + 1) % _offres!.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _skeleton();
    }

    final offres = _offres ?? [];
    if (offres.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: offres.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OfferBanner(offre: offres[index]),
            ),
          ),
        ),
        if (offres.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              offres.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index ? pcolor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _skeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _OfferBanner extends StatelessWidget {
  final Offre offre;
  const _OfferBanner({required this.offre});

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final title = offre.titreFor(language);
    final description = offre.descriptionFor(language);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[300],
        image: (offre.image != null && offre.image!.isNotEmpty)
            ? DecorationImage(image: NetworkImage(offre.image!), fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.65)],
                ),
              ),
            ),
          ),
          if (offre.reductionPourcentage != null)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '-${double.tryParse(offre.reductionPourcentage!)?.toStringAsFixed(0) ?? offre.reductionPourcentage}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
