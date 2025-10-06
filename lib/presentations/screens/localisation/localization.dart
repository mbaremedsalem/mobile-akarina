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
  bool hasInternetConnection = true;
  Future<List<dynamic>> futureImmobiliers = Future.value([]);

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
      futureImmobiliers = fetchImmobiliers();
    });
  }

  Future<List<dynamic>> fetchImmobiliers() async {
    var url = Uri.parse("${baseUrl}akareena/imobiers/");
    try {
      var response = await http.get(url).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? []; // Retourne la liste des immobiliers
      } else {
        throw Exception('Failed to load immobiliers: ${response.body}');
      }
    } catch (e) {

      return [];
    }
  }

  void _addMarkers(List<dynamic> immobiliers) {
    _markers.clear(); // Nettoyer les anciens marqueurs
    
    for (var immobilier in immobiliers) {
      // CORRECTION ICI : Utiliser double.tryParse() au lieu de .toDouble()
      final double? latitude = _parseCoordinate(immobilier['x']);
      final double? longitude = _parseCoordinate(immobilier['y']);
      
      // Si la latitude ou longitude est nulle, ignorer ce marqueur
      if (latitude == null || longitude == null) {
         continue;
      }

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

  // NOUVELLE MÉTHODE : Parser les coordonnées de manière sécurisée
  double? _parseCoordinate(dynamic coordinate) {
    if (coordinate == null) return null;
    
    try {
      if (coordinate is double) {
        return coordinate;
      } else if (coordinate is int) {
        return coordinate.toDouble();
      } else if (coordinate is String) {
        // Nettoyer la chaîne si nécessaire (virgules, espaces, etc.)
        String cleaned = coordinate.toString().replaceAll(',', '.').trim();
        return double.tryParse(cleaned);
      }
    } catch (e) {
    }
    
    return null;
  }

  String _getPriceInfo(dynamic immobilier) {
    try {
      // Essayer différents chemins pour le prix
      if (immobilier['operation']?['type'] == 'vendre') {
        final montant = immobilier['residentiel']?['montant'] ?? 
                       immobilier['montant'] ?? 
                       immobilier['operation']?['montant'];
        
        if (montant != null) {
          return '${getTranslated(context, "À vendre")!}: $montant MRU';
        }
      } else if (immobilier['operation']?['type'] == 'alouer') {
        final loyer = immobilier['residentiel']?['loyer_mensuel'] ?? 
                     immobilier['loyer_mensuel'] ?? 
                     immobilier['operation']?['loyer_mensuel'];
        
        if (loyer != null) {
          return '${getTranslated(context, "À louer")!}: $loyer MRU/mois';
        }
      }
    } catch (e) {

    }
    
    return getTranslated(context, "Prix non disponible")!;
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: Text(getTranslated(context, "Réessayer")!),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final immobiliers = snapshot.data!;
            
            // Ajouter les marqueurs
            _addMarkers(immobiliers);

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(18.0735, -15.9582), // Position centrée sur Nouakchott
                    zoom: 12,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
 },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                
                // Légende des couleurs
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          Colors.green,
                          getTranslated(context, "Disponible")!,
                        ),
                        SizedBox(height: 8),
                        _buildLegendItem(
                          Colors.red,
                          getTranslated(context, "Non disponible")!,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bouton de recentrage
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton(
                    heroTag: 'recenter',
                    onPressed: () {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(18.0735, -15.9582), 12),
                      );
                    },
                    backgroundColor: pcolor,
                    child: Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  getTranslated(context, "Aucun immobilier trouvé")!,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}