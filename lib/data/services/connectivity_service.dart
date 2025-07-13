import 'dart:io';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static const String _testUrl = 'https://www.google.com';
  static const Duration _timeout = Duration(seconds: 5);

  /// Vérifie si l'appareil a une connexion internet active
  static Future<bool> hasInternetConnection() async {
    try {
      final response = await http
          .get(Uri.parse(_testUrl))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } on SocketException {
      // Pas de connexion réseau
      return false;
    } catch (e) {
      // Autres erreurs (timeout, etc.)
      return false;
    }
  }

  /// Vérifie la connectivité avec un timeout personnalisé
  static Future<bool> hasInternetConnectionWithTimeout(Duration timeout) async {
    try {
      final response = await http
          .get(Uri.parse(_testUrl))
          .timeout(timeout);
      
      return response.statusCode == 200;
    } on SocketException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie la connectivité vers une URL spécifique
  static Future<bool> hasConnectionToUrl(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(_timeout);
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } on SocketException {
      return false;
    } catch (e) {
      return false;
    }
  }
} 