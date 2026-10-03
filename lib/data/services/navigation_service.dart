import 'package:flutter/material.dart';

/// Clé de navigation partagée, utilisée par [MaterialApp] et par les services
/// statiques (ex: FCMService) qui doivent naviguer en dehors de l'arbre de
/// widgets (tap sur une notification reçue en arrière-plan par exemple).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
