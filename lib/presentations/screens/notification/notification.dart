import 'package:flutter/material.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Vérifier la connectivité internet d'abord
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });
    
    if (!hasConnection) {
      return; // Ne pas charger les données si pas de connexion
    }
    
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Simuler un appel API
      await Future.delayed(const Duration(seconds: 1));
      
      // Données d'exemple
      final mockData = [
        {
          'id': 1,
          'title': 'Nouvelle propriété disponible',
          'message': 'Un nouvel appartement a été ajouté dans votre zone de recherche.',
          'time': 'Il y a 5 minutes',
          'isRead': false,
          'type': 'property',
        },
        {
          'id': 2,
          'title': 'Prix mis à jour',
          'message': 'Le prix de la propriété que vous surveillez a été mis à jour.',
          'time': 'Il y a 1 heure',
          'isRead': true,
          'type': 'price_update',
        },
        {
          'id': 3,
          'title': 'Nouveau message',
          'message': 'Vous avez reçu un nouveau message de l\'agent immobilier.',
          'time': 'Il y a 2 heures',
          'isRead': false,
          'type': 'message',
        },
      ];

      setState(() {
        notifications = mockData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher la page d'erreur de connexion si pas de connexion internet
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          setState(() {
            hasInternetConnection = hasConnection;
          });
          
          if (hasConnection) {
            _initializeData();
          }
        },
      );
    }
    
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
      ),
      body: RefreshableWidget(
        onRefresh: () async {
          await fetchNotifications();
        },
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
                      final notification = notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () {
                          // Marquer comme lu
                          setState(() {
                            notification['isRead'] = true;
                          });
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;

    IconData getIconForType(String type) {
      switch (type) {
        case 'property':
          return Icons.home;
        case 'price_update':
          return Icons.trending_up;
        case 'message':
          return Icons.message;
        default:
          return Icons.notifications;
      }
    }

    Color getColorForType(String type) {
      switch (type) {
        case 'property':
          return Colors.blue;
        case 'price_update':
          return Colors.green;
        case 'message':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

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
            color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
            border: isRead 
                ? null 
                : Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getColorForType(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  getIconForType(type),
                  color: getColorForType(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
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
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification['time'],
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
}