import 'dart:convert';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  late Future<List<dynamic>> futureResidences;

  // URL de l'API et timeout
  final String baseUrl = 'http://192.168.0.207:8000/';
  final int timeout = 10;

  @override
  void initState() {
    super.initState();
    futureResidences = fetchResidence(); // Récupérer les résidences lorsque la page se charge
  }

  // Fonction pour récupérer les résidences via l'API
  Future<List<dynamic>> fetchResidence() async {
    var url = Uri.parse("${baseUrl}akareena/residentiels/");
    try {
      var response = await http.get(url).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        print(response.body);
        return jsonDecode(response.body); // Retourne la liste des résidences
        
      } else {
        throw Exception('Failed to load residences: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des résidences: $e');
      return [];
    }
  }

  // Fonction pour ajouter des marqueurs sur la carte
  void _addMarkers(List<dynamic> residences) {
    for (var residence in residences) {
      final double? latitude = double.tryParse(residence?['x'] ?? '48.8566');
      final double? longitude = double.tryParse(residence?['y'] ?? '2.3522');

      // Si la latitude ou longitude est nulle, ignorer ce marqueur
      if (latitude != null && longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(residence['id'].toString()), // Assurez-vous que l'ID est une chaîne de caractères
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(
              title: residence['adresse'], // Le nom de la résidence
              snippet: _getPriceSnippet(residence), // Gérer les différents prix
            ),
          ),
        );
      }
    }
  }

  // Fonction pour gérer l'affichage du prix ou du loyer
  String _getPriceSnippet(dynamic residence) {
    double? loyerMensuel = residence['loyer_mensuel'] != null
        ? double.tryParse(residence['loyer_mensuel'].toString())
        : null;
    double? montant = residence['montant'] != null
        ? double.tryParse(residence['montant'].toString())
        : null;

    if (loyerMensuel != null) {
      return '${loyerMensuel.toStringAsFixed(2)} / Mensuel';
    } else if (montant != null) {
      return montant.toStringAsFixed(2);
    } else {
      return 'Prix non disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar' 
              ? IconBroken.Arrow___Right_2 // Icône pour l'arabe (flèche à droite)
              : IconBroken.Arrow___Left_2, // Icône pour le français (flèche à gauche)
              color: kBlackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(getTranslated(context, "Localisation du maison")!,style: TextStyle(color: kBlackColor,),),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureResidences,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _addMarkers(snapshot.data!); // Ajouter des marqueurs une fois les résidences récupérées

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(48.858844, 2.294351), // Position initiale de la carte
                zoom: 10,
              ),
              markers: _markers, // Les marqueurs affichés sur la carte
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            );
          }
          return Center(child: Text('Aucune résidence trouvée.'));
        },
      ),
    );
  }
}
