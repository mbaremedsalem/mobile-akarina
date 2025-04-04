// import 'dart:convert';
// import 'package:akarina/presentations/components/spiner.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_styled_toast/flutter_styled_toast.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:http/http.dart' as http;
// import 'package:akarina/presentations/components/default_button.dart';
// import 'package:akarina/presentations/constants/constants.dart';
// import 'package:akarina/size_config.dart';
// import 'package:akarina/data/localization/language_constants.dart';
// import 'package:intl/intl.dart';

// class PostAnnonceScreen extends StatefulWidget {
//   const PostAnnonceScreen({super.key});

//   @override
//   _PostAnnonceScreenState createState() => _PostAnnonceScreenState();
// }

// class _PostAnnonceScreenState extends State<PostAnnonceScreen> {
//   String? selectedType;
//   String? selectedimmo;
//   String? selectedZone;
//   List<dynamic> villes = [];
//   int currentState = 0;
//   bool isLoaded = false;
//   String selectedCity = '';

//   TextEditingController descriptionController = TextEditingController();
//   TextEditingController prixController = TextEditingController();
//   TextEditingController surfaceController = TextEditingController();
//   TextEditingController addressController = TextEditingController();

//   final storage = const FlutterSecureStorage(); // Pour stocker les données de manière sécurisée
//   final String apiUrl = 'https://akarina.online/akareena/imobiers/new/';

//   List<Map<String, dynamic>> availableCities = []; // Stocke la liste des villes
//   String? selectedVille; // Ville sélectionnée (ID stocké sous forme de String)
//   bool isLoadingCities = true; // Pour afficher un indicateur de chargement

//   @override
//   void initState() {
//     super.initState();
//     fetchCities();
//   }


//   /// Récupération des villes depuis l'API
//   Future<void> fetchCities() async {
//     try {
//       final response = await http.get(
//         Uri.parse("https://akarina.online/akareena/villes/"),
//         headers: {
//           'Content-Type': 'application/json; charset=utf-8',
//         },
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           availableCities = List<Map<String, dynamic>>.from(
//             jsonDecode(utf8.decode(response.bodyBytes)), // Gère l'encodage UTF-8
//           );
//           isLoadingCities = false;
//         });
//       } else {
//         throw Exception("Erreur lors du chargement des villes : ${response.statusCode}");
//       }
//     } catch (e) {
//       setState(() {
//         isLoadingCities = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur : $e")),
//       );
//     }
//   }

//   /// Récupère la langue actuelle et affiche le nom en FR ou AR
//   String getCityName(Map<String, dynamic> city) {
//     String? currentLang = Localizations.localeOf(context).languageCode;
//     return currentLang == 'ar' ? city['nom_ar'] : city['nom'];
//   }


//   // Fonction pour soumettre l'annonce immobilière
// Future<void> submitAnnonce(BuildContext context) async {
//   setState(() {
//     isLoaded = true;
//   });

//   String? token = await storage.read(key: "access"); // Lire le token depuis le stockage sécurisé
//   final url = Uri.parse(apiUrl);

//   // Préparation des données à envoyer
//   Map<String, dynamic> body = {
//     "nom": selectedVille, // Assurez-vous que c'est un ID depuis la liste des villes
//     "type": selectedType,
//     "loyer_mensuel": int.parse(prixController.text),
//     "immobilier_type": selectedimmo,
//     "adresse": selectedZone,
//     "surface": surfaceController.text,
//     "description": descriptionController.text,
//     "etage": 3, // Valeur par défaut
//     "presence_de_balcon": true,
//   };

//   try {
//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token', // Utiliser le token dans l'en-tête Authorization
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode(body),
//     );

//     if (response.statusCode == 201) {
//       final jsonResponse = json.decode(response.body);
//       // Stocker l'ID de l'immobilier dans le stockage sécurisé
//       await storage.write(key: 'idimmo', value: jsonResponse['id'].toString());

//       // Afficher un toast de succès
//       showToast(
//         jsonResponse['message'],
//         context: context, // Ensure context is passed here
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 4),
//       );
//     } else {
//       final errorResponse = json.decode(response.body);
//       showToast(
//         errorResponse['error'] ?? 'Une erreur est survenue',
//         context: context, // Ensure context is passed here
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 4),
//       );
//     }
//   } catch (e) {
//     showToast(
//       'Erreur réseau. Veuillez réessayer.',
//       context: context, // Ensure context is passed here
//       backgroundColor: Colors.red,
//       duration: const Duration(seconds: 4),
//     );
//   } finally {
//     setState(() {
//       isLoaded = false;
//     });
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // En-tête pour basculer entre "Immobilier" et "Projet"
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: kgrey300),
//                 borderRadius: BorderRadius.circular(getProportionateScreenWidth(7)),
//                 color: kgrey100,
//               ),
//               padding: EdgeInsets.symmetric(
//                 horizontal: getProportionateScreenWidth(5),
//                 vertical: getProportionateScreenHeight(5),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         currentState = 0;
//                       });
//                     },
//                     child: _buildStateButton(isActive: currentState == 0, text:getTranslated(context, "Immobilier")!),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         currentState = 1;
//                       });
//                     },
//                     child: _buildStateButton(isActive: currentState == 1, text: getTranslated(context, "Projet")!),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10),
//             currentState == 0 ? buildImmobilierForm() : const ProjectSubmissionForm(),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget pour le bouton de bascule entre les formulaires
//   Widget _buildStateButton({required bool isActive, required String text}) {
//     return Container(
//       height: getProportionateScreenHeight(37),
//       width: getProportionateScreenWidth(155),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(getProportionateScreenWidth(5)),
//         color: isActive ? kWhiteColor : kgrey100,
//         boxShadow: [
//           BoxShadow(
//             color: isActive ? kgrey300 : kgrey100,
//             offset: const Offset(0.0, 0.0),
//             blurRadius: 10.0,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           text,
//           textScaleFactor: 1.0,
//           style: textstyle.copyWith(
//             fontSize: getProportionateScreenWidth(14),
//             color: kBlackColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

//   // Formulaire pour l'immobilier
//   Widget buildImmobilierForm() {
//     return Column(
//       children: [
//       Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12.0), // Rounded corners for the card
//         ),
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0), // Padding inside the card
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Image on the left side
//               Image.network(
//                 'https://www.bpm.mr/uploads/2/2020-09/bankily.JPG', // Replace with correct image URL
//                 height: 40,
//                 width: 40,
//                 fit: BoxFit.cover, // Ensure the image covers the container proportionally
//               ),
//               const SizedBox(width: 16), // Space between image and text
//               // Column for price, duration, and contact
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '6,600 ${getTranslated(context, "MRU")}', // Price
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 4), // Slight space between text
//                     Text(
//                       '6 ${getTranslated(context, "mois")}', // Duration
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                     const SizedBox(height: 8), // Space between text and contact
//                     Text(
//                       '${getTranslated(context, "Contact")}: 47100063', // Contact information
//                       style: const TextStyle(fontSize: 14, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//               // Copy icon on the right
//               IconButton(
//                 icon: const Icon(Icons.copy),
//                 onPressed: () {
//                   // Action to copy contact details
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       // End of the Card Layout

//       const SizedBox(height: 8), // Space between card and the next element

//       // GestureDetector for choosing screenshot
//       GestureDetector(
//         onTap: () {
//           // Action for choosing a payment screenshot
//         },
//         child: Container(
//           height: 100,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(5),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.upload, size: 30, color: Colors.grey),
//                 const SizedBox(height: 8),
//                 Text(
//                   '${getTranslated(context, "Cliquez pour choisir capture d'écran du paiement")}',
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),

//         const SizedBox(height: 10),
//         // Dropdown pour sélectionner la ville
//             isLoadingCities
//                 ? const CircularProgressIndicator() // Affiche un chargement
//                 : DropdownButtonFormField<int>(
//                     value: selectedVille != null ? int.tryParse(selectedVille!) : null,
//                     onChanged: (int? newValue) {
//                       setState(() {
//                         selectedVille = newValue?.toString(); // Stocke l'ID en string
//                       });
//                     },
//                     items: availableCities.map<DropdownMenuItem<int>>((ville) {
//                       return DropdownMenuItem<int>(
//                         value: ville['id'], // ID de la ville
//                         child: Text(getCityName(ville)), // Nom affiché selon la langue
//                       );
//                     }).toList(),
//                     decoration: InputDecoration(
//                       labelText: getTranslated(context, "Ville"),
//                       border: const OutlineInputBorder(),
//                     ),
//                   ),    
//         const SizedBox(height: 10),
//         // Dropdown pour le type d'annonce
//         DropdownButtonFormField<String>(
//           value: selectedType,
//           onChanged: (newValue) {
//             setState(() {
//               selectedType = newValue;
//             });
//           },
//           items: [getTranslated(context, "vendre")!,getTranslated(context, "alouer")!].map((type) {
//             return DropdownMenuItem<String>(
//               value: type,
//               child: Text(type),
//             );
//           }).toList(),
//           decoration: InputDecoration(labelText:getTranslated(context, "Type d'Annonce")!, border: const OutlineInputBorder()),
//         ),
//         const SizedBox(height: 16),
//         // Dropdown pour le type d'immobilier
//         DropdownButtonFormField<String>(
//           value: selectedimmo,
//           onChanged: (newValue) {
//             setState(() {
//               selectedimmo = newValue;
//             });
//           },
//           items: [getTranslated(context, "appartement")!,getTranslated(context, "duplex")!,getTranslated(context, "commercial")!].map((type) {
//             return DropdownMenuItem<String>(
//               value: type,
//               child: Text(type),
//             );
//           }).toList(),
//           decoration: InputDecoration(labelText:getTranslated(context, "Type d'Immobilier"), border: const OutlineInputBorder()),
//         ),
//         const SizedBox(height: 16),
//         // Champ pour le prix
//         TextFormField(
//           controller: prixController,
//           decoration: InputDecoration(labelText: getTranslated(context, "Prix"), border: const OutlineInputBorder()),
//           keyboardType: TextInputType.number,
//         ),
//         const SizedBox(height: 16),
//         // Champ pour la surface
//         TextFormField(
//           controller: surfaceController,
//           decoration: InputDecoration(labelText: getTranslated(context, "Surface"), border: const OutlineInputBorder()),
//           keyboardType: TextInputType.number,
//         ),
//         const SizedBox(height: 16),
//         // Dropdown pour la zone
//         TextFormField(
//           controller: addressController,
//           decoration: InputDecoration(labelText: getTranslated(context, "Adresse"), border: const OutlineInputBorder()),
//           keyboardType: TextInputType.text,
//         ),
//         const SizedBox(height: 16),
//         // Champ pour la description
//         TextField(
//           controller: descriptionController,
//           maxLines: 4,
//           decoration: InputDecoration(border: const OutlineInputBorder(), labelText: getTranslated(context, "Description")),
//         ),
//         const SizedBox(height: 20),
//         // Bouton de soumission
//         isLoaded
//             ? spiner() // Affichage du spinner si isLoaded est vrai
//             : Defaultbutton(
//                 onTap: (){
//                   submitAnnonce(context);
//                 }, // Appeler la fonction submitAnnonce lors de l'appui sur le bouton
//                 color: pcolor,
//                 textcolor: kWhiteColor,
//                 text: getTranslated(context, "Soumettre"),
//                 borderRadius: getProportionateScreenWidth(5),
//                 width: getProportionateScreenWidth(500),
//                 height: getProportionateScreenHeight(45),
//               ),
//       ],
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'dart:ui' as ui;

import 'package:permission_handler/permission_handler.dart';

import 'package:geolocator/geolocator.dart';


class PostAnnonceScreen extends StatefulWidget {
  const PostAnnonceScreen({super.key});

  @override
  _PostAnnonceScreenState createState() => _PostAnnonceScreenState();
}

class _PostAnnonceScreenState extends State<PostAnnonceScreen> {
  String? selectedType;
  String? selectedImmoType;
  String? selectedVille;
  String? selectedOperationType;
  String? selectedPaymentCondition;
  String? selectedPaymentPeriod;
  int currentState = 0;
  bool isLoaded = false;
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  TextEditingController descriptionController = TextEditingController();
  TextEditingController descriptionArController = TextEditingController();
  TextEditingController prixController = TextEditingController();
  TextEditingController surfaceController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController roomsController = TextEditingController();
  TextEditingController xCoordController = TextEditingController();
  TextEditingController yCoordController = TextEditingController();
  TextEditingController villeNomController = TextEditingController();
  TextEditingController villeNomArController = TextEditingController();
  TextEditingController villeRegionController = TextEditingController();
  TextEditingController villeRegionArController = TextEditingController();

  final storage = const FlutterSecureStorage();
  final String apiUrl = 'https://akarina.online/akareena/residentiel/create/';

  // Options pour les dropdowns
  final List<String> immoTypes = ['appartement', 'duplex', 'maisonceremonie'];
  final List<String> operationTypes = ['alouer', 'vendre'];
  final List<String> paymentConditions = ['Paiement mensuel', 'Paiement trimestriel', 'Paiement annuel'];
  final List<String> paymentPeriods = ['Mensuelle', 'Trimestrielle', 'Annuelle'];

  Future<void> pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null) {
        setState(() {
          selectedImages.addAll(images.map((image) => File(image.path)).toList());
        });
      }
    } catch (e) {
      showToast(
        'Erreur lors de la sélection des images: $e',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  }
  
  // Nouvelle méthode pour récupérer la position
  // Future<void> _getCurrentLocation() async {
  //   setState(() {
  //     isLoaded = true;
  //   });

  //   try {
  //     // Vérifiez les permissions
  //     final status = await Permission.location.request();
  //     if (!status.isGranted) {
  //       throw Exception('Permission de localisation refusée');
  //     }

  //     // Récupérez la position
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     // Mettez à jour les champs x et y
  //     setState(() {
  //       xCoordController.text = position.longitude.toString();
  //       yCoordController.text = position.latitude.toString();
  //     });

  //   } catch (e) {
  //     showToast(
  //       'Erreur lors de la récupération de la position: $e',
  //       context: context,
  //       backgroundColor: Colors.red,
  //       duration: const Duration(seconds: 4),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoaded = false;
  //     });
  //   }
  // }

Future<void> _getCurrentLocation() async {
  setState(() => isLoaded = true);

  try {
    // Vérifiez si le service est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationServiceDisabledAlert();
      return;
    }

    // Demande de permission avec gestion fine
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await _showPermissionPermanentlyDeniedAlert();
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        return;
      }
    }

    // Récupération de la position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      xCoordController.text = position.longitude.toStringAsFixed(6);
      yCoordController.text = position.latitude.toStringAsFixed(6);
    });

  } catch (e) {
    showToast(
      'Erreur: ${e.toString()}',
      context: context,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  } finally {
    setState(() => isLoaded = false);
  }
}

Future<void> _showLocationServiceDisabledAlert() async {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(getTranslated(context, "Service de localisation désactivé")!),
      content: Text(getTranslated(context, "Veuillez activer la localisation dans les paramètres de votre appareil")!),
      actions: <Widget>[
        TextButton(
          child: Text(getTranslated(context, "Annuler")!),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(getTranslated(context, "Paramètres")!),
          onPressed: () {
            Geolocator.openLocationSettings();
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

Future<void> _showPermissionPermanentlyDeniedAlert() async {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(getTranslated(context, "Permission refusée définitivement")!),
      content: Text(getTranslated(context, "Veuillez autoriser l'accès à la localisation dans les paramètres de l'application")!),
      actions: <Widget>[
        TextButton(
          child: Text(getTranslated(context, "Annuler")!),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(getTranslated(context, "Paramètres")!),
          onPressed: () {
            openAppSettings(); // Du package permission_handler
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

Future<void> submitResidentiel() async {
  try {
    debugPrint('[SubmitResidentiel] Début de la soumission');
    
    setState(() {
      isLoaded = true;
    });

    String? token = await storage.read(key: "access");
    String? userId = await storage.read(key: "id");
    debugPrint('[SubmitResidentiel] Token: ${token != null ? "présent" : "absent"}');
    debugPrint('[SubmitResidentiel] UserID: $userId');

    if (token == null || userId == null) {
      debugPrint('[SubmitResidentiel] Erreur: Utilisateur non connecté');
      showToast(
        'Vous devez être connecté pour poster une annonce',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
      setState(() {
        isLoaded = false;
      });
      return;
    }

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $token';

    // Log des données du formulaire
    debugPrint('[SubmitResidentiel] Données du formulaire:');
    debugPrint('- Type: ${selectedImmoType}');
    debugPrint('- Description: ${descriptionController.text}');
    debugPrint('- Adresse: ${addressController.text}');
    debugPrint('- Surface: ${surfaceController.text}');
    debugPrint('- Nombre d\'images: ${selectedImages.length}');

    // Ajout des champs de formulaire
    request.fields['type'] = selectedImmoType ?? '';
    request.fields['user_id'] = userId;
    request.fields['description'] = descriptionController.text;
    request.fields['description_ar'] = descriptionArController.text;
    request.fields['adresse'] = addressController.text;
    request.fields['surface'] = surfaceController.text;
    request.fields['x'] = xCoordController.text;
    request.fields['y'] = yCoordController.text;
    request.fields['nombre_de_chambres'] = roomsController.text;
    request.fields['presence_de_balcon'] = 'true';
    
    // Informations sur la ville
    request.fields['ville[nom]'] = villeNomController.text;
    request.fields['ville[nom_ar]'] = villeNomArController.text;
    request.fields['ville[region]'] = villeRegionController.text;
    request.fields['ville[region_ar]'] = villeRegionArController.text;
    
    // Informations sur l'opération
    request.fields['operation[type]'] = selectedOperationType ?? '';
    request.fields['operation[loyer_mensuel]'] = prixController.text;
    request.fields['operation[condition_de_alouer]'] = selectedPaymentCondition ?? '';
    request.fields['operation[periode]'] = selectedPaymentPeriod ?? '';

    // Ajout des images
    for (var image in selectedImages) {
      var stream = http.ByteStream(image.openRead());
      var length = await image.length();
      var multipartFile = http.MultipartFile(
        'images',
        stream,
        length,
        filename: path.basename(image.path),
      );
      request.files.add(multipartFile);
      debugPrint('[SubmitResidentiel] Image ajoutée: ${image.path}');
    }

    debugPrint('[SubmitResidentiel] Envoi de la requête...');
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    
    debugPrint('[SubmitResidentiel] Réponse reçue:');
    debugPrint('- Status Code: ${response.statusCode}');
    debugPrint('- Body: $responseString');

    var jsonResponse = json.decode(responseString);

    if (response.statusCode == 201) {
      debugPrint('[SubmitResidentiel] Succès: Annonce créée');
      showToast(
        'Annonce créée avec succès',
        context: context,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      );
      resetForm();
    } else {
      debugPrint('[SubmitResidentiel] Erreur API: ${jsonResponse['error']}');
      showToast(
        jsonResponse['error'] ?? 'Erreur lors de la création de l\'annonce',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  } on http.ClientException catch (e) {
    debugPrint('[SubmitResidentiel] Erreur réseau: ${e.toString()}');
    debugPrint('[SubmitResidentiel] StackTrace: ${e.toString()}');
    showToast(
      'Erreur de connexion. Vérifiez votre internet',
      context: context,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  } on SocketException catch (e) {
    debugPrint('[SubmitResidentiel] Erreur socket: ${e.toString()}');
    showToast(
      'Problème de connexion au serveur',
      context: context,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  } on TimeoutException catch (e) {
    debugPrint('[SubmitResidentiel] Timeout: ${e.toString()}');
    showToast(
      'Le serveur a mis trop de temps à répondre',
      context: context,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  } on FormatException catch (e) {
    debugPrint('[SubmitResidentiel] Format JSON invalide: ${e.toString()}');
    showToast(
      'Erreur dans le format des données',
      context: context,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  } catch (e, stackTrace) {
    debugPrint('[SubmitResidentiel] Erreur inattendue: ${e.toString()}');
    debugPrint('[SubmitResidentiel] StackTrace: $stackTrace');
    showToast(
      'Une erreur inattendue est survenue',
      context: context,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoaded = false;
      });
    }
    debugPrint('[SubmitResidentiel] Fin de la soumission');
  }
}


  void resetForm() {
    setState(() {
      selectedType = null;
      selectedImmoType = null;
      selectedVille = null;
      selectedOperationType = null;
      selectedPaymentCondition = null;
      selectedPaymentPeriod = null;
      selectedImages.clear();
      
      descriptionController.clear();
      descriptionArController.clear();
      prixController.clear();
      surfaceController.clear();
      addressController.clear();
      roomsController.clear();
      xCoordController.clear();
      yCoordController.clear();
      villeNomController.clear();
      villeNomArController.clear();
      villeRegionController.clear();
      villeRegionArController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du type d'annonce (Immobilier/Projet)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: kgrey300),
                borderRadius: BorderRadius.circular(getProportionateScreenWidth(7)),
                color: kgrey100,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(5),
                vertical: getProportionateScreenHeight(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentState = 0;
                      });
                    },
                    child: _buildStateButton(
                      isActive: currentState == 0, 
                      text: getTranslated(context, "Immobilier")!),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentState = 1;
                      });
                    },
                    child: _buildStateButton(
                      isActive: currentState == 1, 
                      text: getTranslated(context, "Projet")!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            currentState == 0 ? buildImmobilierForm() : const ProjectSubmissionForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateButton({required bool isActive, required String text}) {
    return Container(
      height: getProportionateScreenHeight(37),
      width: getProportionateScreenWidth(155),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(5)),
        color: isActive ? kWhiteColor : kgrey100,
        boxShadow: [
          BoxShadow(
            color: isActive ? kgrey300 : kgrey100,
            offset: const Offset(0.0, 0.0),
            blurRadius: 10.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textScaleFactor: 1.0,
          style: textstyle.copyWith(
            fontSize: getProportionateScreenWidth(14),
            color: kBlackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildImmobilierForm() {
    return Column(
      children: [
        // Type d'immobilier
        DropdownButtonFormField<String>(
          value: selectedImmoType,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Type d'immobilier")!,
            border: const OutlineInputBorder(),
          ),
          items: immoTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedImmoType = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Description (FR)
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Description (Français)"),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // Description (AR)
        TextField(
          controller: descriptionArController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Description"),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          // textDirection: TextDirection.rtl,
          textDirection: ui.TextDirection.ltr
        ),
        const SizedBox(height: 16),
        
        // Adresse
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Adresse"),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Surface
        TextField(
          controller: surfaceController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Surface"),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        // Coordonnées X
        // TextField(
        //   controller: xCoordController,
        //   decoration: InputDecoration(
        //     labelText: "Coordonnée X (Longitude)",
        //     border: const OutlineInputBorder(),
        //   ),
        //   keyboardType: TextInputType.numberWithOptions(decimal: true),
        // ),
        // const SizedBox(height: 16),
        
        // // Coordonnées Y
        // TextField(
        //   controller: yCoordController,
        //   decoration: InputDecoration(
        //     labelText: "Coordonnée Y (Latitude)",
        //     border: const OutlineInputBorder(),
        //   ),
        //   keyboardType: TextInputType.numberWithOptions(decimal: true),
        // ),
        // const SizedBox(height: 16),
        // Remplacez les TextField existants pour x et y par ceci :
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: xCoordController,
                decoration: InputDecoration(
                  labelText: "Longitude (X)",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: yCoordController,
                decoration: InputDecoration(
                  labelText: "Latitude (Y)",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Defaultbutton(
          onTap: _getCurrentLocation,
          color: Colors.blue,
          textcolor: Colors.white,
          text: "Utiliser ma position actuelle",
          borderRadius: getProportionateScreenWidth(5),
          width: double.infinity,
          height: getProportionateScreenHeight(45),
        ),
        const SizedBox(height: 10),
        // Nombre de chambres
        TextField(
          controller: roomsController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Nombre de chambres"),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        // Informations sur la ville
        Text(
          getTranslated(context, "Informations sur la ville")!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Nom ville (FR)
        TextField(
          controller: villeNomController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Nom de la ville (FR)"),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Nom ville (AR)
        TextField(
          controller: villeNomArController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Nom de la ville (AR)"),
            border: const OutlineInputBorder(),
          ),
          // textDirection: TextDirection.rtl,
          textDirection: ui.TextDirection.ltr

          
          
        ),
        const SizedBox(height: 16),
        
        // Région (FR)
        TextField(
          controller: villeRegionController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Région (FR)"),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Région (AR)
        TextField(
          controller: villeRegionArController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Région (AR)"),
            border: const OutlineInputBorder(),
          ),
          // textDirection: TextDirection.rtl,
          textDirection: ui.TextDirection.ltr

        ),
        const SizedBox(height: 16),
        
        // Informations sur l'opération
        Text(
          getTranslated(context, "Informations sur l'opération")!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Type d'opération
        DropdownButtonFormField<String>(
          value: selectedOperationType,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Type d'opération"),
            border: const OutlineInputBorder(),
          ),
          items: operationTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedOperationType = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Prix/Loyer
        TextField(
          controller: prixController,
          decoration: InputDecoration(
            labelText: selectedOperationType == 'alouer' 
                ? getTranslated(context, "Loyer mensuel")
                : getTranslated(context, "Prix de vente"),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        // Condition de paiement
        if (selectedOperationType == 'alouer') ...[
          DropdownButtonFormField<String>(
            value: selectedPaymentCondition,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Condition de paiement"),
              border: const OutlineInputBorder(),
            ),
            items: paymentConditions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentCondition = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Période de paiement
          DropdownButtonFormField<String>(
            value: selectedPaymentPeriod,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Période de paiement"),
              border: const OutlineInputBorder(),
            ),
            items: paymentPeriods.map((period) {
              return DropdownMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentPeriod = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // Sélection des images
        Text(
          getTranslated(context, "Images (minimum 1, maximum 6)")!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    children: [
                      Image.file(
                        selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        ElevatedButton(
          onPressed: pickImages,
          child: Text(getTranslated(context, "Ajouter des images")!),
        ),
        const SizedBox(height: 16),
        
        // Bouton de soumission
        isLoaded
            ? spiner()
            : Defaultbutton(
                onTap: submitResidentiel,
                color: pcolor,
                textcolor: kWhiteColor,
                text: getTranslated(context, "Soumettre"),
                borderRadius: getProportionateScreenWidth(5),
                width: getProportionateScreenWidth(500),
                height: getProportionateScreenHeight(45),
              ),
      ],
    );
  }
}


// Project submission form code remains unchanged


class ProjectSubmissionForm extends StatefulWidget {
  const ProjectSubmissionForm({super.key});

  @override
  _ProjectSubmissionFormState createState() => _ProjectSubmissionFormState();
}

class _ProjectSubmissionFormState extends State<ProjectSubmissionForm> {
  String? selectedType;
  TextEditingController addressController = TextEditingController();
  TextEditingController budgetController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

  // Date picker function
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(  // Ensure scroll for large content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/svg/logo.svg',
              width: 100,
              height: 100,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            getTranslated(context, "Soumettre un Projet Immobilier")!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            getTranslated(context, "Chez Akareena, nous nous engageons à traiter votre demande rapidement et efficacement. Remplissez le formulaire ci-dessous pour nous fournir les détails de votre projet. Nous reviendrons vers vous dès que possible.")!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Dropdown for selecting project type
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Type de Projet")!,
            ),
            value: selectedType,
            items: [getTranslated(context, "appartement")!, getTranslated(context, "Maison")!,getTranslated(context, "Terrain")!]
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
              });
            },
          ),
          const SizedBox(height: 20),
          // Address input field
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Adresse")!,
            ),
          ),
          const SizedBox(height: 20),
          // Budget input field
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Budget")!,
            ),
          ),
          const SizedBox(height: 20),
          // Description input field
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Description")!,
            ),
          ),
          const SizedBox(height: 20),
          // Date pickers for project start and end dates
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: getTranslated(context, "Début du Projet")!,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, startDateController),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: getTranslated(context, "Fin du Projet")!,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, endDateController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Submit button
          Defaultbutton(
            onTap: () {
              // Handle project submission
            },
            color: pcolor,
            textcolor: kWhiteColor,
            text: getTranslated(context, 'Soumettre')!,
            borderRadius: getProportionateScreenWidth(5),
            width: getProportionateScreenWidth(500),
            height: getProportionateScreenHeight(45),
          ),
        ],
      ),
    );
  }
}
