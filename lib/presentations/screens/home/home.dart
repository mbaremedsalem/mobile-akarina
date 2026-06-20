import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/appartement/appartement.dart';
import 'package:akarina/presentations/screens/appartement/forfait_page.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akarina/data/services/connectivity_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final storage = const FlutterSecureStorage();
  final searchController = TextEditingController();
  
  Map<String, dynamic> immobilierSummary = {};
  List<dynamic> immobilierList = [];
  List<dynamic> proximiteList = [];
  List<dynamic> filteredProperties = [];
  List<Map<String, dynamic>> availableCities = [];
  
  String? nextPageUrl;
  String? previousPageUrl;
  int totalCount = 0;
  bool isLoadingMore = false;
  bool hasMore = true;

  String selectedCity = '';
  bool isLoading = true;
  bool isSearch = false;
  bool isLoadingCities = true;
  bool hasInternetConnection = true;
  bool showSearchResults = false;
  IconData suffixIcon = Icons.search;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    searchController.addListener(_updateSearchIcon);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Vérifier si on a atteint le bas de la liste
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });
    
    if (!hasConnection) {
      return;
    }
    
    await Future.wait([
      _loadResidenciel(),
      _loadCategories(),
      _loadProximite(),
      _fetchCities(),
    ]);
  }

  void _updateSearchIcon() {
    setState(() {
      suffixIcon = searchController.text.isEmpty ? Icons.search : Icons.close;
    });
  }

  Future<void> _fetchCities() async {
    if (!mounted) return;
    
    try {
      final response = await http.get(
        Uri.parse("https://akarina.shop/akareena/villes/"),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final rawData = json.decode(utf8.decode(response.bodyBytes));
        
        final List<Map<String, dynamic>> uniqueCities = [];
        final Set<String> seenCities = <String>{};
        
        for (final city in List<Map<String, dynamic>>.from(rawData)) {
          final cityName = city['nom'];
          if (!seenCities.contains(cityName)) {
            seenCities.add(cityName);
            uniqueCities.add(city);
          }
        }

        setState(() {
          availableCities = uniqueCities;
          isLoadingCities = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingCities = false);
        throw Exception("Erreur lors du chargement des villes: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingCities = false);
      _showErrorSnackbar("Erreur: $e");
    }
  }

  Future<void> _fetchProperties(String ville, String address) async {
    if (ville.isEmpty && address.isEmpty) return;

    setState(() {
      isSearch = true;
      showSearchResults = true;
    });

    try {
      final language = await getCurrentLanguage(context);
      final isArabic = language == "ar";

      final params = <String, String>{};

      if (selectedCity.isNotEmpty) {
        if (isArabic) {
          final selectedCityData = availableCities.firstWhere(
            (city) => city['nom'] == selectedCity,
            orElse: () => {},
          );
          
          if (selectedCityData.isNotEmpty) {
            final villeAr = selectedCityData['nom_ar'] ?? selectedCity;
            params['nom_ville_ar'] = villeAr;
          } else {
            params['nom_ville_ar'] = selectedCity;
          }
        } else {
          params['nom_ville'] = selectedCity;
        }
      }

      if (address.isNotEmpty) {
        if (isArabic) {
          params['region_ar'] = address;
        } else {
          params['region'] = address;
        }
      }

      final queryParams = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
          
      final url = 'https://akarina.shop/akareena/search/?$queryParams';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        
        List<dynamic> propertiesList = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('results') && responseData['results'] is List) {
            propertiesList = responseData['results'];
          } else if (responseData.containsKey('data') && responseData['data'] is List) {
            propertiesList = responseData['data'];
          } else {
            for (var value in responseData.values) {
              if (value is List) {
                propertiesList = value;
                break;
              }
            }
          }
        } else if (responseData is List) {
          propertiesList = responseData;
        }

        setState(() {
          filteredProperties = propertiesList;
          isSearch = false;
        });
      } else {
        setState(() => isSearch = false);
        _showErrorSnackbar(getTranslated(context, "Erreur lors de la recherche")!);
      }
    } catch (error) {
      setState(() => isSearch = false);
      _showErrorSnackbar(getTranslated(context, "Erreur de connexion")!);
    }
  }

  void _resetSearch() {
    setState(() {
      showSearchResults = false;
      searchController.clear();
      selectedCity = '';
    });
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    
    try {
      final fetchedCategories = await NetworkService().fetchCategories();
      if (!mounted) return;

      setState(() {
        immobilierSummary = fetchedCategories ?? {};
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _loadResidenciel({String? pageUrl}) async {
    if (!mounted) return;
    
    if (pageUrl == null) {
      setState(() {
        isLoading = true;
        immobilierList = [];
        nextPageUrl = null;
        previousPageUrl = null;
        totalCount = 0;
        hasMore = true;
      });
    } else {
      if (isLoadingMore || !hasMore) return;
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final String url = pageUrl ?? "https://akarina.shop/akareena/imobiers/";
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        final newResults = data['results'] as List<dynamic>? ?? [];
        final count = data['count'] ?? 0;
        final next = data['next'];
        final previous = data['previous'];
        
        setState(() {
          if (pageUrl == null) {
            immobilierList = newResults;
          } else {
            immobilierList.addAll(newResults);
          }
          
          totalCount = count;
          nextPageUrl = next;
          previousPageUrl = previous;
          hasMore = next != null;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        _showErrorSnackbar("Erreur lors du chargement: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      _showErrorSnackbar("Erreur: $e");
    }
  }

  Future<void> _loadNextPage() async {
    if (nextPageUrl != null && !isLoadingMore && hasMore) {
      await _loadResidenciel(pageUrl: nextPageUrl);
    }
  }

  Future<void> _loadProximite() async {
    if (!mounted) return;
    
    try {
      final fetchproximite = await NetworkService().fetchProximite();
      if (!mounted) return;

      setState(() {
        proximiteList = fetchproximite ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorSnackbar(e.toString());
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          setState(() {
            hasInternetConnection = hasConnection;
          });
          
          if (hasConnection) {
            _initializeData();
          }
        },
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHeaderSection(),
              if (!showSearchResults) _buildCategoriesSection(),
              _buildPropertiesSection(),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 280,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      getTranslated(context, "Bienvenue sur Akarina")!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showSearchResults) ...[
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _resetSearch,
                        tooltip: getTranslated(context, "Annuler la recherche"),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  showSearchResults 
                    ? getTranslated(context, "Résultats de votre recherche")!
                    : getTranslated(context, "Trouvez votre maison de rêve")!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                if (isSearch) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FutureBuilder<String>(
        future: getCurrentLanguage(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final language = snapshot.data!;
          return TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: getTranslated(context, "Sélectionnez une ville et entrez une adresse...")!,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: _buildCityDropdown(language),
              suffixIcon: _buildSearchButton(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCityDropdown(String language) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pcolor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoadingCities
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: selectedCity.isEmpty ? null : availableCities.firstWhere(
                  (city) => city['nom'] == selectedCity,
                  orElse: () => {},
                ),
                items: availableCities
                    .map((city) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: city,
                        child: Text(
                          language == "ar" ? city['nom_ar'] : city['nom'],
                          textDirection: language == "ar" ? TextDirection.rtl : TextDirection.ltr,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    })
                    .toList(),
                onChanged: (Map<String, dynamic>? value) {
                  if (value != null) {
                    setState(() => selectedCity = value['nom'] ?? '');
                  }
                },
                hint: Text(
                  getTranslated(context, "Ville")!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                icon: Icon(Icons.keyboard_arrow_down, color: pcolor),
              ),
            ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: pcolor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          if (selectedCity.isNotEmpty || searchController.text.isNotEmpty) {
            _fetchProperties(selectedCity, searchController.text);
          } else {
            _showErrorSnackbar(getTranslated(context, "Veuillez sélectionner une ville ou entrer une adresse")!);
          }
        },
      ),
    );
  }

  SliverToBoxAdapter _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.category,
              title: getTranslated(context, "Catégories")!,
            ),
            const SizedBox(height: 12),
            isLoading
                ? const CategorySkeleton()
                : _buildCategoriesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: pcolor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: pcolor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: immobilierSummary.length,
      itemBuilder: (context, index) {
        final keys = immobilierSummary.keys.toList();
        final category = immobilierSummary[keys[index]];
        return ModernCategoryCard(
          name: category['name'],
          imagePath: _getImageForCategory(category['name']),
          count: category['count'],
          onTap: () => _navigateToCategory(category['name'], category['count']),
        );
      },
    );
  }

  void _navigateToCategory(String categoryName, int count) {
    final apiUrl = _getApiUrlForCategory(categoryName);
    
    if (apiUrl == 'forfait') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ForfaitPage(),
        ),
      );
    } else if (apiUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Appartement(apiUrl: apiUrl, count: count),
        ),
      );
    }
  }

  String _getApiUrlForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'appartement': return 'https://akarina.shop/akareena/appartements/';
      case 'duplex': return 'https://akarina.shop/akareena/duplexes/';
      case 'commercial': return 'https://akarina.shop/akareena/commerciaux/';
      case 'terrain': return 'https://akarina.shop/akareena/terrains/';
      case 'residentiel': return 'https://akarina.shop/akareena/residentiels/';
      case 'maisonceremonie': return 'forfait';
      default: return '';
    }
  }

  SliverToBoxAdapter _buildPropertiesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertiesHeader(),
            const SizedBox(height: 16),
            _buildPropertiesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesHeader() {
    return Row(
      children: [
        _buildSectionTitle(
          icon: Icons.home,
          title: showSearchResults 
            ? getTranslated(context, "Résultats de recherche")!
            : getTranslated(context, "Residentiel")!,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pcolor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            showSearchResults
                ? '${filteredProperties.length} ${getTranslated(context, "résultats")}'
                : '$totalCount ${getTranslated(context, "propriétés")}',
            style: TextStyle(
              color: pcolor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesContent() {
    if (showSearchResults) {
      return filteredProperties.isNotEmpty
          ? _buildModernPropertyGrid(filteredProperties)
          : _buildEmptyState();
    } else if (isLoading && immobilierList.isEmpty) {
      return const PropertyCardSkeleton();
      // Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: [
          _buildModernPropertyGrid(immobilierList),
          // Indicateur de chargement en bas de liste
          if (isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Message quand toutes les propriétés sont chargées
          if (!hasMore && immobilierList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                getTranslated(context, "Toutes les propriétés sont chargées")!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(74)),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            getTranslated(context, "Aucune propriété trouvée")!,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getTranslated(context, "Essayez de modifier vos critères de recherche")!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: pcolor,
              foregroundColor: Colors.white,
            ),
            child: Text(getTranslated(context, "Réinitialiser la recherche")!),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPropertyGrid(List<dynamic> properties) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildPropertyCard(property);
      },
    );
  }

  Widget _buildPropertyCard(dynamic property) {
    final mediaUrl = _resolveImageUrl(property);
    final priceInfo = _extractPriceInfo(property);
    final locationInfo = _extractLocationInfo(property);
    
    final operationType = priceInfo['operationType'];
    final ville = locationInfo['ville'];
    final ratings = property['ratings']?.toString() ?? property['rating']?.toString() ?? '0.0';
    final adresse = locationInfo['adresse'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isVideo(mediaUrl)) {
                    _openVideo(context, mediaUrl);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImmobDetails(id: property['id']),
                      ),
                    );
                  }
                },
                child: Container(
                  height: constraints.maxWidth * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: _isVideo(mediaUrl)
                        ? null
                        : DecorationImage(
                            image: NetworkImage(mediaUrl),
                            fit: BoxFit.cover,
                            onError: (_, __) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.home, color: Colors.grey),
                            ),
                          ),
                    color: _isVideo(mediaUrl) ? Colors.black54 : null,
                  ),
                  child: Stack(
                    children: [
                      if (_isVideo(mediaUrl))
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                        ),
                      
                      if (_isVideo(mediaUrl))
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
                          ),
                        )
                      else if (mediaUrl.contains('encrypted-tbn0'))
                        const Center(
                          child: Icon(Icons.home, size: 40, color: Colors.grey),
                        ),
                      
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: operationType == 'vendre' 
                                ? Colors.red.withOpacity(0.8)
                                : Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getTranslated(context, operationType) ?? operationType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      if (_isVideo(mediaUrl))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              getTranslated(context, "VIDÉO")!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImmobDetails(id: property['id']),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxWidth * 0.15,
                        ),
                        child: Text(
                          adresse!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ville!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      Text(
                        _getPriceText(property, priceInfo),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      Row(
                        children: [
                          ...List.generate(5, (starIndex) => Icon(
                            Icons.star,
                            size: 14,
                            color: starIndex < (double.tryParse(ratings) ?? 0).floor()
                                ? Colors.amber
                                : Colors.grey[300],
                          )),
                          const SizedBox(width: 4),
                          Text(
                            ratings,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPriceText(dynamic property, Map<String, dynamic> priceInfo) {
    // Chercher dans les sous-objets
    final terrain = property['terrain'] as Map?;
    final residentiel = property['residentiel'] as Map?;
    
    // Si c'est un terrain
    if (terrain != null) {
      final montant = terrain['montant'];
      if (montant != null && montant != 'null') {
        return '$montant MRU';
      }
    }
    
    // Si c'est un résidentiel
    if (residentiel != null) {
      final montant = residentiel['montant'];
      if (montant != null && montant != 'null') {
        return '$montant MRU';
      }
      final loyerMensuel = residentiel['loyer_mensuel'];
      final periode = residentiel['periode'] ?? 'mois';
      if (loyerMensuel != null && loyerMensuel != 'null') {
        return '$loyerMensuel MRU/${getTranslated(context, periode) ?? "mois"}';
      }
    }
    
    return getTranslated(context, 'Prix sur demande')!;
  }

  bool _isVideo(String url) {
    if (url.isEmpty) return false;
    
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.wmv', '.flv', '.mkv'];
    final videoPaths = ['/videos/', '/media/videos/', 'video', 'mp4'];
    
    final lowerUrl = url.toLowerCase();
    
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext)) ||
           videoPaths.any((path) => lowerUrl.contains(path));
  }

  void _openVideo(BuildContext context, String videoUrl) {
    String fullVideoUrl = videoUrl;
    if (videoUrl.startsWith('/')) {
      fullVideoUrl = 'https://akarina.shop$videoUrl';
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          child: VideoPlayerWidget(videoUrl: fullVideoUrl),
        ),
      ),
    );
  }

  String _resolveImageUrl(dynamic property) {
    try {
      // Vérifier d'abord dans le sous-objet terrain ou residentiel
      if (property['terrain'] != null && property['terrain'] is Map) {
        final terrainImages = property['terrain']['images'];
        if (terrainImages != null && terrainImages.isNotEmpty) {
          final firstImage = terrainImages[0];
          if (firstImage['image'] != null && firstImage['image'].toString().isNotEmpty) {
            return 'https://akarina.shop'+firstImage['image'];
          }
          if (firstImage['video'] != null && firstImage['video'].toString().isNotEmpty) {
            return firstImage['video'];
          }
        }
      }
      
      if (property['residentiel'] != null && property['residentiel'] is Map) {
        final residentielImages = property['residentiel']['images'];
        if (residentielImages != null && residentielImages.isNotEmpty) {
          final firstImage = residentielImages[0];
          if (firstImage['image'] != null && firstImage['image'].toString().isNotEmpty) {
            return 'https://akarina.shop'+firstImage['image'];
          }
          if (firstImage['video'] != null && firstImage['video'].toString().isNotEmpty) {
            return firstImage['video'];
          }
        }
      }
      
      // Vérifier dans le niveau supérieur
      if (property['images'] != null && property['images'].isNotEmpty) {
        final firstImage = property['images'][0];
        if (firstImage['image'] != null && firstImage['image'].toString().isNotEmpty) {
          return firstImage['image'];
        }
        if (firstImage['video'] != null && firstImage['video'].toString().isNotEmpty) {
          return firstImage['video'];
        }
      }
      
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
    } catch (e) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
    }
  }



  Map<String, dynamic> _extractPriceInfo(dynamic property) {
    final operationType = property['type_operation'] ?? 
                         property['operation']?['type'] ?? 
                         'alouer';
    
    String? montant;
    String? loyerMensuel;
    String? periode;

    if (property['residentiel'] != null && property['residentiel'] is Map) {
      final residentiel = property['residentiel'];
      
      if (residentiel['montant'] != null) {
        montant = residentiel['montant'].toString();
      }
      if (residentiel['loyer_mensuel'] != null) {
        loyerMensuel = residentiel['loyer_mensuel'].toString();
        periode = residentiel['periode'] ?? 'mois';
      }
    } else if (property['montant'] != null) {
      montant = property['montant'].toString();
    } else if (property['loyer_mensuel'] != null) {
      loyerMensuel = property['loyer_mensuel'].toString();
      periode = property['periode'] ?? 'mois';
    } else if (property['operation'] != null && property['operation'] is Map) {
      final operation = property['operation'];
      
      if (operation['montant'] != null) {
        montant = operation['montant'].toString();
      }
      if (operation['loyer_mensuel'] != null) {
        loyerMensuel = operation['loyer_mensuel'].toString();
        periode = operation['periode'] ?? 'mois';
      }
    } else if (property['terrain'] != null && property['terrain'] is Map) {
      if (property['terrain']['montant'] != null) {
        montant = property['terrain']['montant'].toString();
      }
    } else if (property['vendre'] != null && property['vendre'] is Map) {
      if (property['vendre']['montant'] != null) {
        montant = property['vendre']['montant'].toString();
      }
    } else if (property['alouer'] != null && property['alouer'] is Map) {
      if (property['alouer']['loyer_mensuel'] != null) {
        loyerMensuel = property['alouer']['loyer_mensuel'].toString();
        periode = property['alouer']['periode'] ?? 'mois';
      }
    }

    return {
      'operationType': operationType,
      'montant': montant,
      'loyerMensuel': loyerMensuel,
      'periode': periode ?? 'mois',
    };
  }

  Map<String, String> _extractLocationInfo(dynamic property) {
    String adresse = '';
    String ville = '';
    
    adresse = property['adresse'] ?? property['address'] ?? property['location'] ?? '';
    
    if (property['ville'] != null) {
      if (property['ville'] is String) {
        ville = property['ville'];
      } else if (property['ville'] is Map) {
        ville = property['ville']['nom'] ?? property['ville']['name'] ?? '';
      }
    }
    
    ville = ville.isEmpty ? property['city'] ?? property['nom_ville'] ?? '' : ville;
    
    return {
      'adresse': adresse,
      'ville': ville,
    };
  }

  String _getImageForCategory(String categoryName) {
    switch (categoryName) {
      case "Appartement": return 'assets/images/appartement.png';
      case "Duplex": return 'assets/images/duplex.png';
      case "Commercial": return 'assets/images/commercial.png';
      case "Terrain": return 'assets/images/landscape.png';
      case "Residentiel": return 'assets/images/resident.png';
      default: return 'assets/images/resident.png';
    }
  }
}

class ModernCategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final int count;
  final VoidCallback? onTap;

  const ModernCategoryCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: pcolor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, name)!,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 7,
                        color: pcolor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}