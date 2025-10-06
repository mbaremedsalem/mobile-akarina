import 'package:flutter/material.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';

class SearchBarWidget extends StatefulWidget {
  final String selectedCity;
  final String selectedRegion;
  final String searchText;
  final List<Map<String, dynamic>> cities;
  final List<Map<String, dynamic>> regions;
  final bool isLoadingCities;
  final bool isLoadingRegions;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onSearchTextChanged;
  final VoidCallback onSearchPressed;

  const SearchBarWidget({
    super.key,
    required this.selectedCity,
    required this.selectedRegion,
    required this.searchText,
    required this.cities,
    required this.regions,
    required this.isLoadingCities,
    required this.isLoadingRegions,
    required this.onCityChanged,
    required this.onRegionChanged,
    required this.onSearchTextChanged,
    required this.onSearchPressed,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _currentLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchText;
    _loadCurrentLanguage();
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.searchText) {
      _searchController.text = widget.searchText;
    }
  }

  Future<void> _loadCurrentLanguage() async {
    // Implémentez cette méthode selon votre système de localisation
    // _currentLanguage = await getCurrentLanguage(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          // Ligne pour ville et région
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _buildCityDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildRegionDropdown()),
              ],
            ),
          ),
          // Champ de recherche d'adresse
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchTextChanged,
                    decoration: InputDecoration(
                      hintText: getTranslated(context, "Entrez une adresse...")!,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                _buildSearchButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pcolor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.isLoadingCities
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedCity.isEmpty ? null : widget.selectedCity,
                items: widget.cities.map((city) {
                  return DropdownMenuItem<String>(
                    value: city['nom'],
                    child: Text(
                      _currentLanguage == "ar" ? city['nom_ar'] : city['nom'],
                      textDirection: _currentLanguage == "ar" 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) => widget.onCityChanged(value ?? ''),
                hint: Text(
                  getTranslated(context, "Ville")!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                icon: Icon(Icons.keyboard_arrow_down, color: pcolor, size: 16),
                isExpanded: true,
              ),
            ),
    );
  }

  Widget _buildRegionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pcolor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.isLoadingRegions
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedRegion.isEmpty ? null : widget.selectedRegion,
                items: widget.regions.map((region) {
                  return DropdownMenuItem<String>(
                    value: region['nom'],
                    child: Text(
                      _currentLanguage == "ar" ? region['nom_ar'] ?? region['nom'] : region['nom'],
                      textDirection: _currentLanguage == "ar" 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) => widget.onRegionChanged(value ?? ''),
                hint: Text(
                  getTranslated(context, "Région")!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                icon: Icon(Icons.keyboard_arrow_down, color: pcolor, size: 16),
                isExpanded: true,
              ),
            ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pcolor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.search, color: Colors.white, size: 20),
        onPressed: widget.onSearchPressed,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}