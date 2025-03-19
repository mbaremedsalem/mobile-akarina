import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:bcipay/data/services.dart';
import 'package:akarina/data/data_providers/exception.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/user.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../presentations/screens/login/index_login.dart';

class NetworkService {
  final storage = const FlutterSecureStorage();
  int timeout = 60;
  String baseUrl = "https://akarina.online/";

  // String baseUrl = "https://akarina-location-b65cbbb9833c.herokuapp.com/";


  Future<dynamic> login(String phone, String? password) async {
    
    // ignore: prefer_typing_uninitialized_variables
    var responseJson;
    var url = Uri.parse("${baseUrl}user/api/login/");
    // print(baseParPays(pays));
    try {
      var response = await post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          "login": "+222$phone",
          "password": password
        }),
      ).timeout(Duration(seconds: timeout));

      responseJson = _loginresponse(response);
    } catch (e) {
      // print(e);
    }

    return responseJson;
  }


Future<Map<String, dynamic>> fetchImmobDetails(int id) async {
  final url = '${baseUrl}akareena/residentiels/$id';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json; charset=utf-8', // Indique que les données attendues sont en UTF-8
    },
  );

  if (response.statusCode == 200) {
    // Décoder explicitement en UTF-8 pour gérer les caractères spéciaux
    final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
    print(decodedBody); // Facultatif : pour vérifier les données reçues
    return decodedBody;
  } else {
    throw Exception('Failed to load property details: ${response.body}');
  }
}





  // Nouvelle méthode pour récupérer les catégories
  Future<Map<String, dynamic>?> fetchCategories() async {
    var url = Uri.parse("${baseUrl}akareena/immobilier-summary/");
    try {
      var response = await get(
        url,
        headers: {
        'Content-Type': 'application/json; charset=utf-8', // Spécifiez UTF-8 ici
      },
      ).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load categories : ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return null;
    }
  }


  Future<dynamic> fetchApartments(Uri uri) async {
    // var url = Uri.parse("${baseUrl}akareena/appartements/");
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load appartement : ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des appartement: $e');
      return null;
    }
  }
    Future<dynamic> fetchResidence1() async {
    var url = Uri.parse("${baseUrl}akareena/residentiels/");
    try {
      var response = await get(
        url,
        headers: {
        'Content-Type': 'application/json; charset=utf-8', // Spécifiez UTF-8 ici
      },
      ).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        print("#########${response.body}");
        return jsonDecode(response.body);
        
      } else {
        throw Exception('Failed to load categories : ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return null;
    }
  }
  Future<dynamic> fetchResidence() async {
  var url = Uri.parse("${baseUrl}akareena/imobiers/");
  try {
    var response = await get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8', // Spécifiez UTF-8 ici
      },
    ).timeout(Duration(seconds: timeout));

    if (response.statusCode == 200) {
      print("#########${response.body}");
      var data = jsonDecode(response.body);
      return data['results']; // Retourne uniquement la liste des résultats
    } else {
      throw Exception('Failed to load properties: ${response.body}');
    }
  } catch (e) {
    print('Erreur lors de la récupération des propriétés: $e');
    return null;
  }
}

    Future<dynamic> fetchProximite() async {
    var url = Uri.parse("${baseUrl}akareena/residentiel/recommendation/proximite/?x=2.294351&y=48.858844");
    try {
      var response = await get(
        url,
        headers: {
        'Content-Type': 'application/json; charset=utf-8', // Spécifiez UTF-8 ici
      },
      ).timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load categories : ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return null;
    }
  }
// --------- chat  
// Fonction pour vérifier si le token est valide ou expiré
// Future<bool> isTokenValid(String? token) async {
//   if (token == null || token.isEmpty) return false;

//   try {
//     // Utiliser JwtDecoder pour vérifier si le token est expiré
//     return !JwtDecoder.isExpired(token);
//   } catch (e) {
//     // Gérer les cas où le token est mal formé ou non décodable
//     return false;
//   }
// }

// Fonction pour afficher une alerte si le token est invalide ou expiré
// void _showInvalidTokenAlert(BuildContext context) {
//   showDialog(
//     context: context,
//     barrierDismissible: false, // Empêche de fermer l'alerte sans action
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text("Session Expirée"),
//         content: const Text("Votre session a expiré. Veuillez vous reconnecter pour continuer."),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Rediriger vers l'écran de connexion
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const IndexLogin()),
//               );
//             },
//             child: const Text("OK"),
//           ),
//         ],
//       );
//     },
//   );
// }

Future<void> sendImages(int conversationId, List<File> images, BuildContext context) async {
  final uri = Uri.parse(baseUrl+'user/conversations/$conversationId/images/');
  debugPrint("URI: $uri"); // Vérifie si l'URL est correcte

  String? token = await storage.read(key: "access");
  debugPrint("Token récupéré: $token");

  if (token == null) {
    debugPrint("Erreur: Le token est NULL");
    return;
  }

  final request = http.MultipartRequest('POST', uri);
  request.headers['Authorization'] = 'Bearer $token';

  debugPrint("Ajout des images...");
  for (var imageFile in images) {
    debugPrint("Ajout de l'image: ${imageFile.path}");
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
  }

  try {
    debugPrint("Envoi de la requête...");
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint("Statut HTTP: ${response.statusCode}");
    debugPrint("Réponse: $responseBody");

    if (response.statusCode == 201) {
      debugPrint("✅ Images envoyées avec succès: $responseBody");
    } else {
      debugPrint("❌ Échec de l'envoi des images. Code: ${response.statusCode}, Réponse: $responseBody");
    }
  } catch (e) {
    debugPrint("❌ Erreur lors de l'envoi des images: $e");
  }
}



// --------- chat  
// Fonction pour vérifier si le token est valide ou expiré


// Vérifier si le token est valide


// Afficher une alerte si l'utilisateur n'est pas connecté ou si le token est expiré
// Vérifier si le token est valide
Future<bool> isTokenValid(String? token) async {
  if (token == null || token.isEmpty) return false;
  return !JwtDecoder.isExpired(token); // Retourne false si le token est expiré
}

// Afficher une alerte si l'utilisateur n'est pas connecté ou si le token est expiré
void _showTokenAlert(BuildContext context, {bool isExpired = false}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(isExpired ?getTranslated(context, "Session Expirée")! :getTranslated(context, "Non Connecté")!),
        content: Text(isExpired
            ?getTranslated(context, "Votre session a expiré. Veuillez vous reconnecter.")!
            :getTranslated(context, "Vous devez vous connecter pour accéder à cette fonctionnalité.")!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const IndexLogin()),
              );
            },
            child:  Text(getTranslated(context, "cnx")!),
          ),
        ],
      );
    },
  );
}

// Fonction pour récupérer les utilisateurs


// Fonction pour récupérer les utilisateurs
Future<List<User>> fetchUsers(BuildContext context) async {
  final url = Uri.parse('https://akarina.online/user/clients/');
  String? token = await storage.read(key: "access");

  // Vérifier si l'utilisateur est connecté
  if (token == null || token.isEmpty) {
    _showTokenAlert(context, isExpired: false); // Afficher l'alerte "Non Connecté"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception(getTranslated(context, "Non Connecté"));
  }

  // Vérifier si le token est expiré
  if (await isTokenValid(token)) {
    _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception(getTranslated(context, "Session Expirée"));
  }

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Si la requête réussit, on parse la réponse
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      // Si le token est invalide ou expiré (401 Unauthorized)
      final responseBody = jsonDecode(response.body);
      if (responseBody['code'] == "token_not_valid") {
        _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
        await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
        throw Exception(getTranslated(context, "Session Expirée"));
      }
    }

    // Gérer les autres erreurs
    print('Erreur API : ${response.body}');
    throw Exception('${getTranslated(context, "Échec du chargement des utilisateurs ")}: ${response.body}');
  } catch (e) {
    print('Erreur : $e');
    rethrow;
  }
}

// Future<List<User>> fetchUsers(BuildContext context) async {
//   final url = Uri.parse('https://akarina.online/user/clients/');
//   String? token = await storage.read(key: "access");

//   // Vérifier si l'utilisateur est connecté
//   if (token == null || token.isEmpty) {
//     _showTokenAlert(context, isExpired: false); // Afficher l'alerte "Non Connecté"
//     await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
//     throw Exception("Utilisateur non connecté");
//   }

//   // Vérifier si le token est expiré
//   if (await isTokenValid(token)) {
//     _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
//     await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
//     throw Exception("Token expiré");
//   }

//   try {
//     final response = await http.get(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     if (response.statusCode == 200) {
//       // Si la requête réussit, on parse la réponse
//       List<dynamic> data = jsonDecode(response.body);
//       return data.map((json) => User.fromJson(json)).toList();
//     } else if (response.statusCode == 401) {
//       // Si le token est invalide ou expiré (401 Unauthorized)
//       final responseBody = jsonDecode(response.body);
//       if (responseBody['code'] == "token_not_valid") {
//         _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
//         await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
//         throw Exception("Le token est invalide ou expiré.");
//       }
//     }

//     // Gérer les autres erreurs
//     print('Erreur API : ${response.body}');
//     throw Exception('Échec du chargement des utilisateurs : ${response.body}');
//   } catch (e) {
//     print('Erreur : $e');
//     rethrow;
//   }
// }

// Fonction pour créer ou récupérer une conversation
Future<Map<String, dynamic>> getConversation(int participantId, BuildContext context) async {
  final url = Uri.parse('${baseUrl}user/conversations/');
  String? token = await storage.read(key: "access");
  String? idString = await storage.read(key: "id");

  int? id = idString != null ? int.tryParse(idString) : null;

  // Vérifier si l'utilisateur est connecté
  if (token == null || token.isEmpty) {
    _showTokenAlert(context, isExpired: false); // Afficher l'alerte "Non Connecté"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception(getTranslated(context, "Non Connecté"));
  }

  // Vérifier si le token est expiré
  if (await isTokenValid(token)) {
    _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception(getTranslated(context, "Session Expirée"));
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "participants": [participantId, id], // Inclure le participant et l'utilisateur actuel
      }),
    );

    if (response.statusCode == 201) {
      // Nouvelle conversation créée
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      var errorResponse = jsonDecode(response.body);
      if (errorResponse['message'] == "Une conversation avec ces participants existe déjà.") {
        // La conversation existe déjà, retourner son ID
        return {"id": errorResponse["id"], "participants": [participantId, id]};
      } else {
        throw Exception('Erreur: ${errorResponse["message"]}');
      }
    } else {
      throw Exception('Impossible de récupérer la conversation: ${response.body}');
    }
  } catch (e) {
    print('Erreur : $e');
    rethrow;
  }
}

// Fonction pour envoyer un message
Future<void> sendMessage(int conversationId, String content, BuildContext context) async {
  final url = Uri.parse('${baseUrl}user/messages/');
  String? token = await storage.read(key: "access");

  // Vérifier si l'utilisateur est connecté
  if (token == null || token.isEmpty) {
    _showTokenAlert(context, isExpired: false); // Afficher l'alerte "Non Connecté"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception("Utilisateur non connecté");
  }

  // Vérifier si le token est expiré
  if (await isTokenValid(token)) {
    _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception("Token expiré");
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "conversation": conversationId,
        "content": content,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Échec de l\'envoi du message: ${response.body}');
    }
  } catch (e) {
    print('Erreur : $e');
    rethrow;
  }
}

// Fonction pour récupérer les messages d'une conversation
Future<List<dynamic>> fetchMessages(int conversationId, BuildContext context) async {
  final url = Uri.parse('${baseUrl}user/$conversationId/messages/');
  String? token = await storage.read(key: "access");

  // Vérifier si l'utilisateur est connecté
  if (token == null || token.isEmpty) {
    _showTokenAlert(context, isExpired: false); // Afficher l'alerte "Non Connecté"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception("Utilisateur non connecté");
  }

  // Vérifier si le token est expiré
  if (await isTokenValid(token)) {
    _showTokenAlert(context, isExpired: true); // Afficher l'alerte "Session Expirée"
    await Future.delayed(const Duration(milliseconds: 500)); // Délai pour afficher l'alerte
    throw Exception("Token expiré");
  }

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8', // Spécifiez UTF-8 ici
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Décoder le corps en UTF-8 pour garantir que les caractères spéciaux sont correctement interprétés
      final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedBody;
    } else {
      throw Exception('Échec de la récupération des messages: ${response.body}');
    }
  } catch (e) {
    print('Erreur : $e');
    rethrow;
  }
}

  Future<List<dynamic>?> fetchcagnotte() async {
    String? token = await storage.read(key: "token");
    String? id = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    try {
      final response = await post(
          Uri.parse("${baseParPays(pays!)}api/cagnote/list/"),
          headers: {"Authorization": "JWT $token"},
          body: jsonEncode({"id": id})).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<List<dynamic>?> fetchagences() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/agence/list/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<List<dynamic>?> benfecairelist(String? numerogroupe) async {
    String? token = await storage.read(key: "token");
    String? id = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await post(
          Uri.parse("${baseParPays(pays!)}api/func/transaction/beneficiaires-payement_masse/"),
          headers: {"Authorization": "JWT $token"},
          body: jsonEncode({
            "numero_grp_payement": numerogroupe,
            "user": int.parse(id!)
          })).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> facturier() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/user/facturier/list/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
      // print(token);
    } catch (e) {
      // print(e);
    }

    return responseJson;
  }

  Future<List<dynamic>?> fetchnotfications() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/notification/list/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> searsh(String startDate, String endDate) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    // print(startDate);
    // print(endDate);

    try {
      final response = await post(
              Uri.parse("${baseParPays(pays!)}api/transaction/list/filter/"),
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"date_1": startDate, "date_2": endDate}))
          .timeout(const Duration(seconds: 70));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<List<dynamic>?> fetchtransactions() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    // print('here..');
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/transaction/list/last/"),
        headers: {
          "Authorization": "JWT $token",
          "Content-Type": "application/json; charset=utf-8"
        },
      ).timeout(const Duration(seconds: 70));
      responseJson = _response(response);
      // print(response.statusCode);
      // print(response.body);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> validvendor(String qrcode) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/valid-vendor-id/");
    var responseJson;

    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({"code": qrcode}),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> fetchFrais(String transactionType, double? montant) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var url = Uri.parse("${baseParPays(pays!)}api/get_frais_transaction/");
    var responseJson;

    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode(
          {
            "type_transaction": transactionType,
            "montant": montant,
          },
        ),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> payment(String qrcode) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;

    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/valid-code-payement/");

    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({"code": qrcode}),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> envoi(String tel, double montant) async {
    String? token = await storage.read(key: "token");
    String? id = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    var responseJson;

    var url = Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/check/");

    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({"sender": id, "tel": tel, "montant": montant}),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> paycommercent(
      String? id, double montant, String labbel) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    var responseJson;

    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/fast-payement/");

    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "client": myid,
          "vendor": id,
          "montant": montant,
          "label": labbel,
          "type_comptable": "11"
        }),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> confiremepayment(String? id, String codeComptable) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    // print(codeComptable);
    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/payement/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "client": myid,
          "pre_transaction": id,
          "type_comptable": codeComptable
        }),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

//  restore password
  Future<Response> restorePassword(String phone) async {
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/user/password/reset/");

    try {
      Response response = await post(
        url,
        body: {"telephone": phone},
      ).timeout(Duration(seconds: timeout));
      // print(response.body);
      // print(response.statusCode);
      responseJson = response;
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> envoiclientnoraml(
      double montant, String? tel, String? libelle) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/envoie/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "client_origine": myid,
          "tel": tel,
          "montant": montant,
          "libelle": libelle,
          "type_comptable": "02"
        }),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
      // print(response.statusCode);
      // print(response.body);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> envoidigi(double montant, String? id, String? libelle) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/envoie/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "client_origine": myid,
          "client_destinataire": id,
          "montant": montant,
          "libelle": libelle,
          "type_comptable": "01"
        }),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> retirer(double montant) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/retrait/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "montant": montant,
          "role": "CLIENT",
          "id": myid,
          "type_comptable": "05"
        }),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
      // print(response.statusCode);
      // print(response.body);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<Response> credittel(String montant, String operateur, String telephone,
      String? langue) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/forfait/carte-credit/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "operateur": operateur,
            "tel": telephone,
            "montant": montant,
            "langue": langue
          })).timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      // print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> fetchbalance() async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/user/auth-user/get/$myid/");
    try {
      var response = await get(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
      // print(response.statusCode);
      // print(response.body);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> checkclient(int tel) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/cagnote/check-client_digipay/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({"tel": tel}),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> confirmecagnottecreation(
      String? nom, int? ojectif, String? motif, int? benef) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/cagnote/create/");

    Map body = {
      "client": myid,
      "nom": nom,
      "objectif": ojectif,
      "motif": motif,
      "beneficiaire": benef
    };
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> deleteCagnotte(int? idcagnotte) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/cagnote/delete/");

    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "cagnote": idcagnotte,
        }),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> confirmepartcipation(int? idcagnotte, int montant) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/participer-cagnote/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "cagnote": idcagnotte,
          "client": int.parse(myid!),
          "montant": montant
        }),
      ).timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      // print(response.body);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> particpateCagnotte(String? idcagnotte) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/valid-cagnote-code/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({"numero_cagnote": idcagnotte, "id": myid}),
      ).timeout(Duration(seconds: timeout));

      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> cloturer(int? id) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/cloturer-cagnote/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"cagnote": id}))
          .timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> fetchparticapnts(int? id) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/participants-cagnote/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"cagnote": id}))
          .timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> updatedonation({int? idcagnotte, int? montant}) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/update-participation/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "cagnote": idcagnotte,
            "client": int.parse(myid!),
            "montant": montant
          })).timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }


  Future<List<dynamic>?> listGroupe() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var url = Uri.parse("${baseParPays(pays!)}api/grp-payement/list/");

    var responseJson;

    try {
      var response = await get(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> fetchbenfecaires(int? grouppaiment) async {
    String? token = await storage.read(key: "token");
    // String myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/beneficiaire-grp_payement/list/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"grp_payement": grouppaiment}))
          .timeout(Duration(seconds: timeout));

      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> addgroupe(String? nom) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/grp-payement/create/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({"nom": nom, "responsable": int.parse(myid!)}),
      ).timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> addmembre(int number) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/grp-payement/check-client_digipay/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
        },
        body: jsonEncode({"tel": number, "user": int.parse(myid!)}),
      ).timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> confirmeaddingmembre(
      int? benefecaire, int? groupe, int montant, String motif) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/beneficiaire-grp_payement/create/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "montant": montant,
            "motif": motif,
            "grp_payement": groupe,
            "beneficiaire": benefecaire,
          })).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> deletegrouoe(int? id) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/grp-payement/delete/$id/");
    try {
      var response = await delete(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> updatemembre(
      int? id, int? group, int montant, String motif) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/beneficiaire-grp_payement/update/$id/");
    try {
      var response = await put(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "grp_payement": group,
            "id": id,
            "montant": montant,
            "motif": motif
          })).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> deletemembre(int? id) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/beneficiaire-grp_payement/delete/$id/");
    try {
      var response = await delete(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));

      // print(response.body);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> paiementgroupe(int? id, String? motif) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/payement-masse/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "grp_payement": id,
            "expediteur": myid,
            "motif": motif,
            "type_comptable": "20"
          })).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> profiledata() async {
    String? token = await storage.read(key: "token");


    var responseJson;
    // var url = Uri.parse(baseParPays(pays!) + "api/func/profil/statistique/$myid/");
    var url = Uri.parse(
        "$baseUrl/user/profile/");
    try {
      var response = await get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));

      // print(response.statusCode);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> updateprofile(Map body) async {
    String? token = await storage.read(key: "token");

    var responseJson;
    var url =
        Uri.parse("$baseUrl/user/update-profile/");
    try {
      var response = await put(url,
              headers: {
                "Authorization": "Bearer $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));

      responseJson = _response(response);
      // print(response.statusCode);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> logout(Map body) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/logout/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "Bearer $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));

      // print(response.statusCode);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> changepassword(Map body) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/user/password/update/$myid/");
    try {
      var response = await put(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body)
              )
          .timeout(Duration(seconds: timeout));

      // print(response.body);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> confirmecode(String? code) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/user/func/valid-PIN/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"id": int.parse(myid!), "PIN": code}))
          .timeout(Duration(seconds: timeout));

      // print(response.body);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> consultmauritel(String? number) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/bmi/client_digiPay/get-facture/wifi-mauritel/$number/");
    try {
      var response = await get(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));

      // print(response.statusCode);
      // print(response.body);

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> checkreferencefacture(
      String? reference, String? service) async {
    String? token = await storage.read(key: "token");
    // String myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/get-facture/somelec/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"reference": reference, "service": service}))
          .timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> paiementmauritel(
      int? id, String? customercode, double? montant) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/payement/wifi-mauritel/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "client": int.parse(myid!),
            "facturier": id,
            "montant": montant,
            "customercode": customercode
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      // responseJson = response.body;
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> somelecpayment(double? montant, String? ref, int? id,
      String? service, double? soldeFacture) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/payement/somelec/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "client": int.parse(myid!),
            "facturier": id,
            "montant": montant,
            "reference": ref,
            "type_comptable": "16",
            "service": service,
            "solde_facture": soldeFacture
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> getNewAccessToken() async {
    String? refresh = await storage.read(key: "refresh");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/token/refresh/");
    try {
      var response = await post(url,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
              },
              body: jsonEncode({"refresh": refresh}))
          .timeout(const Duration(seconds: 30));

      // print("${response.statusCode} NewaccessToken");

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> fetchsession() async {
    String? pays = await storage.read(key: 'country');
    // print("called");
    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/session/check_session_expiration");
    try {
      var response = await get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      ).timeout(const Duration(seconds: 30));

      // print("${response.statusCode}");

      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> operationbancaire(
      String? compteBancaire,
      String? note,
      int montant,
      String? banque,
      String typeComptable,
      String? nomBenfecaire) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    // print(compteBancaire);
    // print(montant);
    // print(note);
    // print(banque);
    // print(nomBenfecaire);

    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/virement/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "num_compte_bancaire": compteBancaire,
            "client_origine": int.parse(myid!),
            "montant": montant,
            "note": note,
            "nom_banque": banque,
            "type_comptable": typeComptable,
            "nom_beneficiaire": nomBenfecaire
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      // responseJson = response.body;
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  dynamic _response(Response response) {
    // print(response.body);
    switch (response.statusCode) {
      case 200:
        String myres = utf8.decode(response.bodyBytes);
        var responseJson = json.decode(myres);
        return responseJson;
      case 204:
        return response;
      case 205:
        return response;
      case 201:
        String myres = utf8.decode(response.bodyBytes);
        var responseJson = json.decode(myres);
        return responseJson;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
        throw UnauthorisedException(response.body.toString());
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
      default:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode: ${response.statusCode}',
        );
    }
  }

  dynamic _loginresponse(Response response) {
    switch (response.statusCode) {
      case 200:
        String myres = utf8.decode(response.bodyBytes);
        var responseJson = json.decode(myres);
        return responseJson;
      case 204:
        return response;
      case 205:
        return response;
      case 201:
        String myres = utf8.decode(response.bodyBytes);
        var responseJson = json.decode(myres);
        return responseJson;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
        String myres = utf8.decode(response.bodyBytes);
        var responseJson = json.decode(myres);
        return responseJson;
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode: ${response.statusCode}',
        );
      default:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode: ${response.statusCode}',
        );
    }
  }



  Response _responseAll(Response response) {
    // print(response.body);
    switch (response.statusCode) {
      case 200:
        return response;
      case 204:
        return response;
      case 205:
        return response;
      case 201:
        return response;
      case 400:
        return response;
      case 401:
        throw UnauthorisedException(response.body.toString());
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
      default:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode: ${response.statusCode}',
        );
    }
  }

  Response _responsedata(Response response) {
    // print(response.body);
    switch (response.statusCode) {
      case 200:
        return response;
      case 204:
        return response;
      case 205:
        return response;
      case 201:
        return response;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
        throw UnauthorisedException(response.body.toString());
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
      default:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode: ${response.statusCode}',
        );
    }
  }

//  reset password
  Future<Response> resetPassword(Map body) async {
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/user/password/new_reset/");

    try {
      Response response = await post(
        url,
        body: body,
      ).timeout(Duration(seconds: timeout));
      // print(response.body);
      // print(response.statusCode);
      responseJson = response;
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<List<dynamic>?> fetchnotficationsattents() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await get(
        Uri.parse(
            "${baseParPays(pays!)}api/notifications_demande_retrait/list/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<Response> retireAnnuler(Map body) async {
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/func/client_digiPay/annuler-retrait/");
    String? token = await storage.read(key: "token");

    try {
      Response response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));
      // print(response.body);
      // print(response.statusCode);
      responseJson = response;
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> developedBy() async {
    var responseJson;
    try {
      final response = await get(
        Uri.parse(
            "https://bcipay-mr-dev.nw.r.appspot.com/api/developpe_par_value/"),
      ).timeout(Duration(seconds: timeout));

      responseJson = _response(response);
    } catch (e) {
      // print(e);
    }
    return responseJson;
  }

  Future<Response> changeLangue(Map body) async {
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/change_user_language");
    String? token = await storage.read(key: "token");

    try {
      Response response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));
      // print(response.body);
      // print(response.statusCode);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> retraitgab(double montant) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/clientdigiPay-and-vendor/retrait_par_gab/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "id": myid,
          "montant": montant,
          "type_comptable": "05",
          "role": "CLIENT"
        }),
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> listeCartesRecharge(String? operateur) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    try {
      final response = await post(
        Uri.parse(
            "${baseParPays(pays!)}api/bmi/client_digiPay/list/carte-credit/"),
        headers: {"Authorization": "JWT $token"},
        body: jsonEncode({
          "operateur": operateur,
        }),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> rechargespackageTel(
      int montant, String? tel, String? operateur, String? service) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/payement/carte-credit/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "operateur": operateur,
            "tel": tel,
            "montant": montant,
            "client": int.parse(myid!),
            "service": service
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> checkreferencesnde(String? reference) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/bmi/client_digiPay/get-facture/snde/$reference/");
    try {
      var response = await get(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> sndepayment(
    double? montant,
    String? ref,
    int? id,
    double? soldeFacture,
    String? adresse,
  ) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/bmi/client_digiPay/payement/snde/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "client": int.parse(myid!),
            "facturier": id,
            "montant": montant,
            "reference": ref,
            "type_comptable": "16",
            "solde": soldeFacture,
            "adresse": adresse
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  consultetat(String? service, String? reference) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/get-facture/etat/");
    print({"service": service, "reference": reference});
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"service": service, "reference": reference}))
          .timeout(Duration(seconds: timeout));
      print(response.statusCode);
      print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> payementetat(
      String? service, String? reference, double? montant, int? id) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url =
        Uri.parse("${baseParPays(pays!)}api/bmi/client_digiPay/payement/etat/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "client": int.parse(myid!),
            "facturier": id,
            "montant": montant,
            "reference": reference,
            "type_comptable": "16",
            "service": service
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic>? checkagent() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/user/client_digiPay/check_agent_virtuel/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> agentupdate(String? telephone, double? longitude,
      double? latitude, String? adresse, bool online) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/user/client_digiPay/update_fields/");
    try {
      var response = await put(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "tel_agent_virtuel": telephone,
            "latitude": latitude,
            "logitude": longitude,
            "adresse": adresse,
            "online": online
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> fetchagents() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/agent_virtuel/list/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
      // print(response.statusCode);
      // print(response.body);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> retraitvirtuelconsult(
    String? telephone,
    double? montant,
    String? code,
  ) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/transaction/retrait-list-agent-virtuel/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "telephone": telephone,
            "montant": montant,
            "code_confirmation": code,
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> retraitvirtuel(int? retraitId, String? code) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/clientdigiPay-and-vendor/retrait-agent-virtuel/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "retrait_id": retraitId,
            "code_confirmation": code,
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> historiquesReference(String? facturierId) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await post(
          Uri.parse(
              "${baseParPays(pays!)}api/func/liste_paiements_par_facturier/"),
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "client": myid!,
            "facturier": facturierId,
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<List<dynamic>?> listDernierBeneficiaire(String? type) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    var responseJson;
    try {
      final response = await post(
          Uri.parse(
              "${baseParPays(pays!)}api/func/liste_derniers_beneficiaires/"),
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "client": myid!,
            "type": type,
          })).timeout(Duration(seconds: timeout));
      responseJson = _response(response);
      // print(response.statusCode);
      // print(response.body);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> rechargeTelAutresPays(
      int montant, String? tel, String? operateur, String? service) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/payement/carte-credit/");
    try {
      var response = await post(url,
          headers: {
            "Authorization": "JWT $token",
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: jsonEncode({
            "operateur": operateur,
            "tel": tel,
            "montant": montant,
            "client": int.parse(myid!),
            "service": service
          })).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic>? consultGuineeInfo(Map body) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    dynamic responseJson;
    try {
      final response = await post(
              Uri.parse("${baseParPays(pays!)}/api/bmi/client_digiPay/vignette/consultation-infos/"),
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));
      print(response.statusCode);
      print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> consultVignetteGuinee(Map body) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}/api/bmi/client_digiPay/vignette/consultation/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<dynamic> paiementVignetteGuinee(Map body) async {
    String? token = await storage.read(key: "token");
    String? myid = await (storage.read(key: "id"));
    String? pays = await storage.read(key: 'country');
    body['client'] = int.parse(myid!);
    // print(body);

    var responseJson;
    var url = Uri.parse(
        "${baseParPays(pays!)}api/bmi/client_digiPay/vignette/paiement/");
    try {
      var response = await post(url,
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body))
          .timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _response(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<Response> fetchcompte() async {
    String? token = await storage.read(key: "token");
    String? id = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    Response responseJson;
    try {
      final response = await post(
          Uri.parse("${baseParPays(pays!)}api/core_banking/check_infos_default_account/"),
          headers: {"Authorization": "JWT $token"},
          body: jsonEncode({"id": id})).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _responsedata(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<Response> comptewallet(double montant, String? note) async {
    String? token = await storage.read(key: "token");
    String? id = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    Response responseJson;
    try {
      final response = await post(
        Uri.parse(
            "${baseParPays(pays!)}api/core_banking/transfert_compte_wallet/"),
        headers: {"Authorization": "JWT $token"},
        body: jsonEncode({"id": id, "montant": montant, "note": note}),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<Response> walletcompte(double montant, String? note) async {
    String? token = await storage.read(key: "token");
    String? id = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');

    Response responseJson;
    try {
      final response = await post(
        Uri.parse(
            "${baseParPays(pays!)}api/core_banking/transfert_wallet_compte/"),
        headers: {"Authorization": "JWT $token"},
        body: jsonEncode({"id": id, "montant": montant, "note": note}),
      ).timeout(Duration(seconds: timeout));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<Response> searchTransaction(String code) async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    // print(startDate);
    // print(endDate);

    try {
      final response = await post(
              Uri.parse("${baseParPays(pays!)}api/transaction/filter/code_transaction/"),
              headers: {
                "Authorization": "JWT $token",
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode({"code_transaction": code}))
          .timeout(const Duration(seconds: 70));
      // print(response.statusCode);
      // print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<dynamic> listeBanques() async {
    String? token = await storage.read(key: "token");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    try {
      final response = await get(
        Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/ins_list/"),
        headers: {"Authorization": "JWT $token"},
      ).timeout(Duration(seconds: timeout));
      print(response.statusCode);
      print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }
    return responseJson;
  }

  Future<Response> envoiClientInteroperable(
      double montant, String? tel, String? bank, String? typeComptable) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/envoie-interoperable-outbound/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "sender": "$myid",
          "tel": tel,
          "montant": montant,
          "id_banque": bank,
          "type_comptable": typeComptable
        }),
      ).timeout(Duration(seconds: timeout));
      print(response.statusCode);
      print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<Response> retraitClientInteroperable(double montant, String? tel,
      String? bank, String? typeComptable, bool isScanned) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/client_fast_retrait_outbound/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "sender": "$myid",
          "tel": tel,
          "montant": montant,
          "id_banque": bank,
          "type_comptable": typeComptable,
          "is_scanned": isScanned
        }),
      ).timeout(Duration(seconds: timeout));
      print(response.statusCode);
      print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }

  Future<Response> paiementClientInteroperable(double montant, String? tel,
      String? bank, String? typeComptable, bool isScanned) async {
    String? token = await storage.read(key: "token");
    String? myid = await storage.read(key: "id");
    String? pays = await storage.read(key: 'country');
    Response responseJson;
    var url = Uri.parse("${baseParPays(pays!)}api/func/client_digiPay/client_fast_payement_outbound/");
    try {
      var response = await post(
        url,
        headers: {
          "Authorization": "JWT $token",
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          "sender": "$myid",
          "tel": tel,
          "montant": montant,
          "id_banque": bank,
          "type_comptable": typeComptable,
          "is_scanned": isScanned
        }),
      ).timeout(Duration(seconds: timeout));
      print(response.statusCode);
      print(response.body);
      responseJson = _responseAll(response);
    } on BadRequestException {
      throw Failure();
    } on UnauthorisedException {
      throw Failure(code: 1);
    } on FetchDataException {
      throw Failure();
    } on TimeoutException {
      throw Failure();
    }

    return responseJson;
  }


}
