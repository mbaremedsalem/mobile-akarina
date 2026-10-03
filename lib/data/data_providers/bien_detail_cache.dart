import 'package:akarina/data/data_providers/bien_service.dart';
import 'package:akarina/data/models/bien.dart';

/// Petit cache mémoire pour `BienService.fetchBienDetail`.
///
/// Les cartes de grille (voir [PropertyCard]) doivent savoir si un bien a une
/// vidéo, information absente de la réponse de liste `/api/biens/` — elles
/// appellent donc le détail une à une. Ce cache évite de refaire le même
/// appel à chaque reconstruction/défilement de la grille pour une même
/// référence, le temps de la session de l'app.
class BienDetailCache {
  BienDetailCache._();

  static final Map<String, Bien> _cache = {};
  static final Map<String, Future<Bien>> _inFlight = {};

  static Future<Bien> fetch(String reference) {
    final cached = _cache[reference];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[reference];
    if (pending != null) return pending;

    final future = BienService().fetchBienDetail(reference).then((bien) {
      _cache[reference] = bien;
      _inFlight.remove(reference);
      return bien;
    }, onError: (Object error) {
      _inFlight.remove(reference);
      throw error;
    });
    _inFlight[reference] = future;
    return future;
  }
}
