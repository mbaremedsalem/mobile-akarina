import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:akarina/business_logic/search/search_criteria.dart';
import 'package:akarina/presentations/layout/layout.dart';
import 'package:akarina/presentations/screens/immobillier/immobilier_screen.dart';

const String kAppModeStorageKey = 'app_mode';
const String kAppModeCeremonie = 'ceremonie';
const String kAppModeComplet = 'complet';

Future<String?> currentAppMode() => const FlutterSecureStorage().read(key: kAppModeStorageKey);

/// Entre directement dans l'app (mode courant de l'utilisateur), en vidant
/// la pile de navigation — utilisé pour "Passer" la connexion et pour une
/// connexion réussie.
Future<void> enterAppRoot(BuildContext context) async {
  final mode = await currentAppMode();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => buildAppModeRoot(mode)),
    (route) => false,
  );
}

/// Écran racine correspondant au mode choisi par l'utilisateur (voir
/// [applyAppMode]) : soit la page dédiée aux maisons de cérémonie, soit
/// l'application complète à 5 onglets.
Widget buildAppModeRoot(String? mode) {
  if (mode == kAppModeCeremonie) {
    return const ImmobilierScreen(
      title: "Maisons de cérémonie",
      initialCriteria: SearchCriteria(typeBien: 'ceremonie'),
      showExploreFullAppButton: true,
    );
  }
  return const Layout();
}

/// Enregistre le mode choisi et navigue vers l'écran racine correspondant
/// en vidant la pile de navigation — utilisé au premier choix (onboarding)
/// comme lors d'un changement ultérieur depuis Profil.
Future<void> applyAppMode(BuildContext context, String mode) async {
  await const FlutterSecureStorage().write(key: kAppModeStorageKey, value: mode);
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => buildAppModeRoot(mode)),
    (route) => false,
  );
}
