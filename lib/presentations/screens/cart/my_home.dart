import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/input.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/screens/home/video_player.dart'; // Import du lecteur vidéo

// Classe helper pour gérer la lecture vidéo
class VideoHelper {
  static void playVideo(BuildContext context, String videoUrl) {
    
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(20),
          child: Container(
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

class PropertyType {
  final String name;
  
  PropertyType({required this.name});
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  List<PropertyType> propertyTypes = [];
  PropertyType? selectedProperty;
  TextEditingController montantController = TextEditingController();
  TextEditingController regionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  List<dynamic> filteredProperties = [];
  bool isLoading = false;
  bool hasSearched = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    propertyTypes = [
      PropertyType(name: 'Appartement'),
      PropertyType(name: 'Duplex'),
      PropertyType(name: 'Commercial'),
      PropertyType(name: 'Terrain'),
      PropertyType(name: 'Residentiel'),
      PropertyType(name: 'Maisonceremonie'),
    ];
  }

  // Fonction pour afficher la boîte de dialogue des filtres
void _showFilterDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [pcolor, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslated(context, "Filtres Avancés")!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            getTranslated(context, "Affinez votre recherche")!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Type de propriété avec label
                _buildFilterSection(
                  title: getTranslated(context, "Type de propriété")!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PropertyType?>(
                        value: selectedProperty,
                        icon: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down_rounded, color: pcolor, size: 28),
                        ),
                        isExpanded: true,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            getTranslated(context, 'Selectionner le Type')!,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                        onChanged: (PropertyType? newValue) {
                          setState(() {
                            selectedProperty = newValue;
                          });
                        },
                        items: propertyTypes.map((PropertyType? item) {
                          return DropdownMenuItem<PropertyType?>(
                            value: item,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                getTranslated(context, item?.name ?? '')!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        }).toList(),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Ligne Montant et Localisation - CORRIGÉ
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 400) {
                      // Disposition en ligne pour les écrans larges
                      return Row(
                        children: [
                          Expanded(
                            child: _buildFilterSection(
                              title: getTranslated(context, "Budget maximum")!,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextField(
                                  controller: montantController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: getTranslated(context, 'Ex: 50000')!,
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    prefixIcon: Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'MRU',
                                        style: TextStyle(
                                          color: pcolor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    suffixIcon: montantController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear, color: Colors.black, size: 18),
                                            onPressed: () => montantController.clear(),
                                          )
                                        : null,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilterSection(
                              title: getTranslated(context, "Ville")!,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextField(
                                  controller: locationController,
                                  decoration: InputDecoration(
                                    hintText: getTranslated(context, 'Nom de la ville')!,
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    prefixIcon: Icon(IconBroken.Location, color: pcolor, size: 20),
                                    suffixIcon: locationController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear, color: Colors.black, size: 18),
                                            onPressed: () => locationController.clear(),
                                          )
                                        : null,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Disposition en colonne pour les écrans étroits
                      return Column(
                        children: [
                          _buildFilterSection(
                            title: getTranslated(context, "Budget maximum")!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: montantController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: getTranslated(context, 'Ex: 50000')!,
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'MRU',
                                      style: TextStyle(
                                        color: pcolor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  suffixIcon: montantController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear, color: Colors.black, size: 18),
                                          onPressed: () => montantController.clear(),
                                        )
                                      : null,
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSection(
                            title: getTranslated(context, "Ville")!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  hintText: getTranslated(context, 'Nom de la ville')!,
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(IconBroken.Location, color: pcolor, size: 20),
                                  suffixIcon: locationController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear, color: Colors.black, size: 18),
                                          onPressed: () => locationController.clear(),
                                        )
                                      : null,
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Région/Quartier
                _buildFilterSection(
                  title: getTranslated(context, "Région ou Quartier")!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: regionController,
                      decoration: InputDecoration(
                        hintText: getTranslated(context, 'Ex: Tevragh-Zeina, Arafat...')!,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: Icon(IconBroken.Home, color: pcolor, size: 20),
                        suffixIcon: regionController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.black, size: 18),
                                onPressed: () => regionController.clear(),
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Boutons d'action
                Row(
                  children: [
                    // Bouton Effacer
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                          gradient: LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[50]!],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                selectedProperty = null;
                                montantController.clear();
                                locationController.clear();
                                regionController.clear();
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  getTranslated(context, "Effacer")!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
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
                    
                    // Bouton Rechercher
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
                              Navigator.of(context).pop(); // Fermer la boîte de dialogue
                              fetchProperties(); // Lancer la recherche
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_rounded, color: Colors.white, size: 22),
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
      );
    },
  );
}
  Future<void> fetchProperties() async {
    final type = selectedProperty?.name;
    final montant = montantController.text.trim();
    final region = regionController.text.trim();
    final location = locationController.text.trim();

    if (type == null || type.isEmpty) {
      setState(() {
        errorMessage = getTranslated(context, "Veuillez sélectionner un type de propriété");
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      hasSearched = true;
    });

    try {
      final baseUrl = 'https://akarina.online/akareena/models/filter/$type/';
      final params = <String>[];
      
      if (region.isNotEmpty) params.add('ville__region=$region');
      if (location.isNotEmpty) params.add('location=$location');
      if (montant.isNotEmpty) params.add('max_rent=$montant');
      
      final url = baseUrl + (params.isNotEmpty ? '?${params.join('&')}' : '');
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          filteredProperties = data is List ? data : [];
        });
      } else {
        setState(() {
          errorMessage = getTranslated(context, "Erreur lors de la récupération des données");
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = getTranslated(context, "Erreur de connexion");
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fonction pour extraire l'URL du média (image ou vidéo)
  String _getMediaUrl(dynamic property) {
    try {
      // Vérifier d'abord s'il y a des vidéos
      if (property['videos'] != null && 
          property['videos'] is List && 
          property['videos'].isNotEmpty) {
        final firstVideo = property['videos'][0];
        if (firstVideo['video'] != null && firstVideo['video'].toString().isNotEmpty) {
          return firstVideo['video'].toString();
        }
      }
      
      // Sinon, vérifier les images
      if (property['images'] != null && 
          property['images'] is List && 
          property['images'].isNotEmpty) {
        final firstImage = property['images'][0];
        if (firstImage['image'] != null && firstImage['image'].toString().isNotEmpty) {
          return firstImage['image'].toString();
        }
      }
      
      // Image par défaut
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
    } catch (e) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
    }
  }

  // Fonction pour déterminer si c'est une vidéo
  bool _isVideo(String url) {
    if (url.isEmpty) return false;
    
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.wmv', '.flv', '.mkv'];
    final videoPaths = ['/videos/', '/media/videos/', 'video', 'mp4'];
    
    final lowerUrl = url.toLowerCase();
    
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext)) ||
           videoPaths.any((path) => lowerUrl.contains(path));
  }

  // Widget pour afficher la miniature vidéo
  Widget _buildVideoThumbnail(String videoUrl, BuildContext context) {
    return GestureDetector(
      onTap: () {
        VideoHelper.playVideo(context, videoUrl);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fond de la miniature
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Icon(
              Icons.videocam,
              color: Colors.white.withOpacity(0.6),
              size: 30,
            ),
          ),
          // Bouton play centré
          Positioned.fill(
            child: Center(
              child: Container(
                width: 40,
                height: 40,
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
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool aucunCritere = (selectedProperty == null || selectedProperty?.name == null || selectedProperty?.name == "") &&
        montantController.text.isEmpty &&
        regionController.text.isEmpty &&
        locationController.text.isEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bouton pour ouvrir les filtres
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
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
                    onTap: _showFilterDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_alt_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          getTranslated(context, "Ouvrir les Filtres")!,
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

            // Affichage des critères sélectionnés (optionnel)
            if (selectedProperty != null || 
                montantController.text.isNotEmpty || 
                regionController.text.isNotEmpty || 
                locationController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        getTranslated(context, "Filtres actifs")!,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showFilterDialog,
                      child: Text(
                        getTranslated(context, "Modifier")!,
                        style: TextStyle(
                          color: pcolor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            
            // Affichage conditionnel
            if (aucunCritere && (filteredProperties.isEmpty || isLoading))
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  getTranslated(context, "Trouver la maison de ton home")!,
                  style: const TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            else if (isLoading)
              Immobilierkeleton(heidht: 220, item: 6)
            else if (filteredProperties.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  getTranslated(context, "Aucun résultat trouvé")!,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: filteredProperties.length,
                itemBuilder: (context, index) {
                  var property = filteredProperties[index];
                  final isAvailable = property['available'] == true;
                  final typeOperation = property['type_operation'] ?? '';
                  final periode = property['periode'] ?? '';
                  
                  // Obtenir l'URL du média
                  final mediaUrl = _getMediaUrl(property);
                  final isVideo = _isVideo(mediaUrl);
                  
                  String operationLabel = '';
                  if (typeOperation == 'vendre') {
                    operationLabel = getTranslated(context, 'vendre') ?? 'À vendre';
                  } else if (typeOperation == 'alouer') {
                    operationLabel = getTranslated(context, 'alouer') ?? 'À louer';
                  } else {
                    operationLabel = typeOperation;
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImmobDetails(id: property['id']),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: isVideo
                                      ? _buildVideoThumbnail(mediaUrl, context)
                                      : Image.network(
                                          mediaUrl,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image, color: Colors.grey),
                                            );
                                          },
                                        ),
                                ),
                              ),
                              // Badge vidéo
                              if (isVideo)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "VIDEO",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              // Badge disponibilité
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
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    property['adresse'] ?? getTranslated(context, 'Maison')!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    property['region'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Rating row
                                  Row(
                                    children: [
                                      ...List.generate(5, (starIndex) {
                                        double rating = 0.0;
                                        if (property['ratings'] != null) {
                                          rating = double.tryParse(property['ratings'].toString()) ?? 0.0;
                                        }
                                        return Icon(
                                          Icons.star,
                                          color: starIndex < rating ? Colors.amber : Colors.grey.shade300,
                                          size: 12,
                                        );
                                      }),
                                      const SizedBox(width: 4),
                                      Text(
                                        (property['ratings'] != null
                                                ? (double.tryParse(property['ratings'].toString()) ?? 0.0)
                                                : 0.0)
                                            .toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: typeOperation == 'vendre' ? Colors.red.shade100 : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          operationLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: typeOperation == 'vendre' ? Colors.red : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (periode.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            getTranslated(context, periode) ?? periode,
                                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isAvailable ? Icons.check_circle : Icons.cancel,
                                        color: isAvailable ? Colors.green : Colors.red,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          isAvailable
                                              ? getTranslated(context, 'Available')!
                                              : getTranslated(context, 'Unavailable')!,
                                          style: TextStyle(
                                            color: isAvailable ? Colors.green : Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    property['montant'] != null
                                        ? '${property['montant']} MRU'
                                        : property['loyer_mensuel'] != null
                                            ? '${property['loyer_mensuel']} MRU/${getTranslated(context, periode) ?? periode}'
                                            : getTranslated(context, 'Prix sur demande')!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Helper Widget pour les sections de filtre
  Widget _buildFilterSection({IconData ? icon, required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: pcolor, size: 18),
            const SizedBox(width: 0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}