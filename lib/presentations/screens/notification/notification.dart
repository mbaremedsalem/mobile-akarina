import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/app_notification.dart';
import 'package:akarina/data/services/notification_store.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final items = await NotificationStore.getAll();
    if (!mounted) return;
    setState(() {
      notifications = items;
      isLoading = false;
    });
  }

  Future<void> _onTapNotification(AppNotification notif) async {
    await NotificationStore.markRead(notif.id);
    if (!mounted) return;
    setState(() {
      notifications = [
        for (final n in notifications) n.id == notif.id ? n.copyWith(read: true) : n,
      ];
    });
    final reference = notif.reference;
    if (reference != null && reference.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ImmobDetails(reference: reference)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar'
                ? IconBroken.Arrow___Right_2
                : IconBroken.Arrow___Left_2,
            color: kBlackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          getTranslated(context, "Notifications")!,
          style: TextStyle(color: kBlackColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (notifications.any((n) => !n.read))
            TextButton(
              onPressed: () async {
                await NotificationStore.markAllRead();
                if (!mounted) return;
                setState(() {
                  notifications = [for (final n in notifications) n.copyWith(read: true)];
                });
              },
              child: Text(getTranslated(context, "Tout marquer comme lu")!),
            ),
        ],
      ),
      body: RefreshableWidget(
        onRefresh: _load,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          getTranslated(context, "Aucune notification")!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getTranslated(context, "Vous n'avez pas encore de notifications")!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return NotificationCard(
                        notification: notif,
                        onTap: () => _onTapNotification(notif),
                      );
                    },
                  ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.read;
    final locale = Localizations.localeOf(context).languageCode;
    final time = DateFormat('dd/MM/yyyy • HH:mm', locale).format(notification.receivedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isRead ? Colors.white : pcolor.withOpacity(0.05),
            border: isRead ? null : Border.all(color: pcolor.withOpacity(0.2), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    notification.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  ),
                )
              else
                _fallbackIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isRead ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: pcolor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.home_work_rounded, color: pcolor, size: 20),
      );
}
