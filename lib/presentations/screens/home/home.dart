import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/components/spiner.dart';
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic> immobilierSummary = {};
  List<dynamic> immobilierList = [];
  List<dynamic> proximiteList = [];
  List<dynamic> filteredProperties = [];
  bool isLoading = true;
  bool isSearch = false;
  final storage = const FlutterSecureStorage();
  TextEditingController searchController = TextEditingController();
  IconData suffixIcon = Icons.search;
  String selectedCity = '';

  List<Map<String, dynamic>> availableCities = [];
  bool isLoadingCities = true;

  Future<void> fetchCities() async {
    try {
      final response = await http.get(
        Uri.parse("https://akarina.online/akareena/villes/"),
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
        throw Exception(
            "Erreur lors du chargement des villes : ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoadingCities = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  Future<void> fetchProperties(String ville, String address) async {
    if (ville.isNotEmpty) {
      setState(() {
        isSearch = true;
      });

      final url = Uri.parse(
          'https://akarina.online/akareena/residences/filters/?nom_ville=$ville&adresse=$address');

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          setState(() {
            filteredProperties = json.decode(response.body);
            isSearch = false;
          });
        } else {
          setState(() {
            isSearch = false;
          });
        }
      } catch (error) {
        setState(() {
          isSearch = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    NetworkService networkService = NetworkService();
    final fetchedCategories = await networkService.fetchCategories();

    if (fetchedCategories != null) {
      setState(() {
        immobilierSummary = fetchedCategories;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadResidenciel() async {
    NetworkService networkService = NetworkService();
    final fetchedResidence = await networkService.fetchResidence();

    if (fetchedResidence != null) {
      setState(() {
        immobilierList = fetchedResidence;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProximite() async {
    NetworkService networkService = NetworkService();
    final fetchproximite = await networkService.fetchProximite();

    if (fetchproximite != null) {
      setState(() {
        proximiteList = fetchproximite;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadResidenciel();
    _loadCategories();
    _loadProximite();
    fetchCities();
    searchController.addListener(() {
      setState(() {
        suffixIcon = searchController.text.isEmpty ? Icons.search : Icons.close;
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Image(
                    image: AssetImage('assets/images/home.jpeg'),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        FutureBuilder<String>(
                          future: getCurrentLanguage(
                              context), // Récupérer la langue actuelle
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return spiner(); // Afficher un spinner si la langue n'est pas encore récupérée
                            }

                            String language =
                                snapshot.data!; // Langue actuelle (fr ou ar)

                            return TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: getTranslated(context,
                                    "Sélectionnez une ville et entrez une adresse...")!,
                                prefixIcon: DropdownButtonHideUnderline(
                                  child: isLoadingCities
                                      ? spiner()
                                      : DropdownButton<String>(
                                          value: selectedCity.isEmpty
                                              ? null
                                              : selectedCity,
                                          items: availableCities.map((city) {
                                            return DropdownMenuItem<String>(
                                              value: city[
                                                  'nom'], // Toujours stocker en français
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .only(start: 8.0),
                                                child: Text(
                                                  language == "ar"
                                                      ? city['nom_ar']
                                                      : city[
                                                          'nom'], // Afficher le bon texte
                                                  textDirection: language ==
                                                          "ar"
                                                      ? TextDirection
                                                          .rtl // RTL pour l'arabe
                                                      : TextDirection
                                                          .ltr, // LTR pour le français
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              selectedCity = value ?? '';
                                            });
                                          },
                                          hint: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(
                                                start:
                                                    24.0), // Utilisation de start au lieu de left
                                            child: Text(
                                              getTranslated(context, "Ville")!,
                                              textDirection:
                                                  getCurrentLanguage(context) ==
                                                          "ar"
                                                      ? TextDirection.rtl
                                                      : TextDirection.ltr,
                                            ),
                                          ),
                                        ),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    if (selectedCity.isNotEmpty) {
                                      fetchProperties(
                                          selectedCity, searchController.text);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Veuillez sélectionner une ville")),
                                      );
                                    }
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                        if (isSearch) const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              isLoading
                  ? CategorySkeleton()
                  : SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: immobilierSummary.length,
                        itemBuilder: (context, index) {
                          List<String> keys = immobilierSummary.keys.toList();
                          String categoryName =
                              immobilierSummary[keys[index]]['name'];
                          int categoryCount = immobilierSummary[keys[index]]
                              ['count']; // Récupérer le count
                          String imagePath = _getImageForCategory(
                              categoryName); // Obtenir l'image associée

                          return InkWell(
                            onTap: () {
                              // Déterminer l'URL de l'API en fonction de la catégorie
                              String apiUrl;
                              switch (categoryName.toLowerCase()) {
                                case 'appartement':
                                  apiUrl =
                                      'https://akarina.online/akareena/appartements/';
                                  break;
                                case 'duplex':
                                  apiUrl =
                                      'https://akarina.online/akareena/duplexes/';
                                  break;
                                case 'commercial':
                                  apiUrl =
                                      'https://akarina.online/akareena/commerciaux/';
                                  break;
                                case 'terrain':
                                  apiUrl =
                                      'https://akarina.online/akareena/terrains/';
                                  break;
                                case 'residentiel':
                                  apiUrl =
                                      'https://akarina.online/akareena/residentiels/';
                                  break;
                                default:
                                  apiUrl = ''; // Gérer les cas non prévus
                              }

                              // Naviguer vers la page concernée avec l'URL de l'API
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Appartement(
                                      apiUrl: apiUrl, count: categoryCount),
                                ),
                              );
                            },
                            child: CategoryCard(
                              name: categoryName,
                              imagePath:
                                  imagePath, // Passer le chemin de l'image
                            ),
                          );
                        },
                      ),
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, "Residentiel")!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const Spacer(),
                  const Icon(IconBroken.Arrow___Right_Circle),
                ],
              ),
              const SizedBox(height: 15),
              isSearch
                  ? filteredProperties.isNotEmpty
                      ? _buildPropertyGrid(filteredProperties)
                      : Center(
                          child: Text(getTranslated(
                              context, "Aucune propriété trouvée")!),
                        )
                  : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPropertyGrid(immobilierList),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyGrid(List<dynamic> properties) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        String imageUrl = _resolveImageUrl(property['images']);

        // Déterminer si c'est un terrain ou un résidentiel
        final isTerrain = property['terrain'] != null;
        final isResidentiel = property['residentiel'] != null;

        // Récupérer les données spécifiques
        final operationType = property['operation']['type'];
        final ville = property['ville']['nom'];
        final ratings = property['ratings'];
        final adresse = property['adresse'];
        final surface = property['surface'];

        // Récupérer le montant ou le loyer mensuel
        final montant = isTerrain
            ? property['terrain']['montant']
            : isResidentiel
                ? property['residentiel']['montant']
                : null;
        final loyerMensuel =
            isResidentiel ? property['residentiel']['loyer_mensuel'] : null;
        final periode =
            isResidentiel ? property['residentiel']['periode'] : null;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImmobDetails(id: property['id']),
              ),
            );
          },
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 150);
                          },
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: operationType == 'alouer'
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            getTranslated(context, operationType)!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loyerMensuel != null
                              ? '${loyerMensuel?.toStringAsFixed(0)} ${getTranslated(context, 'MRU')!} / ${getTranslated(context, periode)!}'
                              : '${montant?.toStringAsFixed(0)} ${getTranslated(context, 'MRU')!}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/localisation.jpeg',
                              width: 25,
                              height: 25,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                ville ?? 'Ville non spécifiée',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(5, (starIndex) {
                            double rating =
                                double.tryParse(ratings ?? '0.0') ?? 0.0;
                            return Icon(
                              Icons.star,
                              color: starIndex < rating
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isResidentiel)
                              _buildFeatureIcon(
                                const AssetImage('assets/images/chambre.jpeg'),
                                property['residentiel']['nombre_de_chambres'],
                                'Chambres',
                              ),
                            if (isResidentiel)
                              _buildFeatureIcon(
                                const AssetImage('assets/images/douche.jpeg'),
                                property['residentiel']
                                    ['nombre_de_salles_de_bain'],
                                'Salle de bain',
                              ),
                            if (isResidentiel)
                              _buildFeatureIcon(
                                const AssetImage('assets/images/gardient.jpeg'),
                                property['residentiel']
                                        ['presence_chambre_gardient']
                                    ? 1
                                    : 0,
                                'Chambre gardien',
                              ),
                            if (isResidentiel)
                              _buildFeatureIcon(
                                const AssetImage('assets/images/garage.jpeg'),
                                property['residentiel']['nombre_de_garages'],
                                'Garage',
                              ),
                            if (isTerrain)
                              _buildFeatureIcon(
                                const AssetImage('assets/images/landscape.png'),
                                1, // Exemple pour un terrain
                                'Terrain',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcon(AssetImage image, int? value, String tooltip) {
    return Row(
      children: [
        Image(
          image: image, // Utilisation de l'image passée en paramètre
          fit: BoxFit.cover,
          width: 24, // Définir une largeur fixe appropriée
          height: 24, // Définir une hauteur fixe appropriée
        ),
        const SizedBox(width: 5), // Espace entre l'image et le texte
        Text(
          value?.toString() ?? '0',
          style: const TextStyle(
              fontSize: 14, color: Colors.black), // Style de texte
        ),
      ],
    );
  }

  String _resolveImageUrl(dynamic images) {
    if (images != null && images.isNotEmpty) {
      String imagePath = images[0]['image'];
      return imagePath;
    }
    return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
  }

  String _getImageForCategory(String categoryName) {
    switch (categoryName) {
      case "Appartement":
        return 'assets/images/appartement.png';
      case "Duplex":
        return 'assets/images/duplex.png';
      case "Commercial":
        return 'assets/images/commercial.png';
      case "Terrain":
        return 'assets/images/landscape.png';
      case "Residentiel":
        return 'assets/images/resident.png';
      default:
        return 'assets/images/resident.png';
    }
  }
}

class CategoryCard extends StatelessWidget {
  final String name;
  final String imagePath; // Chemin de l'image

  const CategoryCard({
    super.key,
    required this.name,
    required this.imagePath, // Changement pour utiliser une image
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              imagePath, // Utilisation de l'image à la place de l'icône
              width: 35,
              height: 35,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          getTranslated(context, name)!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
