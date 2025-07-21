import 'dart:convert';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:akarina/data/services/connectivity_service.dart';

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  // late Future<List<dynamic>> futureImmobiliers;
  bool hasInternetConnection = true;



  Future<List<dynamic>> futureImmobiliers = Future.value([]); // Initialisation ici

  // URL de l'API et timeout
  final String baseUrl = 'https://akarina.online/';
  final int timeout = 10;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });
    
    if (!hasConnection) return;
    
    setState(() {
      futureImmobiliers = fetchImmobiliers(); // Mise à jour avec setState
    });
  }

  Future<List<dynamic>> fetchImmobiliers() async {
    var url = Uri.parse("${baseUrl}akareena/imobiers/");
    try {
      var response = await http.get(url).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results']; // Retourne la liste des immobiliers
      } else {
        throw Exception('Failed to load immobiliers: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des immobiliers: $e');
      return [];
    }
  }

  void _addMarkers(List<dynamic> immobiliers) {
    _markers.clear(); // Nettoyer les anciens marqueurs
    
    for (var immobilier in immobiliers) {
      final double? latitude = immobilier['x']?.toDouble();
      final double? longitude = immobilier['y']?.toDouble();
      
      // Si la latitude ou longitude est nulle, ignorer ce marqueur
      if (latitude == null || longitude == null) continue;

      final bool isAvailable = immobilier['available'] ?? false;
      final String address = immobilier['adresse'] ?? 'Adresse inconnue';
      final String priceInfo = _getPriceInfo(immobilier);

      _markers.add(
        Marker(
          markerId: MarkerId(immobilier['id'].toString()),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: address,
            snippet: priceInfo,
          ),
          icon: isAvailable 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  String _getPriceInfo(dynamic immobilier) {
    if (immobilier['operation']?['type'] == 'vendre' || 
        immobilier['operation']?['type'] == 'alouer') {
      final montant = immobilier['residentiel']?['montant'] ?? immobilier['montant'];
      final loyer = immobilier['residentiel']?['loyer_mensuel'];
      
      if (montant != null) {
        return 'À vendre: ${montant.toStringAsFixed(2)} MRU';
      } else if (loyer != null) {
        return 'À louer: ${loyer.toStringAsFixed(2)} MRU/mois';
      }
    }
    return 'Prix non disponible';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          setState(() {
            hasInternetConnection = hasConnection;
          });
          
          if (hasConnection) _initializeData();
        },
      );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, "Localisation du maison")!,
          style: TextStyle(color: kBlackColor),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureImmobiliers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _addMarkers(snapshot.data!);

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(18.0735, -15.9582), // Position centrée sur Nouakchott
                    zoom: 12,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) => _mapController = controller,
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'available',
                        onPressed: () {},
                        backgroundColor: Colors.green,
                        child: Icon(Icons.circle, size: 20),
                      ),
                      SizedBox(height: 10),
                      Text(getTranslated(context, "Disponible")!),
                      SizedBox(height: 20),
                      FloatingActionButton(
                        heroTag: 'unavailable',
                        onPressed: () {},
                        backgroundColor: Colors.red,
                        child: Icon(Icons.circle, size: 20),
                      ),
                      SizedBox(height: 10),
                      Text(getTranslated(context, "Non disponible")!),
                    ],
                  ),
                ),
              ],
            );
          }
          return Center(child: Text('Aucun immobilier trouvé.'));
        },
      ),
    );
  }
}