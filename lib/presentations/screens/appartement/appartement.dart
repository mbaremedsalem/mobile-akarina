// import 'dart:convert';
// import 'package:akarina/data/data_providers/network_service.dart';
// import 'package:akarina/data/localization/language_constants.dart';
// import 'package:akarina/presentations/components/default_button.dart';
// import 'package:akarina/presentations/constants/constants.dart';
// import 'package:akarina/presentations/constants/icon_broken.dart';
// import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
// import 'package:akarina/size_config.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class Appartement extends StatefulWidget {
//   final String apiUrl; // URL de l'API
//   final int count; 

//   const Appartement({super.key, required this.apiUrl, required this.count});

//   @override
//   _AppartementState createState() => _AppartementState();
// }

// class _AppartementState extends State<Appartement> {
//   List<dynamic> apartments = [];
//   bool isLoading = true;
//   bool isLoadingCities = true;

//   // Variables pour les filtres
//   String? selectedVille;
//   String? selectedQuarter;
//   bool isFurnished = false;
//   TextEditingController minPriceController = TextEditingController();
//   TextEditingController maxPriceController = TextEditingController();

//   List<Map<String, dynamic>> availableCities = []; // Liste des villes disponibles

//   @override
//   void initState() {
//     super.initState();
//     _loadApartments(); // Charger les appartements sans filtres au démarrage
//     fetchCities(); // Charger la liste des villes
//   }
//   Future<void> _loadApartments() async {
//     setState(() {
//       isLoading = true; // Afficher l'indicateur de chargement
//     });

//     try {
//       // Appeler l'API avec l'URL passée en paramètre
//       final response = await http.get(Uri.parse(widget.apiUrl));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(utf8.decode(response.bodyBytes));
//         setState(() {
//           apartments = data; // Mettre à jour la liste des appartements
//           isLoading = false; // Masquer l'indicateur de chargement
//         });
//       } else {
//         throw Exception('Erreur lors du chargement des données : ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false; // Masquer l'indicateur de chargement en cas d'erreur
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur : $e')),
//       );
//     }
//   }

//   Future<void> fetchCities() async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://akarina.online/akareena/villes/'),
//         headers: {
//           'Content-Type': 'application/json; charset=utf-8',
//         },
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           availableCities = List<Map<String, dynamic>>.from(
//             jsonDecode(utf8.decode(response.bodyBytes)),
//           );
//           isLoadingCities = false;
//         });
//       } else {
//         throw Exception('Erreur lors du chargement des villes : ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() {
//         isLoadingCities = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur : $e')),
//       );
//     }
//   }

//   // Méthode pour obtenir le nom de la ville dans la langue actuelle
//   String getCityName(Map<String, dynamic> city) {
//     final currentLang = Localizations.localeOf(context).languageCode;
//     return currentLang == 'ar' ? city['nom_ar'] : city['nom'];
//   }

//   // Méthode pour afficher la boîte de dialogue des filtres
//   void _showFilterDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Filtre : Ville
//                 isLoadingCities
//                     ? const CircularProgressIndicator()
//                     : DropdownButtonFormField<String>(
//                         value: selectedVille,
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             selectedVille = newValue?.toString();
//                           });
//                         },
//                         items: availableCities.map<DropdownMenuItem<String>>((ville) {
//                           return DropdownMenuItem<String>(
//                             value: ville['nom'],
//                             child: Text(getCityName(ville)),
//                           );
//                         }).toList(),
//                         decoration: InputDecoration(
//                           labelText: getTranslated(context, 'Ville'),
//                           border: const OutlineInputBorder(),
//                         ),
//                       ),
//                 const SizedBox(height: 16.0),
//                 // Filtre : Quartier
//                 DropdownButtonFormField<String>(
//                   value: selectedQuarter,
//                   hint: const Text('Quartier'),
//                   items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha'].map((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: Text(value),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedQuarter = value;
//                     });
//                   },
//                   decoration: InputDecoration(
//                     border: const OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 const SizedBox(height: 16.0),
//                 // Filtre : Prix
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: minPriceController,
//                         decoration: InputDecoration(
//                           hintText: getTranslated(context,"De"),
//                           filled: true,
//                           fillColor: Colors.grey[200],
//                           border: const OutlineInputBorder(),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                     const SizedBox(width: 8.0),
//                     Expanded(
//                       child: TextField(
//                         controller: maxPriceController,
//                         decoration: InputDecoration(
//                           hintText: getTranslated(context,"À"),
//                           filled: true,
//                           fillColor: Colors.grey[200],
//                           border: const OutlineInputBorder(),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16.0),
//                 // Filtre : Meublé
//                 Row(
//                   children: [
//                     Switch(
//                       value: isFurnished,
//                       onChanged: (value) {
//                         setState(() {
//                           isFurnished = value;
//                         });
//                       },
//                     ),
//                      Text(getTranslated(context, "Meubler")!),
//                   ],
//                 ),
//                 const SizedBox(height: 16.0),
//                 // Bouton "Filtrer"
//                 Defaultbutton(
//                   onTap: () {
//                     _loadApartments(
//                       // ville: selectedVille,
//                       // adresse: selectedQuarter,
//                       // meubler: isFurnished,
//                       // operation: 'vendre', // ou 'louer' selon le besoin
//                       // prixMin: double.tryParse(minPriceController.text),
//                       // prixMax: double.tryParse(maxPriceController.text),
//                     );
//                     Navigator.pop(context); // Fermer la boîte de dialogue
//                   },
//                   color: pcolor,
//                   textcolor: kWhiteColor,
//                   text: getTranslated(context, "Filtres")!,
//                   borderRadius: getProportionateScreenWidth(5),
//                   width: getProportionateScreenWidth(500),
//                   height: getProportionateScreenHeight(45),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(
//             Localizations.localeOf(context).languageCode == 'ar' 
//               ? IconBroken.Arrow___Right_2 // Icône pour l'arabe (flèche à droite)
//               : IconBroken.Arrow___Left_2, // Icône pour le français (flèche à gauche)
//               color: kBlackColor,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       title:  Text(getTranslated(context, "Recherche Maison")!,style: TextStyle(color: kBlackColor),),
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//     ),
//     body: Column(
//       children: [
//         // Boutons en haut de la page
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 OutlinedButton.icon(
//                   onPressed: () {
//                     _showFilterDialog(context);
//                   },
//                   icon: const Icon(Icons.filter_list),
//                   label: Text(getTranslated(context, "Filtres")!),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: pcolor,
//                     side: const BorderSide(color: pcolor),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30.0),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: getProportionateScreenWidth(8)),
//                 OutlinedButton.icon(
//                   onPressed: () {
//                     // Réinitialiser les filtres
//                     setState(() {
//                       selectedVille = null;
//                       selectedQuarter = null;
//                       minPriceController.clear();
//                       maxPriceController.clear();
//                       isFurnished = false;
//                     });
//                     _loadApartments(); // Recharger sans filtres
//                   },
//                   icon: const Icon(Icons.clear),
//                   label:  Text(getTranslated(context,"Effacer les filtres")!),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Colors.red,
//                     side: const BorderSide(color: Colors.red),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30.0),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: getProportionateScreenWidth(8)),
//                 Text('${apartments.length} ${getTranslated(context,"résultats")}', style: const TextStyle(fontSize: 16)),
//               ],
//             ),
//           ),
//         ),
//         Expanded(
//           child: isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : ListView.builder(
//                   itemCount: apartments.length,
//                   itemBuilder: (context, index) {
//                     final apartment = apartments[index];
//                     return ApartmentCard(apartment: apartment);
//                   },
//                 ),
//         ),
//       ],
//     ),
//   );
// }

// }

// // Widget pour afficher une carte d'appartement
// class ApartmentCard extends StatelessWidget {
//   final dynamic apartment;

//   const ApartmentCard({super.key, required this.apartment});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: (){
//                   Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ImmobDetails(id: apartment['id']),
//             ),
//           );
//       },
//       child: Card(
//         margin: const EdgeInsets.all(10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
//                   child: Image.network(
//                     (apartment['images'] != null && apartment['images'].isNotEmpty)
//                         ? apartment['images'][0]['image']
//                         : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s',
//                     height: 200,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 Positioned(
//                   top: 10,
//                   left: 10,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     color:apartment['available']? pcolor:kredcolor,
//                     child:  Text(
//                       apartment['available']?getTranslated(context,"Available")!:getTranslated(context,"Unavailable")!,
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//                 const Positioned(
//                   top: 10,
//                   right: 10,
//                   child: Icon(
//                     Icons.favorite_border,
//                     color: Colors.red,
//                   ),
//                 ),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.all(10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     apartment['montant'] != null
//                         ? '${apartment['montant'].toStringAsFixed(2)} ${getTranslated(context, "MRU") ?? "MRU"}'
//                         : '${apartment['loyer_mensuel']?.toStringAsFixed(2) ?? "N/A"} ${getTranslated(context, "MRU") ?? "MRU"} / ${getTranslated(context, apartment['periode'] ?? "Inconnu") ?? apartment['periode'] ?? "Inconnu"}',
//                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 5),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconInfo(icon: Icons.bed, value: apartment['nombre_de_chambres']?.toString() ?? "N/A"),
//                       IconInfo(icon: Icons.garage, value: apartment['nombre_de_garages']?.toString() ?? "N/A"),
//                       IconInfo(icon: Icons.bathtub_outlined, value: apartment['nombre_de_salles_de_bain']?.toString() ?? "N/A"),
//                       IconInfo(icon: Icons.square_foot, value: apartment['surface']?.toString() ?? "N/A"),
//                       IconInfo(icon: Icons.account_balance_outlined, value: apartment['etage']?.toString() ?? "N/A"),
//                     ],
//                   ),
//                   const SizedBox(height: 5),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on, color: Colors.grey),
//                       Expanded(
//                         child: Text(
//                           apartment['adresse'] ?? "Adresse inconnue",
//                           style: const TextStyle(fontSize: 14, color: Colors.grey),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Widget pour afficher une icône avec une valeur
// class IconInfo extends StatelessWidget {
//   final IconData icon;
//   final String value;

//   const IconInfo({super.key, required this.icon, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.grey),
//         const SizedBox(width: 5),
//         Text(value, style: const TextStyle(fontSize: 14)),
//       ],
//     );
//   }
// }
import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    _loadApartments();
    fetchCities();
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
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection du type d'opération (louer/vendre)
                DropdownButtonFormField<String>(
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
                  decoration: InputDecoration(
                    labelText: getTranslated(context, 'Type'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Filtre : Ville
                isLoadingCities
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
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
                        decoration: InputDecoration(
                          labelText: getTranslated(context, 'Ville'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                const SizedBox(height: 16.0),
                
                // Filtre : Quartier
                DropdownButtonFormField<String>(
                  value: selectedQuarter,
                  hint: Text(getTranslated(context, 'Quartier')!),
                  items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha', 'Nouakchott Ouest', 'Nouakchott Nord']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedQuarter = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Filtre : Prix
                Text(getTranslated(context, 'Prix')!, style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        decoration: InputDecoration(
                          hintText: getTranslated(context, "De"),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        decoration: InputDecoration(
                          hintText: getTranslated(context, "À"),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                
                // Filtre : Meublé
                Row(
                  children: [
                    Switch(
                      value: isFurnished,
                      onChanged: (value) {
                        setState(() {
                          isFurnished = value;
                        });
                      },
                    ),
                    Text(getTranslated(context, "Meubler")!),
                  ],
                ),
                const SizedBox(height: 16.0),
                
                // Bouton "Filtrer"
                Defaultbutton(
                  onTap: () {
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
                  color: pcolor,
                  textcolor: kWhiteColor,
                  text: getTranslated(context, "Filtres")!,
                  borderRadius: getProportionateScreenWidth(5),
                  width: getProportionateScreenWidth(500),
                  height: getProportionateScreenHeight(45),
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
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                    icon: const Icon(Icons.filter_list),
                    label: Text(getTranslated(context, "Filtres")!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pcolor,
                      side: const BorderSide(color: pcolor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
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
                    icon: const Icon(Icons.clear),
                    label: Text(getTranslated(context, "Effacer les filtres")!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Text('${apartments.length} ${getTranslated(context, "résultats")}', 
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : apartments.isEmpty
                    ? Center(
                        child: Text(
                          getTranslated(context, "Aucun résultat trouvé")!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: apartments.length,
                        itemBuilder: (context, index) {
                          final apartment = apartments[index];
                          return ApartmentCard(apartment: apartment);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ApartmentCard extends StatelessWidget {
  final dynamic apartment;

  const ApartmentCard({super.key, required this.apartment});

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    (apartment['images'] != null && apartment['images'].isNotEmpty)
                        ? apartment['images'][0]['image']
                        : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: apartment['available'] ? pcolor : kredcolor,
                    child: Text(
                      apartment['available'] 
                          ? getTranslated(context, "Available")!
                          : getTranslated(context, "Unavailable")!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apartment['montant'] != null
                        ? '${apartment['montant'].toStringAsFixed(2)} ${getTranslated(context, "MRU") ?? "MRU"}'
                        : '${apartment['loyer_mensuel']?.toStringAsFixed(2) ?? "N/A"} ${getTranslated(context, "MRU") ?? "MRU"} / ${getTranslated(context, apartment['periode'] ?? "Inconnu") ?? apartment['periode'] ?? "Inconnu"}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconInfo(icon: Icons.bed, value: apartment['nombre_de_chambres']?.toString() ?? "N/A"),
                      IconInfo(icon: Icons.garage, value: apartment['nombre_de_garages']?.toString() ?? "N/A"),
                      IconInfo(icon: Icons.bathtub_outlined, value: apartment['nombre_de_salles_de_bain']?.toString() ?? "N/A"),
                      IconInfo(icon: Icons.square_foot, value: apartment['surface']?.toString() ?? "N/A"),
                      IconInfo(icon: Icons.account_balance_outlined, value: apartment['etage']?.toString() ?? "N/A"),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      Expanded(
                        child: Text(
                          apartment['adresse'] ?? "Adresse inconnue",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}