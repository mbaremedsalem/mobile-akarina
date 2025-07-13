import 'package:flutter/material.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class RecommendationList extends StatefulWidget {
  const RecommendationList({super.key});

  @override
  State<RecommendationList> createState() => _RecommendationListState();
}

class _RecommendationListState extends State<RecommendationList> {
  late Future<List<dynamic>> _futureRecommendations;
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
    
    _futureRecommendations = NetworkService().fetchRecommendedResidences();
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
    
    return FutureBuilder<List<dynamic>>(
      future: _futureRecommendations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(child: Text(getTranslated(context, "Aucune recommandation trouvée.") ?? "Aucune recommandation trouvée."));
        }
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: ListTile(
                leading: item['images'] != null && item['images'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['images'][0]['image'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home, color: Colors.grey),
                      ),
                title: Text(item['adresse'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(item['ratings'] ?? '0'),
                        const SizedBox(width: 8),
                        const Icon(Icons.attach_money, color: Colors.green, size: 16),
                        Text(item['montant']?.toString() ?? item['loyer_mensuel']?.toString() ?? ''),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                onTap: () {
                  // Naviguer vers la page de détail si besoin
                },
              ),
            );
          },
        );
      },
    );
  }
} 