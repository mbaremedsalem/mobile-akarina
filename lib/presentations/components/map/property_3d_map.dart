import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/map/price_marker.dart';
import 'package:akarina/presentations/constants/constants.dart';

/// Carte de localisation d'un bien avec vue 3D inclinée.
///
/// En mode 3D la caméra bascule à 60° sur l'imagerie satellite : les bâtiments
/// extrudés et le relief de Google apparaissent là où la couverture existe,
/// sinon l'imagerie aérienne reste inclinée. Un bouton permet de revenir à la
/// vue 2D classique, de pivoter autour du bien et de passer en plein écran.
class Property3DMap extends StatefulWidget {
  final LatLng position;
  final String titre;

  /// Affiche un avertissement quand la position est déduite du quartier et non
  /// des coordonnées réelles du bien.
  final bool positionApproximative;

  /// Hauteur de la carte ; `null` pour occuper tout l'espace disponible
  /// (utilisé par le mode plein écran).
  final double? hauteur;

  /// Masque le bouton plein écran (déjà en plein écran).
  final bool pleinEcran;

  const Property3DMap({
    super.key,
    required this.position,
    required this.titre,
    this.positionApproximative = false,
    this.hauteur,
    this.pleinEcran = false,
  });

  @override
  State<Property3DMap> createState() => _Property3DMapState();
}

class _Property3DMapState extends State<Property3DMap> {
  static const double _tilt3D = 62;
  static const double _zoom3D = 18.5;
  static const double _zoom2D = 15.5;

  GoogleMapController? _controller;
  bool _mode3D = true;
  double _bearing = 20;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  CameraPosition get _camera => CameraPosition(
        target: widget.position,
        zoom: _mode3D ? _zoom3D : _zoom2D,
        tilt: _mode3D ? _tilt3D : 0,
        bearing: _mode3D ? _bearing : 0,
      );

  void _appliquerCamera() {
    _controller?.animateCamera(CameraUpdate.newCameraPosition(_camera));
  }

  void _basculerMode() {
    setState(() => _mode3D = !_mode3D);
    _appliquerCamera();
  }

  void _pivoter(double degres) {
    if (!_mode3D) return;
    setState(() => _bearing = (_bearing + degres) % 360);
    _appliquerCamera();
  }

  void _ouvrirPleinEcran() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              widget.titre.isEmpty ? _t('Localisation du maison') : widget.titre,
              style: const TextStyle(color: kBlackColor, fontSize: 16),
            ),
            iconTheme: const IconThemeData(color: kBlackColor),
            backgroundColor: Colors.white,
          ),
          body: Property3DMap(
            position: widget.position,
            titre: widget.titre,
            positionApproximative: widget.positionApproximative,
            pleinEcran: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carte = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _camera,
          onMapCreated: (controller) {
            _controller = controller;
            // Certaines plateformes ignorent le tilt de la caméra initiale :
            // on le réapplique une fois la carte prête.
            WidgetsBinding.instance.addPostFrameCallback((_) => _appliquerCamera());
          },
          mapType: _mode3D ? MapType.hybrid : MapType.normal,
          buildingsEnabled: true,
          markers: {
            Marker(
              markerId: const MarkerId('bien'),
              position: widget.position,
              infoWindow: InfoWindow(title: widget.titre),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          // Sans ce recognizer, la carte imbriquée dans la page défilante ne
          // reçoit pas les gestes de rotation / inclinaison.
          gestureRecognizers: kMapGestureRecognizers,
          onCameraMove: (position) => _bearing = position.bearing,
        ),
        Positioned(top: 10, left: 10, child: _buildBasculeMode()),
        Positioned(
          bottom: 10,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_mode3D) _buildBoutonsRotation(),
              if (!widget.pleinEcran) ...[
                const SizedBox(height: 8),
                _buildBoutonRond(
                  icone: Icons.fullscreen,
                  tooltip: _t('Plein écran'),
                  onTap: _ouvrirPleinEcran,
                ),
              ],
            ],
          ),
        ),
        if (widget.positionApproximative)
          Positioned(bottom: 10, left: 10, child: _buildAvertissement()),
      ],
    );

    if (widget.hauteur == null) return carte;

    return Container(
      height: widget.hauteur,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: carte,
      ),
    );
  }

  Widget _buildBasculeMode() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _basculerMode,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _mode3D ? Icons.threed_rotation : Icons.map_outlined,
                size: 17,
                color: pcolor,
              ),
              const SizedBox(width: 6),
              Text(
                _mode3D ? '3D' : '2D',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: pcolor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoutonsRotation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBoutonRond(
          icone: Icons.rotate_left,
          tooltip: _t('Pivoter à gauche'),
          onTap: () => _pivoter(-45),
        ),
        const SizedBox(width: 8),
        _buildBoutonRond(
          icone: Icons.rotate_right,
          tooltip: _t('Pivoter à droite'),
          onTap: () => _pivoter(45),
        ),
      ],
    );
  }

  Widget _buildBoutonRond({
    required IconData icone,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icone, size: 19, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildAvertissement() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.shade700.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            _t('Position approximative'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
