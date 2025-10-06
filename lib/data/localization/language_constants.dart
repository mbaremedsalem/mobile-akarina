import 'package:akarina/data/localization/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



const String LAGUAGE_CODE = 'languageCode';

//languages code
const String FRENSH = 'fr';
const String ARABIC = 'ar';
const String ENGLISH = 'en';

Future<Locale> setLocale(String languageCode) async {
  final storage = new FlutterSecureStorage();
  await storage.write(key: LAGUAGE_CODE, value: languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  final storage = new FlutterSecureStorage();
  String languageCode = await storage.read(key: LAGUAGE_CODE) ?? "ca";
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case FRENSH:
      return Locale(FRENSH, 'CA');
    case ENGLISH:
      return Locale(ENGLISH, 'US');
    case ARABIC:
      return Locale(ARABIC, 'SA');

    default:
      return Locale(ARABIC, 'SA');
  }
}

String? getTranslated(BuildContext context, String? key) {
  if (Localization.of(context)!.translate(key) != null) {
    return Localization.of(context)!.translate(key);
  } else {
    return key;
  }
}

Future<String> getCurrentLanguage(BuildContext context) async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: LAGUAGE_CODE) ?? ARABIC; // Retourne 'ar' par défaut
}

// Nouvelle fonction pour la direction du texte basée sur votre système
TextDirection getAppTextDirection(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == ARABIC ? TextDirection.rtl : TextDirection.ltr;
}
