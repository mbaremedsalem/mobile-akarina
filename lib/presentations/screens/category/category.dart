import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/appartement/appartement.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class Category extends StatefulWidget {
  // final String token;

  const Category({super.key});

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> with TickerProviderStateMixin {
  Map<String, dynamic>? categories;
  List<dynamic>? recommendations;
  bool isLoading = true;
  bool isLoadingRecommendations = true;
  bool hasInternetConnection = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    
    await Future.wait([
      _loadCategories(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadCategories() async {
    NetworkService networkService = NetworkService();

    // Appeler la méthode fetchCategories en passant le token
    final fetchedCategories = await networkService.fetchCategories();

    if (fetchedCategories != null) {
      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
      _animationController.forward();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    NetworkService networkService = NetworkService();
    
    try {
      final fetchedRecommendations = await networkService.fetchRecommendations();
      if (fetchedRecommendations.isNotEmpty) {
      }
      setState(() {
        recommendations = fetchedRecommendations;
        isLoadingRecommendations = false;
      });
    } catch (e) {

      setState(() {
        isLoadingRecommendations = false;
      });
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
      backgroundColor: const Color(0xFFF8F9FA),
      


      body: isLoading
          ?  ImmobilierDetailSkeleton()
          : categories == null
              ? _buildErrorState()
              : _buildCategoriesList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            getTranslated(context, "Erreur lors de la récupération des catégories") ?? 
            "Erreur lors de la récupération des catégories",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: pcolor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(getTranslated(context, "Réessayer") ?? "Réessayer"),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // Section Recommandations
              if (recommendations != null && recommendations!.isNotEmpty) ...[
                Text(
                  getTranslated(context, "Recommandations") ?? "Recommandations",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kBlackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslated(context, "Découvrez nos meilleures propriétés") ?? 
                  "Découvrez nos meilleures propriétés",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecommendationsSection(),
                const SizedBox(height: 32),
              ],
              
              // Section Catégories
              Text(
                getTranslated(context, "Découvrez nos propriétés") ?? "Découvrez nos propriétés",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ),
            
              Text(
                getTranslated(context, "Choisissez la catégorie qui vous intéresse") ?? 
                "Choisissez la catégorie qui vous intéresse",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final categoryNames = [
                      "Appartement",
                      "Duplex", 
                      "Commercial",
                      "Terrain",
                      "Residentiel",
                      "Maisonceremonie"
                    ];
                    final categoryKeys = [
                      'appartements',
                      'duplexes',
                      'commerciaux',
                      'terrains',
                      'residentiels',
                      "maisonceremonie"
                    ];
                    
                    return _buildCategoryCard(
                      categoryNames[index],
                      categories![categoryKeys[index]],
                    );
                  },
                ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (isLoadingRecommendations) {
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      );
    }

    if (recommendations == null || recommendations!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendations!.length,
        itemBuilder: (context, index) {
          final recommendation = recommendations![index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    // Extraire les données directement de la réponse API
    String? imageUrl;
    String? title;
    String? description;
    double? rating;
    String? price;
    String? propertyType;
    String? address;

    try {
      // Extraire les données selon la structure de l'API fournie
      title = recommendation['adresse']?.toString() ?? 'Propriété';
      description = recommendation['description']?.toString() ?? 'Aucune description disponible';
      address = recommendation['adresse']?.toString() ?? '';
      
      // Extraire le rating
      if (recommendation['ratings'] != null) {
        rating = double.tryParse(recommendation['ratings'].toString()) ?? 0.0;
            } else {
        rating = 0.0;
      }

      // Extraire le prix selon le type d'opération
      if (recommendation['type_operation'] == 'vendre') {
        if (recommendation['montant'] != null) {
          price = '${recommendation['montant']} M';
        }
      } else if (recommendation['type_operation'] == 'alouer') {
        if (recommendation['loyer_mensuel'] != null) {
          price = '${recommendation['loyer_mensuel']} K/mois';
        } else if (recommendation['prix_loyer'] != null) {
          price = '${recommendation['prix_loyer']} K/mois';
        }
      }

      // Extraire la première image si disponible
      if (recommendation['images'] != null && recommendation['images'] is List && recommendation['images'].isNotEmpty) {
        final firstImage = recommendation['images'][0];
        if (firstImage is Map && firstImage['image'] != null) {
          imageUrl = firstImage['image'].toString();
        }
      }
    } catch (e) {
      // Valeurs par défaut en cas d'erreur
      imageUrl = null;
      title = 'Propriété';
      description = 'Aucune description disponible';
      rating = 0.0;
      price = null;
      propertyType = null;
    }

        return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 0),
              child: Card(
        elevation: 4,
                        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToPropertyDetail(recommendation),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.home,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.home,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      // Titre
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kBlackColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Type d'opération
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: recommendation['type_operation'] == 'vendre' ? Colors.red.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recommendation['type_operation'] == 'vendre' ? 'À vendre' : 'À louer',
                          style: TextStyle(
                            fontSize: 9,
                            color: recommendation['type_operation'] == 'vendre' ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Description
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Rating et Prix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Prix
                          if (price != null)
                            Flexible(
                              child: Text(
                                '$price MRU',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: pcolor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  void _navigateToPropertyDetail(Map<String, dynamic> property) {
    // Extraire l'ID de la propriété avec gestion de type
    int? propertyId;
    
    try {
      if (property['immob'] != null) {
        final immobId = property['immob']['id'];
        propertyId = immobId is int ? immobId : int.tryParse(immobId.toString());
      } else {
        final id = property['id'];
        propertyId = id is int ? id : int.tryParse(id.toString());
      }
      
      if (propertyId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImmobDetails(id: propertyId!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Impossible d'ouvrir les détails") ?? "Impossible d'ouvrir les détails"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Impossible d'ouvrir les détails") ?? "Impossible d'ouvrir les détails"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategoryCard(String categoryName, Map<String, dynamic> categoryData) {
    final categoryInfo = _getCategoryInfo(categoryName);
    
    return Hero(
      tag: 'category_$categoryName',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCategory(categoryName, categoryData),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryInfo['gradientStart'],
                  categoryInfo['gradientEnd'],
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: categoryInfo['gradientStart'].withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image de fond avec overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      categoryInfo['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Contenu
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryInfo['icon'],
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      // Nom de la catégorie
                      Text(
                        getTranslated(context, categoryData['name'])!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, // Limite à une seule ligne
                        overflow: TextOverflow.ellipsis, // Ajoute "..." si le texte est trop long
                        softWrap: false, // Empêche le retour à la ligne
                      ),
                      const SizedBox(height: 4),
                      // Nombre de propriétés
                      Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${categoryData['count']} ${getTranslated(context, "propriétés") ?? "propriétés"}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bouton voir plus
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getTranslated(context, "Voir") ?? "Voir",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'appartement':
        return {
          'image': 'assets/images/appartements.jpg',
          'icon': Icons.apartment,
          'gradientStart': const Color(0xFF667eea),
          'gradientEnd': const Color(0xFF764ba2),
        };
      case 'duplex':
        return {
          'image': 'assets/images/duplex 1.png',
          'icon': Icons.home_work,
          'gradientStart': const Color(0xFFf093fb),
          'gradientEnd': const Color(0xFFf5576c),
        };
      case 'commercial':
        return {
          'image': 'assets/images/commercial.jpg',
          'icon': Icons.store,
          'gradientStart': const Color(0xFF4facfe),
          'gradientEnd': const Color(0xFF00f2fe),
        };
      case 'terrain':
        return {
          'image': 'assets/images/terrain 1.png',
          'icon': Icons.landscape,
          'gradientStart': const Color(0xFF43e97b),
          'gradientEnd': const Color(0xFF38f9d7),
        };
      case 'residentiel':
        return {
          'image': 'assets/images/maison meuble 1.png',
          'icon': Icons.home,
          'gradientStart': const Color(0xFFfa709a),
          'gradientEnd': const Color(0xFFfee140),
        };
      case 'maisonceremonie':
        return {
          'image': 'assets/images/ceremoniehause.jpg',
          'icon': Icons.celebration,
          'gradientStart': const Color(0xFFff9a9e),
          'gradientEnd': const Color(0xFFfecfef),
        };
      default:
        return {
          'image': 'assets/images/default.png',
          'icon': Icons.home,
          'gradientStart': const Color(0xFF667eea),
          'gradientEnd': const Color(0xFF764ba2),
        };
    }
  }

  void _navigateToCategory(String categoryName, Map<String, dynamic> categoryData) {
                                    String apiUrl;
                                    switch (categoryName.toLowerCase()) {
                                      case 'appartement':
                                        apiUrl = 'https://akarina.shop/akareena/appartements/';
                                        break;
                                      case 'duplex':
                                        apiUrl = 'https://akarina.shop/akareena/duplexes/';
                                        break;
                                      case 'commercial':
                                        apiUrl = 'https://akarina.shop/akareena/commerciaux/';
                                        break;
                                      case 'terrain':
                                        apiUrl = 'https://akarina.shop/akareena/terrains/';
                                        break;
                                      case 'residentiel':
                                        apiUrl = 'https://akarina.shop/akareena/residentiels/';
                                        break;
      case 'maisonceremonie':
        apiUrl = 'https://akarina.shop/akareena/maison_ceremonie';
                                        break;
                                      default:
        apiUrl = '';
    }
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          Appartement(apiUrl: apiUrl, count: categoryData['count']),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
