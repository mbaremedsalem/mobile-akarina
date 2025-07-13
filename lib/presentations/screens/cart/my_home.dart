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
    ];
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
      
      if (region.isNotEmpty) params.add('region=$region');
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
            // Filtres dans une Card moderne
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PropertyType?>(
                              value: selectedProperty,
                              icon: const Icon(Icons.arrow_drop_down),
                              hint: Text(getTranslated(context, 'Selectionner le Type')!),
                    onChanged: (PropertyType? newValue) {
                      setState(() {
                                  selectedProperty = newValue;
                      });
                    },
                              items: propertyTypes.map((PropertyType? item) {
                      return DropdownMenuItem<PropertyType?>(
                        value: item,
                                  child: Text(getTranslated(context, item?.name ?? '')!),
                      );
                    }).toList(),
                  ),
                ),
              ),
                        const SizedBox(width: 12),
              Expanded(
                child: defaultInputField(
                controller: montantController,
                type: TextInputType.number,
                text: getTranslated(context, 'montant')!,
                prefix: Icons.euro_rounded,
                ), 
              ),
            ],
          ),
                    const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                          child: defaultInputField(
                controller: locationController,
                type: TextInputType.text,
                text: getTranslated(context, 'location')!,
                prefix: Icons.location_on_outlined,
                ),          
              ),
                        const SizedBox(width: 12),
              Expanded(
                child: defaultInputField(
                controller: regionController,
                type: TextInputType.text,
                text: getTranslated(context, 'region')!,
                prefix: Icons.recycling_outlined,
                ), 
              ),
            ],
          ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                            fetchProperties();
                        },
                        icon: const Icon(Icons.search),
                        label: Text(getTranslated(context, 'Search')!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pcolor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: property['images'] != null && property['images'] is List && property['images'].isNotEmpty
                                ? Image.network(
                                    property['images'][0]['image'],
                                    height: 100,
                                    width: double.infinity,
                                      fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 100,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home, size: 30, color: Colors.grey),
                                ),
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
}

class PropertyCard extends StatelessWidget {
  final dynamic property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImmobDetails(id: property['id']),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: property['images'] != null && 
                       property['images'] is List && 
                       property['images'].isNotEmpty
                    ? Image.network(
                        property['images'][0]['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.home, size: 48, color: Colors.grey);
                        },
                      )
                    : const Icon(Icons.home, size: 48, color: Colors.grey),
              ),
            ),
            
            // Détails
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['adresse'] ?? 'Adresse non disponible',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    property['region'] ?? 'Région non spécifiée',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _getPriceText(property),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriceText(dynamic property) {
    if (property['montant'] != null) {
      return '${property['montant']} MRU';
    } else if (property['loyer_mensuel'] != null) {
      return '${property['loyer_mensuel']} MRU/mois';
    }
    return 'Prix sur demande';
  }
}