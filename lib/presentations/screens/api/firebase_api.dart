import 'package:akarina/data/data_providers/network_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    
    // Obtenez le token FCM
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Envoyez le token FCM au backend
    sendFCMTokenToBackend(fcmToken);

    // Écoutez les messages FCM lorsqu'ils sont reçus
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  void sendFCMTokenToBackend(String? fcmToken) async {
     final storage1 = NetworkService().storage;
     String? token = await storage1.read(key: "access");
    if (fcmToken != null) {
      var response = await http.post(
        Uri.parse('http://192.168.0.230:8000/user/update_fcm_token/'),
        headers: {
          'Authorization': 'Bearer $token',  // Remplacez par le token d'accès utilisateur
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('FCM Token mis à jour avec succès');
      } else {
        print('Erreur lors de l\'envoi du FCM Token');
      }
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    // Logique pour afficher la notification dans l'application Flutter
    print("Notification reçue: ${message.notification?.title}, ${message.notification?.body}");
  }
}
