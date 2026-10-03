import 'package:flutter/material.dart';

import 'package:akarina/business_logic/search/search_criteria.dart';
import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/components/property/property_card.dart';
import 'package:akarina/presentations/components/search/search_criteria_sheet.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/layout/layout.dart';

/// Écran générique de résultats immobiliers : sert aux onglets Immobilier,
/// Vente et Achat de la bottom nav, ainsi qu'à la redirection depuis la
/// barre de recherche de l'AppBar (voir [Layout]).
///
/// Quand [listenToGlobalSearch] est vrai, l'écran se met à jour dès qu'une
/// nouvelle recherche est publiée via [ImmobilierSearchBus] (utilisé par
/// l'onglet Immobilier, cible de la redirection de recherche).
class ImmobilierScreen extends StatefulWidget {
  final String title;
  final SearchCriteria? initialCriteria;
  final bool listenToGlobalSearch;

  /// Affiche un bandeau permettant de rejoindre l'app complète (5 onglets)
  /// — utilisé quand cet écran sert de racine dédiée (mode "Maisons de
  /// cérémonie", voir [applyAppMode]).
  final bool showExploreFullAppButton;

  const ImmobilierScreen({
    super.key,
    required this.title,
    this.initialCriteria,
    this.listenToGlobalSearch = false,
    this.showExploreFullAppButton = false,
  });

  @override
  State<ImmobilierScreen> createState() => _ImmobilierScreenState();
}

class _ImmobilierScreenState extends State<ImmobilierScreen> {
  late SearchCriteria _criteria;
  final ScrollController _scrollController = ScrollController();

  List<Bien> _results = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextPageUrl;
  int _totalCount = 0;
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria ?? const SearchCriteria();
    if (widget.listenToGlobalSearch) {
      ImmobilierSearchBus.addListener(_onGlobalSearch);
      final pending = ImmobilierSearchBus.pendingCriteria;
      if (pending != null) {
        _criteria = pending;
      }
    }
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void dispose() {
    if (widget.listenToGlobalSearch) {
      ImmobilierSearchBus.removeListener(_onGlobalSearch);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onGlobalSearch() {
    final criteria = ImmobilierSearchBus.pendingCriteria;
    if (criteria == null || !mounted) return;
    setState(() => _criteria = criteria);
    _load();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _initialize() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (!mounted) return;
    setState(() => _hasInternetConnection = hasConnection);
    if (!hasConnection) return;
    await _load();
  }

  Future<void> _load({String? pageUrl}) async {
    if (!mounted) return;

    if (pageUrl == null) {
      setState(() {
        _isLoading = true;
        _results = [];
        _nextPageUrl = null;
        _totalCount = 0;
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final page = await BienService().fetchBiens(
        pageUrl: pageUrl,
        typeTransaction: pageUrl == null ? _criteria.typeTransaction : null,
        typeBien: pageUrl == null ? _criteria.typeBien : null,
        villeId: pageUrl == null ? _criteria.villeId : null,
        quartierId: pageUrl == null ? _criteria.quartierId : null,
        meuble: pageUrl == null ? _criteria.meuble : null,
        unitePrix: pageUrl == null ? _criteria.unitePrix : null,
        nbChambres: pageUrl == null ? _criteria.nbChambres : null,
        prixMin: pageUrl == null ? _criteria.prixMin : null,
        prixMax: pageUrl == null ? _criteria.prixMax : null,
        disponibleDu: pageUrl == null ? _criteria.disponibleDu : null,
        disponibleAu: pageUrl == null ? _criteria.disponibleAu : null,
        search: pageUrl == null ? _criteria.search : null,
        ordering: pageUrl == null ? _criteria.ordering : null,
      );

      if (!mounted) return;
      setState(() {
        if (pageUrl == null) {
          _results = page.results;
        } else {
          _results.addAll(page.results);
        }
        _totalCount = page.count;
        _nextPageUrl = page.next;
        _hasMore = page.next != null;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${getTranslated(context, "Erreur")!}: $e')),
      );
    }
  }

  Future<void> _loadNextPage() async {
    if (_nextPageUrl != null && !_isLoadingMore && _hasMore) {
      await _load(pageUrl: _nextPageUrl);
    }
  }

  Future<void> _openFilters() async {
    final result = await showSearchCriteriaSheet(context, initial: _criteria);
    if (result == null) return;
    setState(() => _criteria = result);
    _load();
  }

  Widget _buildExploreFullAppBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: pcolor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const Layout()));
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.apartment_rounded, color: pcolor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getTranslated(context, "Découvrir toute l'application Agharina")!,
                    style: TextStyle(color: pcolor, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: pcolor, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternetConnection) {
      return NoInternetPage(onRetry: _initialize);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(getTranslated(context, widget.title)!, style: const TextStyle(color: kBlackColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.filter_alt_rounded, color: pcolor),
                if (_criteria.hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (widget.showExploreFullAppButton)
              SliverToBoxAdapter(child: _buildExploreFullAppBanner(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      _isLoading
                          ? getTranslated(context, "Chargement...") ?? "..."
                          : '$_totalCount ${getTranslated(context, "propriétés") ?? "propriétés"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (_criteria.hasActiveFilters)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _criteria = const SearchCriteria());
                          _load();
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(getTranslated(context, "Effacer")!),
                      ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: PropertyCardSkeleton(),
                ),
              )
            else if (_results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PropertyCard(property: _results[index]),
                    childCount: _results.length,
                  ),
                ),
              ),
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              getTranslated(context, "Aucune propriété trouvée")!,
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              getTranslated(context, "Essayez de modifier vos critères de recherche")!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_criteria.hasActiveFilters)
              ElevatedButton(
                onPressed: () {
                  setState(() => _criteria = const SearchCriteria());
                  _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: pcolor, foregroundColor: Colors.white),
                child: Text(getTranslated(context, "Réinitialiser la recherche")!),
              )
            else
              ElevatedButton(
                onPressed: _openFilters,
                style: ElevatedButton.styleFrom(backgroundColor: pcolor, foregroundColor: Colors.white),
                child: Text(getTranslated(context, "Rechercher")!),
              ),
          ],
        ),
      ),
    );
  }
}
