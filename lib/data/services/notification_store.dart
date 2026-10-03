import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:akarina/data/models/app_notification.dart';

/// Historique local des notifications reçues (FCM) + compteur de non-lues.
///
/// Persisté dans le secure storage pour survivre aux redémarrages de l'app,
/// et lisible depuis l'isolate d'arrière-plan de Firebase Messaging (qui n'a
/// pas accès à l'état de l'app principale).
class NotificationStore {
  static const _storageKey = 'app_notifications';
  static const _maxItems = 200;
  static const _storage = FlutterSecureStorage();

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<List<AppNotification>> getAll() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<AppNotification> items) async {
    final trimmed = items.take(_maxItems).toList();
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(AppNotification notification) async {
    final items = await getAll();
    items.insert(0, notification);
    await _saveAll(items);
    await refreshUnreadCount();
  }

  static Future<void> markRead(String id) async {
    final items = await getAll();
    final updated = [
      for (final n in items) n.id == id ? n.copyWith(read: true) : n,
    ];
    await _saveAll(updated);
    await refreshUnreadCount();
  }

  static Future<void> markAllRead() async {
    final items = await getAll();
    final updated = [for (final n in items) n.copyWith(read: true)];
    await _saveAll(updated);
    await refreshUnreadCount();
  }

  /// Recharge le compteur depuis le stockage. À appeler au démarrage de
  /// l'app et à chaque retour au premier plan, car l'isolate d'arrière-plan
  /// FCM ne peut pas mettre à jour [unreadCountNotifier] directement.
  static Future<int> refreshUnreadCount() async {
    final items = await getAll();
    final count = items.where((n) => !n.read).length;
    unreadCountNotifier.value = count;
    return count;
  }
}
