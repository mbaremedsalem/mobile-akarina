import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
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
  bool isLoadingCities = true;

  // Variables pour les filtres
  String? selectedVille;
  String? selectedQuarter;
  bool isFurnished = false;
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();

  List<Map<String, dynamic>> availableCities = []; // Liste des villes disponibles

  @override
  void initState() {
    super.initState();
    _loadApartments(); // Charger les appartements sans filtres au démarrage
    fetchCities(); // Charger la liste des villes
  }

  // Méthode pour charger les appartements avec filtres
Future<void> _loadApartments({
  String? ville,
  String? adresse,
  bool? meubler,
  String? operation,
  double? prixMin,
  double? prixMax,
}) async {
  setState(() {
    isLoading = true; // Afficher l'indicateur de chargement
  });
// 46981937Bb@
  try {
    // Construire l'URL avec les paramètres de filtre
    final Uri uri = Uri.parse('https://akarina.online/akareena/filter-residentiel/').replace(
      queryParameters: {
        if (ville != null) 'ville': ville,
        if (adresse != null) 'adresse': adresse,
        if (meubler != null) 'meubler': meubler.toString(),
        if (operation != null) 'operation': operation,
        if (prixMin != null) 'prix_min': prixMin.toString(),
        if (prixMax != null) 'prix_max': prixMax.toString(),
      },
    );

    // Appeler l'API
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        apartments = data; // Mettre à jour la liste des appartements
        isLoading = false; // Masquer l'indicateur de chargement
      });
    } else {
      throw Exception('Erreur lors du chargement des données : ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      isLoading = false; // Masquer l'indicateur de chargement en cas d'erreur
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $e')),
    );
  }
}
  // Méthode pour charger la liste des villes
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

  // Méthode pour obtenir le nom de la ville dans la langue actuelle
  String getCityName(Map<String, dynamic> city) {
    final currentLang = Localizations.localeOf(context).languageCode;
    return currentLang == 'ar' ? city['nom_ar'] : city['nom'];
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
                // Filtre : Ville
                isLoadingCities
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: selectedVille,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedVille = newValue?.toString();
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
                  hint: const Text('Quartier'),
                  items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha'].map((String value) {
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        decoration: InputDecoration(
                          hintText: 'De',
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
                          hintText: 'À',
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
                    const Text('Meublé ?'),
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
                      operation: 'vendre', // ou 'louer' selon le besoin
                      prixMin: double.tryParse(minPriceController.text),
                      prixMax: double.tryParse(maxPriceController.text),
                    );
                    Navigator.pop(context); // Fermer la boîte de dialogue
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

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(IconBroken.Arrow___Left_2),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text('Recherche Appartements'),
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
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filtres'),
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
                    // Réinitialiser les filtres
                    setState(() {
                      selectedVille = null;
                      selectedQuarter = null;
                      minPriceController.clear();
                      maxPriceController.clear();
                      isFurnished = false;
                    });
                    _loadApartments(); // Recharger sans filtres
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer les filtres'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                SizedBox(width: getProportionateScreenWidth(8)),
                Text('${apartments.length} résultats', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
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

// Widget pour afficher une carte d'appartement
class ApartmentCard extends StatelessWidget {
  final dynamic apartment;

  const ApartmentCard({super.key, required this.apartment});

  @override
  Widget build(BuildContext context) {
    final residentiel = apartment['residentiel'];
    return Card(
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
                      : 'https://via.placeholder.com/150',
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
                  color: pcolor,
                  child: const Text(
                    '7 days on Akareena',
                    style: TextStyle(color: Colors.white),
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
                  residentiel['montant'] != null
                      ? '${residentiel['montant'].toStringAsFixed(2)}'
                      : '0.0',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconInfo(icon: Icons.bed, value: residentiel['nombre_de_chambres'].toString()),
                    IconInfo(icon: Icons.garage, value: residentiel['nombre_de_garages'].toString()),
                    IconInfo(icon: Icons.kitchen, value: residentiel['nombre_de_salles_de_bain'].toString()),
                    IconInfo(icon: Icons.square_foot, value: residentiel['surface']),
                    IconInfo(icon: Icons.people, value: residentiel['nombre_d_etages'].toString()),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    Expanded(
                      child: Text(
                        residentiel['adresse'],
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
    );
  }
}
// Widget pour afficher une icône avec une valeur
class IconInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const IconInfo({Key? key, required this.icon, required this.value}) : super(key: key);

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