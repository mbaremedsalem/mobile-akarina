import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/property/property_card.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class Appartement extends StatefulWidget {
  final String typeBien;
  final String title;
  final int count;

  const Appartement({super.key, required this.typeBien, required this.title, required this.count});

  @override
  _AppartementState createState() => _AppartementState();
}

class _AppartementState extends State<Appartement> {
  // Variables principales
  List<Bien> apartments = [];
  bool isLoading = true;
  bool isLoadingCities = true;
  bool hasInternetConnection = true;
  bool hasSearched = false;

  // Variables pour les filtres
  int? selectedVille;
  int? _meublerFilter; // null = tous, 0 = non meublé, 1 = meublé
  String? _selectedOperation; // 'location' ou 'vente'
  double? _prixMin;
  double? _prixMax;

  // Contrôleurs
  TextEditingController _minPriceController = TextEditingController();
  TextEditingController _maxPriceController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  List<Ville> availableCities = [];

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
    int? villeId,
    bool? meubler,
    String? typeTransaction,
    double? prixMin,
    double? prixMax,
    String? searchQuery,
  }) async {
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final page = await BienService().fetchBiens(
        typeBien: widget.typeBien,
        villeId: villeId,
        meuble: meubler,
        typeTransaction: typeTransaction,
        prixMin: (prixMin != null && prixMin > 0) ? prixMin : null,
        prixMax: (prixMax != null && prixMax > 0) ? prixMax : null,
        search: searchQuery,
      );

      setState(() {
        apartments = page.results;
        isLoading = false;
      });
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

  void _applyFilters() {
    bool? meublerFilter;
    if (_meublerFilter != null) {
      meublerFilter = _meublerFilter == 1;
    }

    _loadApartments(
      villeId: selectedVille,
      meubler: meublerFilter,
      typeTransaction: _selectedOperation,
      prixMin: _prixMin,
      prixMax: _prixMax,
      searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  void _resetAllFilters() {
    setState(() {
      selectedVille = null;
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

  // === FONCTION POUR COMPTER LES FILTRES ACTIFS ===
  int _getActiveFiltersCount() {
    int count = 0;
    if (selectedVille != null) count++;
    if (_meublerFilter != null) count++;
    if (_selectedOperation != null && _selectedOperation!.isNotEmpty) count++;
    if (_prixMin != null && _prixMin! > 0) count++;
    if (_prixMax != null && _prixMax! > 0) count++;
    return count;
  }

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



// === DIALOGUE DE FILTRES MODERNISÉ AVEC GESTION DU CLAVIER ===

void _showFilterDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStateBottom) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle (indicateur de glissement)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header avec titre et icône
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [pcolor, pcolor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.filter_list_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          getTranslated(context, "Filtres Avancés")!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenu des filtres avec SingleChildScrollView pour éviter le cache du clavier
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre de recherche moderne
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: _buildModernSearchSection(),
                        ),
                        
                        // Type d'opération
                        _buildModernFilterCard(
                          icon: Icons.business_center_rounded,
                          title: getTranslated(context, 'Type opération')!,
                          child: _buildModernDropdown(
                            value: _selectedOperation,
                            hint: getTranslated(context, 'Tous les types')!,
                            items: [
                              {'value': null, 'label': getTranslated(context, 'Tous les types')!},
                              {'value': 'vente', 'label': getTranslated(context, 'vendre')!},
                              {'value': 'location', 'label': getTranslated(context, 'alouer')!},
                            ],
                            onChanged: (value) {
                              setStateBottom(() {
                                _selectedOperation = value;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Ville
                        _buildModernFilterCard(
                          icon: Icons.location_city_rounded,
                          title: getTranslated(context, 'Ville')!,
                          child: isLoadingCities
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _buildModernDropdown(
                                  value: selectedVille,
                                  hint: getTranslated(context, 'Toutes les villes')!,
                                  items: [
                                    {'value': null, 'label': getTranslated(context, 'Toutes les villes')!},
                                    ...availableCities.map((ville) => {
                                      'value': ville.id,
                                      'label': getCityName(ville),
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setStateBottom(() {
                                      selectedVille = value;
                                    });
                                    setState(() {});
                                  },
                                ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Meublé
                        _buildModernFilterCard(
                          icon: Icons.chair_rounded,
                          title: getTranslated(context, 'Meublé')!,
                          child: _buildModernChips(
                            options: [
                              {'value': null, 'label': getTranslated(context, "Tous")!},
                              {'value': 1, 'label': getTranslated(context, "Meublé")!},
                              {'value': 0, 'label': getTranslated(context, "Non meublé")!},
                            ],
                            selectedValue: _meublerFilter,
                            onChanged: (value) {
                              setStateBottom(() {
                                _meublerFilter = value;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Prix
                        _buildModernFilterCard(
                          icon: Icons.attach_money_rounded,
                          title: getTranslated(context, 'Prix')!,
                          child: _buildModernPriceRange(),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _resetAllFilters();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 18, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      getTranslated(context, "Effacer tout")!,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _applyFilters();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pcolor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      getTranslated(context, "Rechercher")!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Widget pour un champ de prix moderne avec focus
Widget _buildModernPriceField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  required Color iconColor,
  required Function(String) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: Icon(icon, color: iconColor, size: 18),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    ],
  );
}

// Widget pour la barre de recherche moderne
Widget _buildModernSearchSection() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: getTranslated(context, "Rechercher par adresse, ville..."),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: pcolor, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, color: Colors.grey[400], size: 18),
                onPressed: () {
                  _searchController.clear();
                  _loadApartments();
                },
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onSubmitted: (value) => _performSearch(),
    ),
  );
}

// Widget pour une carte de filtre moderne
Widget _buildModernFilterCard({
  required IconData icon,
  required String title,
  required Widget child,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!, width: 1),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: pcolor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: pcolor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

// Widget pour un dropdown moderne
Widget _buildModernDropdown({
  required dynamic value,
  required String hint,
  required List<Map<String, dynamic>> items,
  required Function(dynamic) onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<dynamic>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        items: items.map((item) {
          return DropdownMenuItem<dynamic>(
            value: item['value'],
            child: Text(
              item['label'],
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: pcolor, size: 20),
      ),
    ),
  );
}

// Widget pour les chips modernes
Widget _buildModernChips({
  required List<Map<String, dynamic>> options,
  required dynamic selectedValue,
  required Function(dynamic) onChanged,
}) {
  return Row(
    children: options.map((option) {
      final isSelected = selectedValue == option['value'];
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onChanged(option['value']),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? pcolor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? pcolor : Colors.grey[200]!,
                ),
              ),
              child: Center(
                child: Text(
                  option['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

// Widget pour la plage de prix moderne
Widget _buildModernPriceRange() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildModernPriceField(
              controller: _minPriceController,
              label: getTranslated(context, "Min")!,
              hint: "0",
              icon: Icons.arrow_upward_rounded,
              iconColor: Colors.green,
              onChanged: (value) {
                _prixMin = double.tryParse(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernPriceField(
              controller: _maxPriceController,
              label: getTranslated(context, "Max")!,
              hint: "1,000,000",
              icon: Icons.arrow_downward_rounded,
              iconColor: Colors.red,
              onChanged: (value) {
                _prixMax = double.tryParse(value);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        getTranslated(context, "Laissez vide pour aucun filtre de prix")!,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
    ],
  );
}


  Future<void> fetchCities() async {
    try {
      final villes = await BienService().fetchVilles();
      setState(() {
        availableCities = villes;
        isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCities = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur villes : $e')),
      );
    }
  }

  String getCityName(Ville city) {
    return city.nomFor(Localizations.localeOf(context).languageCode);
  }

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
          if (_showSearchBar)
            Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              child: _buildSearchSection(),
            ),

          // Barre d'outils de filtres MODERNISÉE
          Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: Row(
              children: [
                // Bouton Filtres avec badge
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pcolor, pcolor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showFilterDialog(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_alt_rounded,
                              color: Colors.white,
                              size: getProportionateScreenWidth(18),
                            ),
                            SizedBox(width: getProportionateScreenWidth(8)),
                            Text(
                              getTranslated(context, "Filtres")!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: getProportionateScreenWidth(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_getActiveFiltersCount() > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getActiveFiltersCount().toString(),
                                  style: TextStyle(
                                    color: pcolor,
                                    fontSize: getProportionateScreenWidth(10),
                                    fontWeight: FontWeight.bold,
                                  ),
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
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _resetAllFilters,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: Colors.grey.shade700,
                              size: getProportionateScreenWidth(18),
                            ),
                            SizedBox(width: getProportionateScreenWidth(6)),
                            Text(
                              getTranslated(context, "Effacer")!,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: getProportionateScreenWidth(12),
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

                // Compteur de résultats modernisé
                Container(
                  height: 48,
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(16),
                  ),
                  decoration: BoxDecoration(
                    color: pcolor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: pcolor.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      '${apartments.length}',
                      style: TextStyle(
                        color: pcolor,
                        fontSize: getProportionateScreenWidth(18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
                            crossAxisSpacing: getProportionateScreenWidth(10),
                            mainAxisSpacing: getProportionateScreenHeight(10),
                            childAspectRatio: 0.6,
                          ),
                          itemCount: apartments.length,
                          itemBuilder: (context, index) {
                            return PropertyCard(property: apartments[index]);
                          },
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