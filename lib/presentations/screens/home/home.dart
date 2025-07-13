import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/appartement/appartement.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akarina/data/services/connectivity_service.dart';

import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/appartement/appartement.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
  
  String selectedCity = '';
  bool isLoading = true;
  bool isSearch = false;
  bool isLoadingCities = true;
  bool hasInternetConnection = true;
  IconData suffixIcon = Icons.search;

  @override
  void initState() {
    super.initState();
    _initializeData();
    searchController.addListener(_updateSearchIcon);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Vérifier la connectivité internet d'abord
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });
    
    if (!hasConnection) {
      return; // Ne pas charger les données si pas de connexion
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
        Uri.parse("https://akarina.online/akareena/villes/"),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          availableCities = List<Map<String, dynamic>>.from(
            json.decode(utf8.decode(response.bodyBytes)),
          );
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
    if (ville.isEmpty) return;

    setState(() => isSearch = true);

    try {
      final response = await http.get(Uri.parse(
        'https://akarina.online/akareena/residences/filters/?nom_ville=$ville&adresse=$address'
      ));

      if (response.statusCode == 200) {
        setState(() {
          filteredProperties = json.decode(response.body);
          isSearch = false;
        });
      } else {
        setState(() => isSearch = false);
        _showErrorSnackbar(getTranslated(context, "Erreur lors de la recherche")!);
      }
    } catch (error) {
      setState(() => isSearch = false);
      _showErrorSnackbar(error.toString());
    }
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

  Future<void> _loadResidenciel() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final fetchedResidence = await NetworkService().fetchResidence();
      if (!mounted) return;

      setState(() {
        immobilierList = fetchedResidence ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorSnackbar(e.toString());
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
    
    // Afficher la page d'erreur de connexion si pas de connexion internet
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
            slivers: [
              _buildHeaderSection(),
              _buildCategoriesSection(),
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
                Text(
                  getTranslated(context, "Bienvenue sur Akarina")!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslated(context, "Trouvez votre maison de rêve")!,
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
              child: DropdownButton<String>(
                value: selectedCity.isEmpty ? null : selectedCity,
                items: availableCities.map((city) {
                  return DropdownMenuItem<String>(
                    value: city['nom'],
                    child: Text(
                      language == "ar" ? city['nom_ar'] : city['nom'],
                      textDirection: language == "ar" ? TextDirection.rtl : TextDirection.ltr,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) => setState(() => selectedCity = value ?? ''),
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
          if (selectedCity.isNotEmpty) {
            _fetchProperties(selectedCity, searchController.text);
          } else {
            _showErrorSnackbar(getTranslated(context, "Veuillez sélectionner une ville")!);
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
    if (apiUrl.isNotEmpty) {
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
      case 'appartement': return 'https://akarina.online/akareena/appartements/';
      case 'duplex': return 'https://akarina.online/akareena/duplexes/';
      case 'commercial': return 'https://akarina.online/akareena/commerciaux/';
      case 'terrain': return 'https://akarina.online/akareena/terrains/';
      case 'residentiel': return 'https://akarina.online/akareena/residentiels/';
      case 'maisonceremonie': return 'https://akarina.online/akareena/maison_ceremonie';
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
          title: getTranslated(context, "Residentiel")!,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pcolor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isSearch
                ? '${filteredProperties.length} ${getTranslated(context, "résultats")}'
                : '${immobilierList.length} ${getTranslated(context, "propriétés")}',
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
    if (isSearch) {
      return filteredProperties.isNotEmpty
          ? _buildModernPropertyGrid(filteredProperties)
          : _buildEmptyState();
    } else if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return _buildModernPropertyGrid(immobilierList);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
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
    final imageUrl = _resolveImageUrl(property['images']);
    final isTerrain = property['terrain'] != null;
    final isResidentiel = property['residentiel'] != null;
    final operationType = property['operation']['type'];
    final ville = property['ville']['nom'];
    final ratings = property['ratings'] ?? '0.0';
    final adresse = property['adresse'] ?? '';
    final montant = isTerrain ? property['terrain']['montant']?.toString() : null;
    final loyerMensuel = isResidentiel ? property['residentiel']['loyer_mensuel']?.toString() : null;
    final periode = isResidentiel ? property['residentiel']['periode'] : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImmobDetails(id: property['id']),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image section
                Container(
                  height: constraints.maxWidth * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) => const Icon(Icons.home, color: Colors.grey),
                    ),
                  ),
                  child: Stack(
                    children: [
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
                    ],
                  ),
                ),
                
                // Info section
                Padding(
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
                          adresse,
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
                              ville,
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
                        loyerMensuel != null
                            ? '$loyerMensuel MRU/${periode ?? 'mois'}'
                            : '${montant ?? 'N/A'} MRU',
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
              ],
            );
          },
        ),
      ),
    );
  }

  String _resolveImageUrl(dynamic images) {
    if (images != null && images.isNotEmpty) {
      return images[0]['image'];
    }
    return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
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