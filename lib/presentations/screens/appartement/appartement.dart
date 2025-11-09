import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:akarina/data/services/connectivity_service.dart';

// Classe helper pour gérer la lecture vidéo
class VideoHelper {
  static void playVideo(BuildContext context, String videoUrl) {
    
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            child: VideoPlayerWidget(videoUrl: videoUrl),
          ),
        ),
      );
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: Impossible de lire la vidéo')),
      );
    }
  }
}

class Appartement extends StatefulWidget {
  final String apiUrl;
  final int count;

  const Appartement({super.key, required this.apiUrl, required this.count});

  @override
  _AppartementState createState() => _AppartementState();
}

class _AppartementState extends State<Appartement> {
  // Variables principales
  List<dynamic> apartments = [];
  bool isLoading = true;
  bool isLoadingCities = true;
  bool hasInternetConnection = true;
  bool hasSearched = false;

  // Variables pour les filtres
  String? selectedVille;
  String? selectedQuarter;
  int? _meublerFilter; // null = tous, 0 = non meublé, 1 = meublé
  String? _selectedOperation;
  double? _prixMin;
  double? _prixMax;

  // Contrôleurs
  TextEditingController _minPriceController = TextEditingController();
  TextEditingController _maxPriceController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  List<Map<String, dynamic>> availableCities = [];
  List<String> availableQuarters = [];

  @override
  void initState() {
    super.initState();

    _initializeData();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {

    final hasConnection = await ConnectivityService.hasInternetConnection();
    
    setState(() {
      hasInternetConnection = hasConnection;
    });
    
    if (!hasConnection) {
      return;
    }
    
    try {
      await Future.wait([
        _loadApartments(),
        fetchCities(),
      ]);
    } catch (e) {
    }
  }

  Future<void> _loadApartments({
    String? ville,
    String? adresse,
    bool? meubler,
    String? operation,
    double? prixMin,
    double? prixMax,
    String? searchQuery,
  }) async {

    
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      Uri uri = Uri.parse(widget.apiUrl);
      Map<String, String> queryParams = {};

      // Ajouter les paramètres existants de l'URL de base
      if (uri.queryParameters.isNotEmpty) {
        queryParams.addAll(uri.queryParameters);
      }

      // === FILTRES AMÉLIORÉS ===
      
      // Filtre par recherche texte
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      
      // Filtre par ville
      if (ville != null && ville.isNotEmpty) {
        queryParams['ville'] = ville;
      }
      
      // Filtre par adresse
      if (adresse != null && adresse.isNotEmpty) {
        queryParams['adresse'] = adresse;
      }
      
      // Filtre meublé
      if (meubler != null) {
        queryParams['meubler'] = meubler.toString();
      }
      
      // Filtre opération
      if (operation != null && operation.isNotEmpty) {
        queryParams['operation'] = operation;
      }
      
      // Filtres prix
      if (prixMin != null && prixMin > 0) {
        queryParams['prix_min'] = prixMin.toStringAsFixed(0);
      }
      if (prixMax != null && prixMax > 0) {
        queryParams['prix_max'] = prixMax.toStringAsFixed(0);
      }


      // Construire l'URL finale
      Uri newUri = uri.replace(queryParameters: queryParams);


      final response = await http.get(newUri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        List<dynamic> apartmentsList = [];
        
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          apartmentsList = data['results'];
        } else if (data is List) {
          apartmentsList = data;
        } else {
          throw Exception('Format de réponse inconnu');
        }
        
        setState(() {
          apartments = apartmentsList;
          isLoading = false;
        });
        
        
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === FONCTIONS DE GESTION DES FILTRES ===

  void _applyFilters() {
    
    bool? meublerFilter;
    if (_meublerFilter != null) {
      meublerFilter = _meublerFilter == 1;
    }
    
    _loadApartments(
      ville: selectedVille,
      adresse: selectedQuarter,
      meubler: meublerFilter,
      operation: _selectedOperation,
      prixMin: _prixMin,
      prixMax: _prixMax,
      searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  void _resetAllFilters() {

    setState(() {
      selectedVille = null;
      selectedQuarter = null;
      _meublerFilter = null;
      _selectedOperation = null;
      _prixMin = null;
      _prixMax = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _searchController.clear();
      _showSearchBar = false;
    });
    
    _loadApartments();
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {

      _loadApartments(searchQuery: _searchController.text);
    }
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _loadApartments();
      }
    });
  }

  // === WIDGETS POUR LES FILTRES ===

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: getTranslated(context, "Rechercher par adresse, ville..."),
          prefixIcon: Icon(Icons.search_rounded, color: pcolor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchController.clear();
                    _loadApartments();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (value) => _performSearch(),
      ),
    );
  }

  Widget _buildMeublerFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chair_rounded, color: pcolor, size: 20),
              const SizedBox(width: 8),
              Text(
                getTranslated(context, "Meublé")!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: getTranslated(context, "Tous")!,
                  isSelected: _meublerFilter == null,
                  onTap: () {
                    setState(() {
                      _meublerFilter = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: getTranslated(context, "Meublé")!,
                  isSelected: _meublerFilter == 1,
                  onTap: () {
                    setState(() {
                      _meublerFilter = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: getTranslated(context, "Non meublé")!,
                  isSelected: _meublerFilter == 0,
                  onTap: () {
                    setState(() {
                      _meublerFilter = 0;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? pcolor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? pcolor : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({required IconData icon, required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: pcolor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // === DIALOGUE DE FILTRES MODERNE ===

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          elevation: 10,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec dégradé
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [pcolor, Colors.blue.shade700],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          getTranslated(context, "Filtres Avancés")!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenu des filtres
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barre de recherche
                          _buildSearchSection(),
                          
                          const SizedBox(height: 20),
                          
                          // Type d'opération
                          _buildFilterSection(
                            icon: Icons.business_center_rounded,
                            title: getTranslated(context, 'Type opération')!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedOperation,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedOperation = newValue;
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(getTranslated(context, 'Tous les types')!),
                                  ),
                                  DropdownMenuItem(
                                    value: 'vendre',
                                    child: Text(getTranslated(context, 'vendre')!),
                                  ),
                                  DropdownMenuItem(
                                    value: 'alouer',
                                    child: Text(getTranslated(context, 'alouer')!),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Ville
                          _buildFilterSection(
                            icon: Icons.location_city_rounded,
                            title: getTranslated(context, 'Ville')!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isLoadingCities
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(pcolor),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            getTranslated(context, 'Chargement...')!,
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: selectedVille,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedVille = newValue;
                                        });
                                      },
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            getTranslated(context, 'Toutes les villes')!,
                                            style: TextStyle(color: Colors.grey.shade500),
                                          ),
                                        ),
                                        ...availableCities.map<DropdownMenuItem<String>>((ville) {
                                          return DropdownMenuItem<String>(
                                            value: ville['nom'],
                                            child: Text(
                                              getCityName(ville),
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Filtre Meublé
                          _buildMeublerFilter(),
                          
                          const SizedBox(height: 20),
                          
                          // Prix
                          _buildFilterSection(
                            icon: Icons.attach_money_rounded,
                            title: getTranslated(context, 'Prix')!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                getTranslated(context, "Prix minimum")!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: TextField(
                                                  controller: _minPriceController,
                                                  decoration: InputDecoration(
                                                    hintText: "0",
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                    prefixIcon: Icon(Icons.arrow_upward_rounded, 
                                                        color: Colors.green.shade600, size: 18),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (value) {
                                                    _prixMin = double.tryParse(value);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                getTranslated(context, "Prix maximum")!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: TextField(
                                                  controller: _maxPriceController,
                                                  decoration: InputDecoration(
                                                    hintText: "1000000",
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                    prefixIcon: Icon(Icons.arrow_downward_rounded, 
                                                        color: Colors.red.shade600, size: 18),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (value) {
                                                    _prixMax = double.tryParse(value);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      getTranslated(context, "Laissez vide pour aucun filtre de prix")!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Boutons d'action
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade300),
                                    gradient: LinearGradient(
                                      colors: [Colors.grey.shade100, Colors.grey.shade50],
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _resetAllFilters,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh_rounded, 
                                              color: Colors.grey.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            getTranslated(context, "Effacer")!,
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [pcolor, Colors.blue.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: pcolor.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        _applyFilters();
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.search_rounded, 
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            getTranslated(context, "Rechercher")!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // === FONCTIONS EXISTANTES (gardez celles-ci) ===

  Future<void> fetchCities() async {

    try {
      final url = 'https://akarina.shop/akareena/villes/';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );


      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          
          if (data is List) {
            setState(() {
              availableCities = List<Map<String, dynamic>>.from(data);
              isLoadingCities = false;
            });

          } else {

            throw Exception('Format de données villes invalide');
          }
        } catch (e) {
          throw Exception('Erreur de décodage JSON des villes: $e');
        }
      } else {

        throw Exception('Erreur lors du chargement des villes : ${response.statusCode}');
      }
    } catch (e) {

      setState(() {
        isLoadingCities = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur villes : $e')),
      );
    }
  }

  String getCityName(Map<String, dynamic> city) {
    final currentLang = Localizations.localeOf(context).languageCode;
    final name = currentLang == 'ar' ? city['nom_ar'] : city['nom'];
    return name;
  }

  // === BUILD METHOD AMÉLIORÉE ===

  @override
  Widget build(BuildContext context) {

    if (!hasInternetConnection) {
      return NoInternetPage();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar' 
              ? IconBroken.Arrow___Right_2
              : IconBroken.Arrow___Left_2,
              color: kBlackColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(getTranslated(context, "Recherche Maison")!, style: TextStyle(color: kBlackColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche principale
          if (_showSearchBar)
            Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              child: _buildSearchSection(),
            ),

          // Barre d'outils de filtres
          Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Bouton Filtres
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pcolor, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: pcolor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () => _showFilterDialog(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(16),
                            vertical: getProportionateScreenHeight(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt_rounded, color: Colors.white, size: getProportionateScreenWidth(16)),
                              SizedBox(width: getProportionateScreenWidth(8)),
                              Text(
                                getTranslated(context, "Filtres")!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: getProportionateScreenWidth(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: getProportionateScreenWidth(12)),

                  // Bouton Effacer
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: _resetAllFilters,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(16),
                            vertical: getProportionateScreenHeight(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, color: Colors.grey.shade700, size: getProportionateScreenWidth(16)),
                              SizedBox(width: getProportionateScreenWidth(8)),
                              Text(
                                getTranslated(context, "Effacer")!,
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: getProportionateScreenWidth(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: getProportionateScreenWidth(12)),

                  // Compteur de résultats
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                      vertical: getProportionateScreenHeight(10),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      '${apartments.length} ${getTranslated(context, "résultats")}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: getProportionateScreenWidth(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu principal
          Expanded(
            child: RefreshableWidget(
              onRefresh: () async {
                await _loadApartments();
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : apartments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasSearched ? Icons.search_off_rounded : Icons.home_work_rounded,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                hasSearched 
                                    ? getTranslated(context, "Aucun résultat trouvé")!
                                    : getTranslated(context, "Aucun bien disponible")!,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (hasSearched)
                                TextButton(
                                  onPressed: _resetAllFilters,
                                  child: Text(getTranslated(context, "Réinitialiser les filtres")!),
                                ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: getProportionateScreenWidth(8),
                            mainAxisSpacing: getProportionateScreenHeight(8),
                            childAspectRatio: 0.75,
                          ),
                          itemCount: apartments.length,
                          itemBuilder: (context, index) {
                            final apartment = apartments[index];
                            return ApartmentCardModern(apartment: apartment);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// Gardez les classes ApartmentCardModern, IconInfo et VideoHelper existantes
// (Elles sont déjà bien optimisées dans votre code original)

// ... (Vos classes ApartmentCardModern, IconInfo restent inchangées)
// Nouvelle carte moderne pour appartement
class ApartmentCardModern extends StatelessWidget {
  final dynamic apartment;

  const ApartmentCardModern({super.key, required this.apartment});

  @override
  Widget build(BuildContext context) {

    
    double rating = 0.0;
    if (apartment['ratings'] != null) {
      rating = double.tryParse(apartment['ratings'].toString()) ?? 0.0;
    }
    final isAvailable = apartment['available'] == true;
    final isFurnished = apartment['meubler'] == true;
    final operation = apartment['type_operation'] ?? 'alouer';
    final badgeColor = operation == 'vendre' ? Colors.red.shade100 : Colors.blue.shade100;
    final badgeTextColor = operation == 'vendre' ? Colors.red : Colors.blue;
    
    // Vérifier s'il y a des vidéos
    final hasVideos = apartment['videos'] != null && apartment['videos'].isNotEmpty;
    final hasImages = apartment['images'] != null && apartment['images'].isNotEmpty;
    
    String mediaUrl = '';
    bool isVideo = false;
    
    // Priorité aux vidéos
    if (hasVideos) {
      mediaUrl = apartment['videos'][0]['video'] ?? '';
      isVideo = true;
    } else if (hasImages) {
      mediaUrl = apartment['images'][0]['image'] ?? '';
    } else {
      mediaUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
    }

    // S'assurer que l'URL est absolue
    if (mediaUrl.startsWith('/')) {
      mediaUrl = 'https://akarina.shop$mediaUrl';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImmobDetails(id: apartment['id']),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Conteneur pour l'image ou la vidéo
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: getProportionateScreenHeight(100),
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: isVideo
                        ? _buildVideoThumbnail(mediaUrl, context)
                        : _buildImage(mediaUrl),
                  ),
                ),
                
                // Badge de disponibilité
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable
                          ? getTranslated(context, "Available")!
                          : getTranslated(context, "Unavailable")!,
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: getProportionateScreenWidth(8), 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                
                // Badge vidéo si c'est une vidéo
                if (isVideo)
                  Positioned(
                    top: 4,
                    right: 40, // Décalé pour laisser de la place au favori
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: getProportionateScreenWidth(8)),
                          SizedBox(width: 2),
                          Text(
                            getTranslated(context, "Video") ?? "VIDEO",
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: getProportionateScreenWidth(7), 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Bouton favori
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: getProportionateScreenWidth(12),
                    child: Icon(
                      Icons.favorite_border, 
                      color: Colors.red, 
                      size: getProportionateScreenWidth(14)
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(getProportionateScreenWidth(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badges
                    Wrap(
                      spacing: 2,
                      runSpacing: 1,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            getTranslated(context, operation) ?? operation,
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(7), 
                              color: badgeTextColor, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        if (isFurnished)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              getTranslated(context, "Meubler")!,
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(7), 
                                color: Colors.orange, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(3)),
                    
                    // Adresse
                    Flexible(
                      child: Text(
                        apartment['adresse'] ?? getTranslated(context, 'Maison')!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: getProportionateScreenWidth(10)
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: getProportionateScreenHeight(2)),
                    
                    // Rating
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(5, (starIndex) => Icon(
                          Icons.star,
                          color: starIndex < rating ? Colors.amber : Colors.grey.shade300,
                          size: getProportionateScreenWidth(8),
                        )),
                        SizedBox(width: getProportionateScreenWidth(2)),
                        Text(
                          rating.toStringAsFixed(1), 
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(7), 
                            fontWeight: FontWeight.w600
                          )
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Prix
                    Flexible(
                      child: Text(
                        apartment['montant'] != null
                            ? '${apartment['montant']} ${getTranslated(context, "MRU") ?? "MRU"}'
                            : apartment['loyer_mensuel'] != null
                                ? '${apartment['loyer_mensuel']} ${getTranslated(context, "MRU") ?? "MRU"} / ${getTranslated(context, apartment['periode'] ?? "Inconnu") ?? apartment['periode'] ?? "Inconnu"}'
                                : getTranslated(context, 'Prix sur demande')!,
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(10), 
                          fontWeight: FontWeight.bold, 
                          color: Colors.green
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: getProportionateScreenHeight(4)),
                    
                    // Icônes d'information
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconInfo(icon: Icons.bed, value: apartment['nombre_de_chambres']?.toString() ?? "-"),
                        IconInfo(icon: Icons.bathtub_outlined, value: apartment['nombre_de_salles_de_bain']?.toString() ?? "-"),
                        IconInfo(icon: Icons.square_foot, value: apartment['surface']?.toString() ?? "-"),
                        IconInfo(icon: Icons.account_balance_outlined, value: apartment['etage']?.toString() ?? "-"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une image
  Widget _buildImage(String imageUrl) {
    return Image.network(
      imageUrl,
      height: getProportionateScreenHeight(100),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {

        return Container(
          height: getProportionateScreenHeight(100),
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.grey),
        );
      },
    );
  }

  // Widget pour afficher une miniature vidéo avec bouton de lecture
  Widget _buildVideoThumbnail(String videoUrl, BuildContext context) {
    return GestureDetector(
      onTap: () {
        VideoHelper.playVideo(context, videoUrl);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fond de la miniature avec une couleur de fond
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Icon(
              Icons.videocam, 
              color: Colors.white.withOpacity(0.6), 
              size: getProportionateScreenWidth(30)
            ),
          ),
          
          // Bouton play centré
          Positioned.fill(
            child: Center(
              child: Container(
                width: getProportionateScreenWidth(40),
                height: getProportionateScreenWidth(40),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow, 
                  color: Colors.white, 
                  size: getProportionateScreenWidth(24)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IconInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const IconInfo({super.key, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon, 
          size: getProportionateScreenWidth(9), 
          color: Colors.grey
        ),
        SizedBox(height: getProportionateScreenHeight(1)),
        Text(
          value, 
          style: TextStyle(fontSize: getProportionateScreenWidth(7))
        ),
      ],
    );
  }
}