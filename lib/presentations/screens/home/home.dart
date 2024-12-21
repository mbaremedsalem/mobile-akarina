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
  final storage = FlutterSecureStorage();
  TextEditingController searchController = TextEditingController();
  IconData suffixIcon = Icons.search;
  String selectedCity = '';

  // List of available cities
  final List<String> availableCities = [
    'Noukchott',
    'Nouadhibou',
    'Rosso',
    'Kaédi',
    'Zouerate',
    // Add more cities as needed
  ];

    Future<void> fetchProperties(String ville, String address) async {
      if (ville.isNotEmpty ) {
        setState(() {
          isSearch = true;  // Show loading indicator while fetching data
        });

        final url = Uri.parse(
            'https://akarina-9865f1a90dee.herokuapp.com/akareena/residences/filters/?nom_ville=$ville&adresse=$address'
        );
        
        try {
          final response = await http.get(url);

          if (response.statusCode == 200) {
            print(response.body);
            setState(() {
              filteredProperties = json.decode(response.body);  // Store the fetched properties
              isSearch = false;  // Hide loading indicator after data is fetched
            });
          } else {
            print('Failed to load properties: ${response.statusCode}');
            setState(() {
              isSearch = false;  // Hide loading indicator if there is an error
            });
          }
        } catch (error) {
          print('Error occurred: $error');
          setState(() {
            isSearch = false;  // Hide loading indicator on error
          });
        }
      }
    }

    Future<void> _loadCategories() async {
    NetworkService networkService = NetworkService();

    // Appeler la méthode fetchCategories en passant le token
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

    // Appeler la méthode fetchCategories en passant le token
    final fetchedresidence = await networkService.fetchResidence();

    if (fetchedresidence != null) {
      setState(() {
        immobilierList = fetchedresidence;
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

    // Appeler la méthode fetchCategories en passant le token
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
@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar and background image
            Stack(
              alignment: Alignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/images/house 1.png'),
                  fit: BoxFit.cover,
                  width: double.infinity, // Ensure the image covers full width
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34.0),
                  child: Column(
                    children: [
                       Text(
                        getTranslated(context, "Le site immobilier préféré des professionnels")!,
                        // 'Le site immobilier préféré des professionnels',
                        textAlign: TextAlign.center, // Center the text
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Input field with dropdown for city and text input for address
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: getTranslated(context, "Sélectionnez une ville et entrez une adresse...s")!,
                          prefixIcon: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCity.isEmpty ? null : selectedCity,
                              items: availableCities.map((String city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(city),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedCity = value ?? '';
                                });
                              },
                              hint:  Padding(
                                padding: EdgeInsets.only(left: 24.0),
                                child: Text(getTranslated(context, "Ville")!),
                              ),
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (selectedCity.isNotEmpty) {
                                fetchProperties(selectedCity, searchController.text); // Trigger search on click
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (isSearch) const CircularProgressIndicator(), // Display loading indicator while fetching data
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Categories Section
            isLoading
                ? CategorySkeleton() // Show skeleton loader when fetching categories
                : Container(
                  height: 150, // Adjust height to accommodate the card and text
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                    itemCount: immobilierSummary.length,
                    itemBuilder: (context, index) {
                      List<String> keys = immobilierSummary.keys.toList();
                      String categoryName = immobilierSummary[keys[index]]['name'];
                      int categoryCount = immobilierSummary[keys[index]]['count'];
                      IconData icon = _getIconForCategory(categoryName); // Get the right icon for each category
                      
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Appartement(count: immobilierSummary[keys[index]]['count']),
                            ),
                          );
                        },
                        child: CategoryCard(
                          name: "$categoryName", // You can remove the count if not needed for the design
                          icon: icon,
                        ),
                      );
                    },
                  ),
                ),

            // Properties Section
            Row(
              children:  [
                Text(
                  getTranslated(context, "Residentiel")!,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Spacer(),
                Icon(IconBroken.Arrow___Right_Circle),
              ],
            ),
            const SizedBox(height: 15),

            // Display search results if available, otherwise show default property list
            isSearch
                ? filteredProperties.isNotEmpty
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: filteredProperties.length, // Use search results count
                        itemBuilder: (context, index) {
                          final immobilier = filteredProperties[index]; // Use search result data

                          // Safe image URL extraction
                          String imageUrl = 'https://via.placeholder.com/150';
                          if (immobilier['images'] != null && immobilier['images'].isNotEmpty) {
                            imageUrl = immobilier['images'][0]['image'];
                          }

                          // Properly handling price and rating conversion
                          String price = immobilier['loyer_mensuel'] != null
                              ? '${immobilier['loyer_mensuel'].toStringAsFixed(2)} /${getTranslated(context, "Mensuel")}'
                              : immobilier['montant'] != null
                                  ? immobilier['montant'].toStringAsFixed(2)
                                  : '0.0';
                          double rating = immobilier['ratings'] != null
                              ? double.tryParse(immobilier['ratings']) ?? 0.0
                              : 0.0;

                          return PropertyCard(
                            imageUrl: imageUrl,
                            title: immobilier['description'] ?? 'Description non disponible',
                            type_operation: immobilier['type_operation'] ?? '',
                            price: price,
                            address: immobilier['adresse'] ?? 'Adresse non disponible',
                            rating: rating,
                            available: immobilier['available'] ?? false,
                          );
                        },
                      )
                    : Center(child: Text(getTranslated(context, "Aucune propriété trouvée")!)) // Message for empty search results
                : isLoading
                    ? Immobilierkeleton() // Show skeleton loader when loading default list
                    :SingleChildScrollView(
                      scrollDirection: Axis.horizontal,  // Définit le défilement horizontal
                      child: Row(
                        children: immobilierList.map((immobilier) {
                          // Extraction sécurisée de l'URL de l'image
                          String imageUrl = 'https://via.placeholder.com/150';
                          if (immobilier['images'] != null && immobilier['images'].isNotEmpty) {
                            imageUrl = immobilier['images'][0]['image'];
                          }

                          // Conversion correcte du prix et de la note
                          String price = immobilier['loyer_mensuel'] != null
                              ? '${immobilier['loyer_mensuel'].toStringAsFixed(2)} /${getTranslated(context, "Mensuel")}'
                              : immobilier['montant'] != null
                                  ? immobilier['montant'].toStringAsFixed(2)
                                  : '0.0';
                          double rating = immobilier['ratings'] != null
                              ? double.tryParse(immobilier['ratings']) ?? 0.0
                              : 0.0;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImmobDetails(id: immobilier['id']),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0),  // Espace entre les éléments
                              width: 250,  // Largeur de chaque élément
                              child: PropertyCard(
                                imageUrl: imageUrl,
                                title: immobilier['description'] ?? 'Description non disponible',
                                type_operation: immobilier['type_operation'] ?? '',
                                price: price,
                                address: immobilier['adresse'] ?? 'Adresse non disponible',
                                rating: rating,
                                available: immobilier['available'] ?? false,
                              ),
                            ),
                          );
                        }).toList(),  // Transforme la liste en widgets PropertyCard
                      ),
                    ),

            Row(
              children: [
                Text(
                  getTranslated(context, "Propriétés à louer")!,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Spacer(),
                Icon(IconBroken.Arrow___Right_Circle),
              ],
            ),
            const SizedBox(height: 15),
                    isLoading
                    ? Immobilierkeleton() // Show skeleton loader when loading default list
                    :SingleChildScrollView(
                      scrollDirection: Axis.horizontal,  // Définit le défilement horizontal
                      child: Row(
                        children: proximiteList.map((immobilier) {
                          // Extraction sécurisée de l'URL de l'image
                          String imageUrl = 'https://via.placeholder.com/150';
                          if (immobilier['images'] != null && immobilier['images'].isNotEmpty) {
                            imageUrl = immobilier['images'][0]['image'];
                          }

                          // Conversion correcte du prix et de la note
                          String price = immobilier['loyer_mensuel'] != null
                              ? '${immobilier['loyer_mensuel'].toStringAsFixed(2)} /${getTranslated(context, "Mensuel")}'
                              : immobilier['montant'] != null
                                  ? immobilier['montant'].toStringAsFixed(2)
                                  : '0.0';
                          double rating = immobilier['ratings'] != null
                              ? double.tryParse(immobilier['ratings']) ?? 0.0
                              : 0.0;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImmobDetails(id: immobilier['id']),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0),  // Espace entre les éléments
                              width: 250,  // Largeur de chaque élément
                              child: PropertyCard(
                                imageUrl: 'https://akarina-9865f1a90dee.herokuapp.com'+imageUrl,
                                title: immobilier['description'] ?? 'Description non disponible',
                                type_operation: immobilier['type_operation'] ?? '',
                                price: price,
                                address: immobilier['adresse'] ?? 'Adresse non disponible',
                                rating: rating,
                                available: immobilier['available'] ?? false,
                              ),
                            ),
                          );
                        }).toList(),  // Transforme la liste en widgets PropertyCard
                      ),
                    )
                      ],
        ),
      ),
    ),
  );
}

  // Function to map category name to icons
  IconData _getIconForCategory(String categoryName) {
    switch (categoryName) {
      case "Appartement":
        return Icons.apartment;
      case "Duplex":
        return Icons.home_work;
      case "Commercial":
        return Icons.business;
      case "Terrain":
        return Icons.landscape;
      case "Residentiel":
        return Icons.house;
      default:
        return Icons.home;
    }
  }
}

// Widget to display category card
class CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;

  const CategoryCard({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Spacing between cards
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content
        children: [
          // Card Container for Icon
          Container(
            width: 90,  // Adjust width to match the card size in the design
            height: 90, // Adjust height to match the card size in the design
            decoration: BoxDecoration(
              color: Colors.white, // Background color for the card
              borderRadius: BorderRadius.circular(12), // Rounded corners
              border: Border.all(color: Colors.grey.shade300, width: 1), // Light border
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40, // Adjust icon size to match design
                color: Colors.black, // Icon color
              ),
            ),
          ),
          const SizedBox(height: 8), // Space between icon and text
          // Category Name
          Text(
            name,
            style: TextStyle(
              fontSize: 16, // Adjust font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center, // Center the text
          ),
        ],
      ),
    );
  }
}


// PropertyCard widget to display each property
class PropertyCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String address;
  final double rating;
  final bool available;
  final String type_operation;

  const PropertyCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.address,
    required this.rating,
    required this.available,
    required this.type_operation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                          
                          borderRadius: BorderRadius.circular(getProportionateScreenWidth(5)),
                          color: pcolor,
                        ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: const Text(
                            '3 days ago',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                          
                          borderRadius: BorderRadius.circular(getProportionateScreenWidth(5)),
                          color: type_operation == 'vendre' ? Colors.green : Colors.red,
                        ),
                          child: Text(
                            type_operation,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$price ${getTranslated(context, "MRU")}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              address,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 20,
                    );
                  }),
                ),
                Icon(
                  available ? Icons.check_circle : Icons.cancel,
                  color: available ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
