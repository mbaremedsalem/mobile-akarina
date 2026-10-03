import 'package:flutter/material.dart';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/home/home.dart';
import 'package:akarina/presentations/screens/home/map_home.dart';

/// Accueil de l'application : bascule entre la carte (vue par défaut) et la
/// liste classique par catégories, comme sur Zillow.
///
/// Les deux vues restent montées dans un [IndexedStack] : passer de l'une à
/// l'autre ne relance ni le chargement des biens ni celui de la carte.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _afficheCarte = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _afficheCarte ? 0 : 1,
          children: [
            MapHome(onSwitchToList: () => setState(() => _afficheCarte = false)),
            const Home(),
          ],
        ),
        if (!_afficheCarte) _buildBoutonCarte(),
      ],
    );
  }

  Widget _buildBoutonCarte() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Center(
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(26),
          elevation: 6,
          shadowColor: Colors.black45,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => setState(() => _afficheCarte = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    getTranslated(context, 'Carte')!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit indicateur réutilisable si vous souhaitez la même bascule ailleurs.
class MapListToggle extends StatelessWidget {
  final bool carteActive;
  final ValueChanged<bool> onChanged;

  const MapListToggle({
    super.key,
    required this.carteActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(context, Icons.map_outlined, 'Carte', carteActive, true),
          _buildSegment(context, Icons.view_list, 'Liste', !carteActive, false),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    IconData icone,
    String label,
    bool actif,
    bool valeur,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onChanged(valeur),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? pcolor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 17, color: actif ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              getTranslated(context, label)!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actif ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
