// lib/services/fcm_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:akarina/data/models/app_notification.dart';
import 'package:akarina/data/services/navigation_service.dart';
import 'package:akarina/data/services/notification_store.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';

const String _kDeviceTokensUrl = 'https://admin-akarina.akarina.shop/api/device-tokens/';
const String _kDeviceTokensUnregisterUrl =
    'https://admin-akarina.akarina.shop/api/device-tokens/unregister/';
const String _kNotificationChannelId = 'real_estate_channel';
const int _kNotificationColor = 0xFF2A92CF;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

/// Valeur du champ `plateforme` attendue par /api/device-tokens/.
String get _kPlateforme => _isIOS ? 'ios' : 'android';

/// Extrait l'identifiant du bien (référence ou id) depuis le payload data
/// d'une notification FCM, quelle que soit la clé utilisée côté serveur.
String? _referenceFromData(Map<String, dynamic> data) {
  for (final key in ['reference', 'bien_reference', 'bien_id', 'id']) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final _storage = FlutterSecureStorage();

  static String? _fcmToken;

  static Future<void> initialize() async {
    await NotificationStore.refreshUnreadCount();
    await _initializeLocalNotifications();

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Statut autorisation notifications: ${settings.authorizationStatus}');

    // Sur Android, le jeton FCM peut être obtenu et enregistré même si la
    // permission d'affichage des notifications est refusée (celle-ci ne
    // contrôle que la bannière système) — donc on ne bloque plus dessus.
    await _getAndRegisterToken();
    _setupForegroundMessages();
    _setupBackgroundMessages();
    _setupTokenRefresh();
    await _handleInitialMessage();
  }

  static Future<String?> getToken() async {
    return _fcmToken ?? await _storage.read(key: 'fcm_token');
  }

  static Future<void> _getAndRegisterToken() async {
    try {
      // Sur iOS, FCM ne peut délivrer de jeton qu'une fois le jeton APNs
      // reçu d'Apple (quelques instants après le démarrage). Sans APNs
      // (simulateur, capacité « Push Notifications » absente), on abandonne
      // proprement : onTokenRefresh prendra le relais s'il arrive plus tard.
      if (_isIOS && !await _waitForApnsToken()) {
        debugPrint('⚠️ Jeton APNs indisponible : notifications iOS inactives sur cet appareil');
        return;
      }
      String? token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      if (token != null) {
        _fcmToken = token;
        await _storage.write(key: 'fcm_token', value: token);
        await _registerTokenWithServer(token);
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération token FCM: $e');
    }
  }

  static Future<bool> _waitForApnsToken() async {
    for (var i = 0; i < 10; i++) {
      final apns = await _firebaseMessaging.getAPNSToken();
      if (apns != null) {
        debugPrint('🍏 Jeton APNs reçu');
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  static Future<void> _registerTokenWithServer(String token) async {
    try {
      // L'API /api/device-tokens/ n'exige pas d'authentification : tout
      // appareil (connecté ou non, avec ou sans compte) doit pouvoir
      // recevoir les notifications de diffusion générale. On joint quand
      // même le jeton admin s'il existe pour permettre au backend
      // d'associer l'appareil à un compte quand c'est possible.
      final authToken = await _storage.read(key: 'admin_token');
      final response = await http.post(
        Uri.parse(_kDeviceTokensUrl),
        headers: {
          if (authToken != null) 'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token, 'plateforme': _kPlateforme}),
      );
      final alreadyRegistered = response.statusCode == 400 && response.body.contains('existe déjà');
      if (response.statusCode == 200 || response.statusCode == 201 || alreadyRegistered) {
        debugPrint('✅ Token FCM enregistré sur le serveur');
      } else {
        debugPrint('⚠️ Erreur enregistrement token FCM: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Serveur inaccessible (enregistrement FCM): $e');
    }
  }

  /// À appeler juste après une connexion réussie : le token FCM a pu être
  /// obtenu avant que l'utilisateur ne soit authentifié.
  static Future<void> registerTokenAfterLogin() async {
    final token = _fcmToken ?? await _storage.read(key: 'fcm_token');
    if (token != null) {
      await _registerTokenWithServer(token);
    }
  }

  /// À appeler avant la suppression du token de session (avant `_logout`),
  /// pour que le serveur arrête d'envoyer des notifications à cet appareil.
  static Future<void> unregisterToken() async {
    try {
      final token = _fcmToken ?? await _storage.read(key: 'fcm_token');
      final authToken = await _storage.read(key: 'admin_token');
      if (token != null && authToken != null) {
        await http.post(
          Uri.parse(_kDeviceTokensUnregisterUrl),
          headers: {
            'Authorization': 'Token $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': token}),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur désenregistrement token FCM: $e');
    }
  }

  static void _setupForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notif = await _persist(message);
      await _showLocalNotification(message, notif);
    });
  }

  static void _setupBackgroundMessages() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Notification système tapée alors que l'app était en arrière-plan.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await NotificationStore.markRead(_notificationId(message));
      _navigateToBien(message.data);
    });
  }

  /// Démarrage à froid de l'app via un tap sur la notification.
  static Future<void> _handleInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message == null) return;
    await NotificationStore.markRead(_notificationId(message));
    // Laisse le temps à la navigation racine de se monter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToBien(message.data);
    });
  }

  static void _setupTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _storage.write(key: 'fcm_token', value: newToken);
      _registerTokenWithServer(newToken);
    });
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _kNotificationChannelId,
        'Notifications Immobilières',
        description: 'Notifications pour les biens immobiliers',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static String _notificationId(RemoteMessage message) =>
      message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Construit l'entrée d'historique à partir du message et la sauvegarde ;
  /// renvoie l'objet pour l'affichage immédiat de la notification système.
  static Future<AppNotification> _persist(RemoteMessage message) async {
    final data = message.data;
    final notif = AppNotification(
      id: _notificationId(message),
      title: message.notification?.title ?? data['title']?.toString() ?? 'Agharina',
      body: message.notification?.body ?? data['body']?.toString() ?? '',
      reference: _referenceFromData(data),
      imageUrl: message.notification?.android?.imageUrl ?? data['image']?.toString(),
      receivedAt: DateTime.now(),
    );
    await NotificationStore.add(notif);
    return notif;
  }

  static Future<void> _showLocalNotification(RemoteMessage message, AppNotification notif) async {
    final unread = NotificationStore.unreadCountNotifier.value;

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _kNotificationChannelId,
      'Agharina - Notifications Immobilières',
      channelDescription: 'Notifications pour les biens immobiliers',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
      color: const Color(_kNotificationColor),
      number: unread,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(notif.body),
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: null,
      ),
    );

    await _localNotifications.show(
      id: notif.id.hashCode & 0x7fffffff,
      title: notif.title,
      body: notif.body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode({'_id': notif.id, ...message.data}),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final id = data['_id']?.toString();
      if (id != null) NotificationStore.markRead(id);
      _navigateToBien(data);
    } catch (e) {
      debugPrint('❌ Erreur parsing payload notification: $e');
    }
  }

  static void _navigateToBien(Map<String, dynamic> data) {
    final reference = _referenceFromData(data);
    if (reference == null) return;
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => ImmobDetails(reference: reference)));
  }
}


// ✅ Handler pour les messages en background (isolate séparé : pas d'accès
// à l'état de l'app principale, juste au stockage et aux notifications
// locales).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  final notif = AppNotification(
    id: id,
    title: message.notification?.title ?? data['title']?.toString() ?? 'Agharina',
    body: message.notification?.body ?? data['body']?.toString() ?? '',
    reference: _referenceFromData(data),
    imageUrl: message.notification?.android?.imageUrl ?? data['image']?.toString(),
    receivedAt: DateTime.now(),
  );
  await NotificationStore.add(notif);
  final unread = await NotificationStore.refreshUnreadCount();

  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await localNotifications.initialize(settings: initializationSettings);

  final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    _kNotificationChannelId,
    'Agharina - Notifications Immobilières',
    channelDescription: 'Notifications pour les biens immobiliers',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_notification',
    largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
    color: const Color(_kNotificationColor),
    number: unread,
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await localNotifications.show(
    id: id.hashCode & 0x7fffffff,
    title: notif.title,
    body: notif.body,
    notificationDetails: platformChannelSpecifics,
    payload: jsonEncode({'_id': notif.id, ...data}),
  );
}
