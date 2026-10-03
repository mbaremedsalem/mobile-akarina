import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fabrique les pastilles de prix affichées sur la carte, à la façon de Zillow.
///
/// Les icônes sont dessinées au canvas puis mises en cache : une même
/// combinaison (texte, sélection, disponibilité, densité d'écran) n'est
/// rasterisée qu'une seule fois, même avec 150 marqueurs à l'écran.
class PriceMarkerFactory {
  PriceMarkerFactory._internal();
  static final PriceMarkerFactory _instance = PriceMarkerFactory._internal();
  factory PriceMarkerFactory() => _instance;

  final Map<String, BitmapDescriptor> _cache = {};

  /// Pastille de prix d'un bien.
  Future<BitmapDescriptor> build({
    required String label,
    required bool selected,
    required bool available,
    required Color couleur,
    required double devicePixelRatio,
  }) {
    final key = 'p|$label|$selected|$available|$couleur|$devicePixelRatio';
    return _cached(
      key,
      () => _drawPill(
        label: label,
        selected: selected,
        available: available,
        couleur: couleur,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }

  /// Pastille ronde représentant un groupe de biens trop proches pour être
  /// distingués au niveau de zoom courant.
  Future<BitmapDescriptor> buildCluster({
    required int count,
    required Color couleur,
    required double devicePixelRatio,
  }) {
    final key = 'c|$count|$couleur|$devicePixelRatio';
    return _cached(
      key,
      () => _drawCluster(
        count: count,
        couleur: couleur,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }

  Future<BitmapDescriptor> _cached(
    String key,
    Future<BitmapDescriptor> Function() build,
  ) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    final built = await build();
    _cache[key] = built;
    return built;
  }

  Future<BitmapDescriptor> _drawPill({
    required String label,
    required bool selected,
    required bool available,
    required Color couleur,
    required double devicePixelRatio,
  }) async {
    final scale = devicePixelRatio.clamp(1.0, 3.0);
    final fontSize = (selected ? 15.0 : 13.0) * scale;
    final paddingH = 12.0 * scale;
    final paddingV = 7.0 * scale;
    final pointeH = 6.0 * scale;
    final bordure = (selected ? 2.5 : 1.5) * scale;

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : (available ? couleur : Colors.grey[600]),
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final largeur = painter.width + paddingH * 2;
    final hauteurPill = painter.height + paddingV * 2;
    final hauteur = hauteurPill + pointeH;
    // Marge pour que l'ombre ne soit pas rognée par les bords de l'image.
    final marge = 4.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final rect = Rect.fromLTWH(marge, marge, largeur, hauteurPill);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(hauteurPill / 2));

    final fond = Paint()
      ..color = selected ? couleur : Colors.white
      ..style = PaintingStyle.fill;
    final contour = Paint()
      ..color = selected ? Colors.white : (available ? couleur : Colors.grey.shade400)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bordure;

    // Ombre portée.
    canvas.drawRRect(
      rrect.shift(Offset(0, 1.5 * scale)),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * scale),
    );

    // Pointe triangulaire sous la pastille.
    final centreX = marge + largeur / 2;
    final pointe = Path()
      ..moveTo(centreX - pointeH * 0.8, marge + hauteurPill - 1)
      ..lineTo(centreX, marge + hauteurPill + pointeH)
      ..lineTo(centreX + pointeH * 0.8, marge + hauteurPill - 1)
      ..close();
    canvas.drawPath(pointe, fond);
    canvas.drawPath(pointe, contour..strokeWidth = bordure * 0.8);

    canvas.drawRRect(rrect, fond);
    canvas.drawRRect(rrect, contour..strokeWidth = bordure);

    painter.paint(
      canvas,
      Offset(marge + paddingH, marge + paddingV),
    );

    return _toBitmap(
      recorder,
      (largeur + marge * 2).ceil(),
      (hauteur + marge * 2).ceil(),
    );
  }

  Future<BitmapDescriptor> _drawCluster({
    required int count,
    required Color couleur,
    required double devicePixelRatio,
  }) async {
    final scale = devicePixelRatio.clamp(1.0, 3.0);
    final label = count > 99 ? '99+' : '$count';
    final rayon = (count >= 50 ? 26.0 : count >= 10 ? 23.0 : 20.0) * scale;
    final marge = 5.0 * scale;
    final taille = (rayon + marge) * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final centre = Offset(taille / 2, taille / 2);

    canvas.drawCircle(
      centre.translate(0, 1.5 * scale),
      rayon,
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * scale),
    );
    canvas.drawCircle(centre, rayon, Paint()..color = couleur.withOpacity(0.25));
    canvas.drawCircle(centre, rayon * 0.78, Paint()..color = couleur);
    canvas.drawCircle(
      centre,
      rayon * 0.78,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13.0 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );

    return _toBitmap(recorder, taille.ceil(), taille.ceil());
  }

  Future<BitmapDescriptor> _toBitmap(
    ui.PictureRecorder recorder,
    int largeur,
    int hauteur,
  ) async {
    final image = await recorder.endRecording().toImage(largeur, hauteur);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: largeur.toDouble(),
      height: hauteur.toDouble(),
    );
  }
}

/// Charge un style de carte épuré (routes et quartiers lisibles, points
/// d'intérêt commerciaux masqués) pour que les pastilles de prix ressortent.
class MapStyle {
  static const String epure = '''
[
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.attraction","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e7f5"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f5f5f3"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#dcecc9"}]}
]
''';
}

/// Empêche la carte de « voler » les gestes verticaux quand elle est intégrée
/// dans une liste défilante (page détails).
final Set<Factory<OneSequenceGestureRecognizer>> kMapGestureRecognizers = {
  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
};
