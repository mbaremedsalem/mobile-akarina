import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Appartement extends StatefulWidget {
    final int count;

  const Appartement({Key? key, required this.count}) : super(key: key);
  @override
  _AppartementState createState() => _AppartementState();
}

class _AppartementState extends State<Appartement> {
  List<dynamic> apartments = [];
  bool isLoading = true;
  List<dynamic> immobilierList = [];

  // Variables pour les filtres
  String? selectedCity;
  String? selectedQuarter;
  bool isFurnished = false;
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  Future<void> _loadApartments() async {
    NetworkService networkService = NetworkService();

    // Appeler la méthode fetchCategories en passant le token
    final fetchedresidence = await networkService.fetchApartments();

    if (fetchedresidence != null) {
      setState(() {
        apartments = fetchedresidence;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
        icon: Icon(IconBroken.Arrow___Left_2), // Utiliser FontAwesome pour l'icône
        onPressed: () {
          Navigator.pop(context);
        },
      ),
        title: Text('Recherche Appartements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Boutons en haut de la page
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
                    icon: Icon(Icons.filter_list),
                    label: Text('Filtres'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pcolor,
                      side: BorderSide(color: pcolor), // Bordure or
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8),),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Logique pour effacer les filtres
                      setState(() {
                        selectedCity = null;
                        selectedQuarter = null;
                        minPriceController.clear();
                        maxPriceController.clear();
                        isFurnished = false;
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Effacer les filtres'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red), // Bordure rouge
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8),),
                  // Nombre de résultats (exemple ici, à remplacer par vos données)
                  Text('${widget.count.toString()} résultats', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
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

  // Méthode pour afficher la boîte de dialogue des filtres
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filtres similaires à la première image fournie
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  hint: Text('Ville'),
                  items: <String>['Nouakchott', 'Nouadhibou', 'Atar']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: selectedQuarter,
                  hint: Text('Quartier'),
                  items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha']
                      .map((String value) {
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
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 16.0),
                // Champs de prix
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        decoration: InputDecoration(
                          hintText: 'De',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        decoration: InputDecoration(
                          hintText: 'À',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                // Boutons "Louer" et "Acheter"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Action pour Louer
                      },
                      child: Text('Louer'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Action pour Acheter
                      },
                      child: Text('Acheter'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                // Meublé Switch
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
                    Text('Meublé ?'),
                  ],
                ),
                SizedBox(height: 16.0),
                // Bouton "Filtrer"
                Defaultbutton(
                  onTap: () {
                    // Soumission du formulaire
                  },
                  color: pcolor,
                  textcolor: kWhiteColor,
                  text: 'Filtrer',
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
}

class ApartmentCard extends StatelessWidget {
  final dynamic apartment;

  const ApartmentCard({Key? key, required this.apartment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                           
                           (apartment['images'] != null && apartment['images'].isNotEmpty) ?
                            apartment['images'][0]['image']:'https://via.placeholder.com/150',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: pcolor,
                  child: Text(
                    '7 days on Akareena',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Positioned(
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
                                apartment['loyer_mensuel'] != null
                              ? '${apartment['loyer_mensuel'].toStringAsFixed(2)} /Mensuel'
                              : apartment['montant'] != null
                                  ? apartment['montant'].toStringAsFixed(2)
                                  : '0.0',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconInfo(icon: Icons.bed, value: apartment['nombre_de_chambres'].toString()),
                    IconInfo(icon: Icons.garage, value: apartment['nombre_de_garages'].toString()),
                    IconInfo(icon: Icons.kitchen, value: apartment['nombre_de_salles_de_bain'].toString()),
                    IconInfo(icon: Icons.square_foot, value: apartment['surface']),
                    IconInfo(icon: Icons.people, value: apartment['etage'].toString()),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey),
                    Expanded(
                      child: Text(
                        apartment['adresse'],
                        style: TextStyle(fontSize: 14, color: Colors.grey),
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
    );
  }
}

class IconInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const IconInfo({Key? key, required this.icon, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 5),
        Text(value, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}


// import 'package:flutter/material.dart';

// class Appartement extends StatefulWidget {
//   @override
//   _AppartementState createState() => _AppartementState();
// }

// class _AppartementState extends State<Appartement> {
  // // Variables pour les filtres
  // String? selectedCity;
  // String? selectedQuarter;
  // bool isFurnished = false;
  // TextEditingController minPriceController = TextEditingController();
  // TextEditingController maxPriceController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
        // title: Text('Recherche Appartements'),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Section des boutons "Filtrer" et "Effacer les filtres"
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 OutlinedButton.icon(
//                   onPressed: () {
//                     _showFilterDialog(context);
//                   },
//                   icon: Icon(Icons.filter_list),
//                   label: Text('Filtres'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Color(0xFFB38E5D), side: BorderSide(color: Color(0xFFB38E5D)), // Bordure or
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30.0),
//                     ),
//                   ),
//                 ),
//                 OutlinedButton.icon(
//                   onPressed: () {
//                     // Logique pour effacer les filtres
//                     setState(() {
//                       selectedCity = null;
//                       selectedQuarter = null;
//                       minPriceController.clear();
//                       maxPriceController.clear();
//                       isFurnished = false;
//                     });
//                   },
//                   icon: Icon(Icons.clear),
//                   label: Text('Effacer les filtres'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Colors.red, side: BorderSide(color: Colors.red), // Bordure rouge
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30.0),
//                     ),
//                   ),
//                 ),
//                 // Nombre de résultats (exemple ici, à remplacer par vos données)
//                 Text('28 résultats', style: TextStyle(fontSize: 16)),
//               ],
//             ),
//             // Ajoutez d'autres éléments de contenu ici, si nécessaire.
          
          
//           ],
//         ),
//       ),
//     );
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
//                 // Filtres similaires à la première image fournie
//                 DropdownButtonFormField<String>(
//                   value: selectedCity,
//                   hint: Text('Ville'),
//                   items: <String>['Nouakchott', 'Nouadhibou', 'Atar']
//                       .map((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: Text(value),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedCity = value;
//                     });
//                   },
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 SizedBox(height: 16.0),
//                 DropdownButtonFormField<String>(
//                   value: selectedQuarter,
//                   hint: Text('Quartier'),
//                   items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha']
//                       .map((String value) {
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
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 SizedBox(height: 16.0),
//                 // Champs de prix
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: minPriceController,
//                         decoration: InputDecoration(
//                           hintText: 'De',
//                           filled: true,
//                           fillColor: Colors.grey[200],
//                           border: OutlineInputBorder(),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                     SizedBox(width: 8.0),
//                     Expanded(
//                       child: TextField(
//                         controller: maxPriceController,
//                         decoration: InputDecoration(
//                           hintText: 'À',
//                           filled: true,
//                           fillColor: Colors.grey[200],
//                           border: OutlineInputBorder(),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16.0),
//                 // Boutons "Louer" et "Acheter"
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () {
//                         // Action pour Louer
//                       },
//                       child: Text('Louer'),
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.black, backgroundColor: Colors.white,
//                         side: BorderSide(color: Colors.grey),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20.0),
//                         ),
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Action pour Acheter
//                       },
//                       child: Text('Acheter'),
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.black, backgroundColor: Colors.white,
//                         side: BorderSide(color: Colors.grey),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20.0),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16.0),
//                 // Meublé Switch
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
//                     Text('Meublé ?'),
//                   ],
//                 ),
//                 SizedBox(height: 16.0),
//                 // Bouton "Filtrer"
//                 ElevatedButton(
//                   onPressed: () {
//                     // Appliquer les filtres
//                     Navigator.pop(context); // Fermer le dialogue
//                   },
//                   child: Text('Filtrer'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFFB38E5D), // Couleur similaire au design
//                     minimumSize: Size(double.infinity, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }


// }

