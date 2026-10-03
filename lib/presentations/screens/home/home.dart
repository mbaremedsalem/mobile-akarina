import 'package:flutter/material.dart';

import 'package:akarina/business_logic/cubit/layout_cubit.dart';
import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:akarina/presentations/components/home/offers_carousel.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/components/property/property_card.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';

/// Accueil : bannières promotionnelles (/api/offres/) puis biens
/// récemment ajoutés (/api/biens/?ordering=-date_creation).
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Bien> _recentProperties = [];
  bool _isLoadingRecent = true;
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (!mounted) return;
    setState(() => _hasInternetConnection = hasConnection);
    if (!hasConnection) return;
    await _loadRecentProperties();
  }

  Future<void> _loadRecentProperties() async {
    if (!mounted) return;
    setState(() => _isLoadingRecent = true);
    try {
      final page = await BienService().fetchBiens(ordering: '-date_creation', pageSize: 10);
      if (!mounted) return;
      setState(() {
        _recentProperties = page.results;
        _isLoadingRecent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRecent = false);
    }
  }

  void _goToImmobilierTab() {
    LayoutCubit.get(context).changeBottom(1);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    if (!_hasInternetConnection) {
      return NoInternetPage(onRetry: _initializeData);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const OffersCarousel(),
                const SizedBox(height: 28),
                _buildRecentSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pcolor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.fiber_new_rounded, color: pcolor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  getTranslated(context, "Récemment ajoutés")!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              TextButton(
                onPressed: _goToImmobilierTab,
                child: Text(getTranslated(context, "Voir tout")!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingRecent
              ? const PropertyCardSkeleton()
              : _recentProperties.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          getTranslated(context, "Aucune propriété trouvée")!,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: _recentProperties.length,
                      itemBuilder: (context, index) => PropertyCard(property: _recentProperties[index]),
                    ),
        ],
      ),
    );
  }
}
