import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:akarina/data/services/connectivity_service.dart';

class Appartement extends StatefulWidget {
  final String apiUrl; // URL de base de l'API
  final int count;

  const Appartement({super.key, required this.apiUrl, required this.count});

  @override
  _AppartementState createState() => _AppartementState();
}

class _AppartementState extends State<Appartement> {
  List<dynamic> apartments = [];
  bool isLoading = true;
  bool isLoadingCities = true;
  bool hasInternetConnection = true;

  // Variables pour les filtres
  String? selectedVille;
  String? selectedQuarter;
  bool isFurnished = false;
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  String operationType = 'alouer'; // Valeur par défaut

  List<Map<String, dynamic>> availableCities = [];
  List<String> availableQuarters = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
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
      _loadApartments(),
      fetchCities(),
    ]);
  }

  Future<void> _loadApartments({
    String? ville,
    String? adresse,
    bool? meubler,
    String? operation,
    double? montantMin,
    double? montantMax,
    double? prixMin,
    double? prixMax,
  }) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Construire l'URL avec les paramètres de filtre
      Uri uri = Uri.parse(widget.apiUrl);
      Map<String, String> queryParams = {};

      // Ajouter les paramètres existants de l'URL de base
      if (uri.queryParameters.isNotEmpty) {
        queryParams.addAll(uri.queryParameters);
      }

      // Ajouter les nouveaux paramètres de filtre
      if (ville != null && ville.isNotEmpty) {
        queryParams['nom_ville'] = ville;
      }
      if (adresse != null && adresse.isNotEmpty) {
        queryParams['adresse'] = adresse;
      }
      if (meubler != null) {
        queryParams['meubler'] = meubler.toString();
      }
      if (operation != null && operation.isNotEmpty) {
        queryParams['type_operation'] = operation;
      }
      if (prixMin != null) {
        queryParams['loyer_min'] = prixMin.toStringAsFixed(0);
      }
      if (prixMax != null) {
        queryParams['loyer_max'] = prixMax.toStringAsFixed(0);
      }
      // if (montantMin != null) {
      //   queryParams['montant_min'] = montantMin.toStringAsFixed(0);
      // }
      // if (montantMax != null) {
      //   queryParams['montant_max'] = montantMax.toStringAsFixed(0);
      // }
      // Construire la nouvelle URL avec les paramètres
      Uri newUri = uri.replace(queryParameters: queryParams);

      final response = await http.get(newUri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          apartments = data;
          isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des données : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Future<void> fetchCities() async {
    try {
      final response = await http.get(
        Uri.parse('https://akarina.online/akareena/villes/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          availableCities = List<Map<String, dynamic>>.from(
            jsonDecode(utf8.decode(response.bodyBytes)),
          );
          isLoadingCities = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des villes : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingCities = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  String getCityName(Map<String, dynamic> city) {
    final currentLang = Localizations.localeOf(context).languageCode;
    return currentLang == 'ar' ? city['nom_ar'] : city['nom'];
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec titre et bouton fermer
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: pcolor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, "Filtres")!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Contenu des filtres
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type d'opération
                        Text(
                          getTranslated(context, 'Type d\'opération')!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: operationType,
                            onChanged: (String? newValue) {
                              setState(() {
                                operationType = newValue ?? 'alouer';
                              });
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'alouer',
                                child: Text(getTranslated(context, 'alouer')!),
                              ),
                              DropdownMenuItem(
                                value: 'vendre',
                                child: Text(getTranslated(context, 'vendre')!),
                              ),
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Ville
                        Text(
                          getTranslated(context, 'Ville')!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        isLoadingCities
                            ? const Center(child: CircularProgressIndicator())
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedVille,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedVille = newValue;
                                    });
                                  },
                                  items: availableCities.map<DropdownMenuItem<String>>((ville) {
                                    return DropdownMenuItem<String>(
                                      value: ville['nom'],
                                      child: Text(getCityName(ville)),
                                    );
                                  }).toList(),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 4),
                        
                        // Quartier
                        // Text(
                        //   getTranslated(context, 'Quartier')!,
                        //   style: const TextStyle(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.black87,
                        //   ),
                        // ),
                        // const SizedBox(height: 8),
                        
                        // Container(
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(12),
                        //     border: Border.all(color: Colors.grey.shade300),
                        //   ),
                        //   child: DropdownButtonFormField<String>(
                        //     value: selectedQuarter,
                        //     hint: Text(getTranslated(context, 'Quartier')!),
                        //     items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha', 'Nouakchott Ouest', 'Nouakchott Nord']
                        //         .map<DropdownMenuItem<String>>((String value) {
                        //       return DropdownMenuItem<String>(
                        //         value: value,
                        //         child: Text(value),
                        //       );
                        //     }).toList(),
                        //     onChanged: (value) {
                        //       setState(() {
                        //         selectedQuarter = value;
                        //       });
                        //     },
                        //     decoration: const InputDecoration(
                        //       border: InputBorder.none,
                        //       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                        
                        // Prix
                        Text(
                          getTranslated(context, 'Prix')!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: TextField(
                                  controller: minPriceController,
                                  decoration: InputDecoration(
                                    hintText: getTranslated(context, "De"),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: TextField(
                                  controller: maxPriceController,
                                  decoration: InputDecoration(
                                    hintText: getTranslated(context, "À"),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Meublé
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getTranslated(context, "Meubler")!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Switch(
                                value: isFurnished,
                                onChanged: (value) {
                                  setState(() {
                                    isFurnished = value;
                                  });
                                },
                                activeColor: pcolor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedVille = null;
                                    selectedQuarter = null;
                                    minPriceController.clear();
                                    maxPriceController.clear();
                                    isFurnished = false;
                                    operationType = 'alouer';
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(getTranslated(context, "Effacer")!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _loadApartments(
                                    ville: selectedVille,
                                    adresse: selectedQuarter,
                                    meubler: isFurnished,
                                    operation: operationType,
                                    prixMin: double.tryParse(minPriceController.text),
                                    prixMax: double.tryParse(maxPriceController.text),
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pcolor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(getTranslated(context, "apply")!),
                              ),
                            ),
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
      },
    );
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(getTranslated(context, "Recherche Maison")!, style: TextStyle(color: kBlackColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                    icon: Icon(Icons.filter_list, size: getProportionateScreenWidth(16)),
                    label: Text(
                      getTranslated(context, "Filtres")!,
                      style: TextStyle(fontSize: getProportionateScreenWidth(12)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pcolor,
                      side: const BorderSide(color: pcolor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(12),
                        vertical: getProportionateScreenHeight(8),
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedVille = null;
                        selectedQuarter = null;
                        minPriceController.clear();
                        maxPriceController.clear();
                        isFurnished = false;
                        operationType = 'alouer';
                      });
                      _loadApartments();
                    },
                    icon: Icon(Icons.clear, size: getProportionateScreenWidth(16)),
                    label: Text(
                      getTranslated(context, "Effacer les filtres")!,
                      style: TextStyle(fontSize: getProportionateScreenWidth(12)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(12),
                        vertical: getProportionateScreenHeight(8),
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Text(
                    '${apartments.length} ${getTranslated(context, "résultats")}', 
                    style: TextStyle(fontSize: getProportionateScreenWidth(14))
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshableWidget(
              onRefresh: () async {
                await _loadApartments();
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : apartments.isEmpty
                      ? Center(
                          child: Text(
                            getTranslated(context, "Aucun résultat trouvé")!,
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: getProportionateScreenWidth(8),
                            mainAxisSpacing: getProportionateScreenHeight(8),
                            childAspectRatio: 0.75, // Ajusté pour éviter le débordement
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
    final imageUrl = (apartment['images'] != null && apartment['images'].isNotEmpty)
        ? apartment['images'][0]['image']
        : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';

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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
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
                  ),
                ),
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