import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class ImmobDetails extends StatefulWidget {
  final int id;

  const ImmobDetails({super.key, required this.id});

  @override
  State<ImmobDetails> createState() => _ImmobDetailsState();
}

class _ImmobDetailsState extends State<ImmobDetails> {
  LatLng _initialPosition = const LatLng(48.8566, 2.3522);
  bool isLoading = true;
  Map<String, dynamic>? immobData;
  GoogleMapController? _controller;
  late Future<List<User>> futureUsers;

  // Variables pour les reviews
  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = false;
  double averageRating = 0.0;
  bool hasInternetConnection = true;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

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

    fetchImmobDetails();
    fetchReviews();
    futureUsers = NetworkService().fetchUsers(context);
  }

  Future<void> fetchImmobDetails() async {
    try {
      var data = await NetworkService().fetchImmobDetails(widget.id);
      print('=== API RESPONSE ===');
      print('Raw data: $data');
      print('===================');

      setState(() {
        // Extraire les données de l'objet 'immob'
        immobData = data['immob'] ?? data;
        _initialPosition = LatLng(
          double.parse(immobData?['y'] ?? '48.8566'),
          double.parse(immobData?['x'] ?? '2.3522'),
        );
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Méthode pour récupérer les reviews
  Future<void> fetchReviews() async {
    setState(() {
      isLoadingReviews = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://akarina.online/akareena/immobilier/${widget.id}/reviews/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          reviews = (responseData['reviews'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          averageRating = (responseData['average_rating'] as num).toDouble();
          isLoadingReviews = false;
        });
      } else {
        setState(() {
          isLoadingReviews = false;
        });
        print('Error fetching reviews: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingReviews = false;
      });
      print('Error fetching reviews: $e');
    }
  }

  // Méthode pour créer un review
  Future<void> createReview(int rating, String comment) async {
    try {
      // Vérifier le token
      final String? token = await storage.read(key: "access");
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(
                context, "Vous devez vous connecter pour poster un avis")!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: getTranslated(context, "Se connecter")!,
              textColor: Colors.white,
              onPressed: () {
                // Naviguer vers la page de connexion
                Navigator.pushNamed(context, '/login');
              },
            ),
          ),
        );
        return;
      }

      print('📡 Envoi de la requête de review...');
      print('🔗 URL: https://akarina.online/akareena/${widget.id}/reviews/');
      print('⭐ Rating: $rating');
      print('💬 Comment: $comment');

      final response = await http.post(
        Uri.parse('https://akarina.online/akareena/${widget.id}/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Review créé avec succès: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                getTranslated(context, "Review créé avec succès")!),
            backgroundColor: Colors.green,
          ),
        );
        // Rafraîchir les reviews
        await fetchReviews();
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        print('❌ Erreur 401: Token expiré ou invalide');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(
                context, "Vous devez vous connecter pour poster un avis")!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: getTranslated(context, "Se connecter")!,
              textColor: Colors.white,
              onPressed: () {
                // Naviguer vers la page de connexion
                Navigator.pushNamed(context, '/login');
              },
            ),
          ),
        );
      } else if (response.statusCode == 400) {
        // Erreur de validation
        print('❌ Erreur 400: Erreur de validation');
        try {
          final errorData = jsonDecode(response.body);
          print('📄 Détails de l\'erreur: $errorData');

          String errorMessage = getTranslated(context, "Erreur de validation")!;

          // Traiter les erreurs spécifiques
          if (errorData['rating'] != null) {
            errorMessage += '\n- Rating: ${errorData['rating'][0]}';
          }
          if (errorData['comment'] != null) {
            errorMessage += '\n- Commentaire: ${errorData['comment'][0]}';
          }
          if (errorData['non_field_errors'] != null) {
            errorMessage += '\n- ${errorData['non_field_errors'][0]}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        } catch (e) {
          print('❌ Erreur lors du parsing de l\'erreur: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  getTranslated(context, "Erreur de validation des données")!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 403) {
        // Accès interdit
        print('❌ Erreur 403: Accès interdit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(
                context, "Vous n'avez pas l'autorisation de poster un avis")!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 404) {
        // Immobilier non trouvé
        print('❌ Erreur 404: Immobilier non trouvé');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Immobilier non trouvé")!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 429) {
        // Trop de requêtes
        print('❌ Erreur 429: Trop de requêtes');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(
                context, "Trop de requêtes. Veuillez patienter")!),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (response.statusCode >= 500) {
        // Erreur serveur
        print('❌ Erreur serveur: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(
                context, "Erreur serveur. Veuillez réessayer plus tard")!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Autres erreurs
        print('❌ Erreur inconnue: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ??
                  errorData['detail'] ??
                  getTranslated(
                      context, "Erreur lors de la création du review")!),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          print('==================+++++++++${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            
            SnackBar(
              content: Text(
                  '${getTranslated(context, "Erreur")}: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Exception lors de la création du review: $e');
      print('📋 Type d\'erreur: ${e.runtimeType}');

      // Afficher le type d'erreur dans la console
      print("Type d'erreur : ${e.runtimeType}");
      print("Message : $e");
   
      String errorMessage;
      if (e.toString().contains('SocketException')) {
        errorMessage = getTranslated(context, "Erreur de connexion réseau")!;
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = getTranslated(context, "Délai d'attente dépassé")!;
      } else if (e.toString().contains('FormatException')) {
        errorMessage = getTranslated(context, "Erreur de format de données")!;
      } else if (e.toString().contains('MissingPluginException')) {
        errorMessage =
            getTranslated(context, "Erreur de configuration de l'application")!;
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage =
            getTranslated(context, "Erreur de sécurité de connexion")!;
      } else if (e.toString().contains('CertificateException')) {
        errorMessage = getTranslated(context, "Erreur de certificat SSL")!;
      } else {
        errorMessage = "Erreur: $e";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher la page d'erreur de connexion si pas de connexion internet
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection =
              await ConnectivityService.hasInternetConnection();
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
                ? IconBroken
                    .Arrow___Right_2 // Icône pour l'arabe (flèche à droite)
                : IconBroken
                    .Arrow___Left_2, // Icône pour le français (flèche à gauche)
            color: kBlackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          getTranslated(context, "Détails de l'immobilier")!,
          style: TextStyle(color: kBlackColor),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showOrderDialog();
        },
        backgroundColor: pcolor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart),
        label: Text(getTranslated(context, "Commander")!),
      ),
      body: SafeArea(
        child: RefreshableWidget(
          onRefresh: () async {
            await fetchImmobDetails();
          },
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : immobData == null
                  ? Center(
                      child: Text(
                          getTranslated(context, "Aucune donnée trouvée.")!))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _contact(),
                            SizedBox(height: getProportionateScreenHeight(5)),
                            _buildPriceAndStatusHeader(),
                            SizedBox(height: getProportionateScreenHeight(5)),
                            // Section pour les images
                            _buildImageSection(immobData?['images'] ?? []),
                            SizedBox(height: getProportionateScreenHeight(5)),
                            // Section pour les utilisateurs
                            _buildUsersSection(),
                            SizedBox(height: getProportionateScreenHeight(25)),
                            // Disponibilité
                            // Informations principales (icônes des caractéristiques)
                            _buildFeatureInfo(),
                            const SizedBox(height: 10),

                            // Entourage du maison (icônes des infrastructures)
                            _buildInfrastructureSection(),
                            const SizedBox(height: 10),

                            // Description de la maison
                            FutureBuilder<String>(
                              future: getCurrentLanguage(context),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text(getTranslated(context,
                                      "Erreur lors du chargement de la langue")!);
                                } else {
                                  final currentLanguage =
                                      snapshot.data ?? ARABIC;
                                  final descriptionKey =
                                      currentLanguage == ARABIC
                                          ? 'description_ar'
                                          : 'description';

                                  return _buildDescriptionSection(
                                    immobData?[descriptionKey] ??
                                        getTranslated(context,
                                            "Pas de description disponible."),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 10),

                            // Localisation du maison (Google Maps)
                            _buildMapSection(immobData),

                            // Section des reviews
                            _buildReviewsSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required double? montant,
    required double? loyerMensuel,
    required String? periode,
    required bool available,
    required String typeOperation,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(16.0),
        vertical: getProportionateScreenHeight(8.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(8.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Montant ou loyer mensuel
          Text(
            typeOperation == 'vendre'
                ? '${montant?.toStringAsFixed(0)} ${getTranslated(context, "MRU") ?? "MRU"}'
                : '${loyerMensuel?.toStringAsFixed(0)} ${getTranslated(context, "MRU") ?? "MRU"} / ${getTranslated(context, periode) ?? periode}',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(16),
              fontWeight: FontWeight.bold,
              color: typeOperation == 'vendre' ? Colors.green : Colors.blue,
            ),
          ),
          // Disponibilité
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(8.0),
              vertical: getProportionateScreenHeight(4.0),
            ),
            decoration: BoxDecoration(
              color: available ? Colors.green : Colors.red,
              borderRadius:
                  BorderRadius.circular(getProportionateScreenWidth(8.0)),
            ),
            child: Text(
              available
                  ? getTranslated(context, "Disponible") ?? "Disponible"
                  : getTranslated(context, "Non disponible") ??
                      "Non disponible",
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour le bouton WhatsApp
  void _launchWhatsApp() async {
    const phoneNumber = '20203000';
    const message = 'Bonjour, je vous contacte depuis l\'application';
    final url = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Impossible d\'ouvrir WhatsApp';
    }
  }

  // Fonction pour le bouton Téléphone
  void _launchPhone() async {
    const phoneNumber = '20203000';
    final url = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Impossible de passer un appel';
    }
  }

  Widget _contact() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            getTranslated(context, "message")!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              // Bouton WhatsApp
              Expanded(
                child: InkWell(
                  onTap: _launchWhatsApp,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined,
                            color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          getTranslated(context, "WhatsApp")!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Bouton Téléphone
              Expanded(
                child: InkWell(
                  onTap: _launchPhone,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34B7F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          getTranslated(context, "Contact")!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndStatusHeader() {
    // Déterminer le type de propriété et extraire les données appropriées
    Map<String, dynamic>? propertyData;

    if (immobData?['residentiel'] != null) {
      propertyData = immobData?['residentiel'];
    } else if (immobData?['terrain'] != null) {
      propertyData = immobData?['terrain'];
    } else if (immobData?['commercial'] != null) {
      propertyData = immobData?['commercial'];
    } else {
      propertyData = immobData;
    }

    // Récupération des données
    final typeOperation = propertyData?['type_operation'] ??
        immobData?['operation']?['type'] ??
        'vendre';
    final montant =
        double.tryParse(propertyData?['montant']?.toString() ?? '0');
    final loyerMensuel =
        double.tryParse(propertyData?['loyer_mensuel']?.toString() ?? '0');
    final periode = propertyData?['periode'] ?? 'mois';
    final isAvailable =
        propertyData?['available'] == true || immobData?['available'] == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 350;

        return Container(
          margin: EdgeInsets.symmetric(),
          padding: EdgeInsets.all(getProportionateScreenWidth(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(getProportionateScreenWidth(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: getProportionateScreenWidth(10),
                spreadRadius: getProportionateScreenWidth(3),
                offset: Offset(0, getProportionateScreenHeight(4)),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Flex(
            direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Partie Prix
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      typeOperation == 'vendre'
                          ? getTranslated(context, 'vendre')!
                          : getTranslated(context, 'alouer')!,
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(14),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(4)),
                    Text(
                      typeOperation == 'vendre'
                          ? '${montant?.toStringAsFixed(0)} MRU'
                          : '${loyerMensuel?.toStringAsFixed(0)} MRU/${getTranslated(context, periode)}',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(22),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (typeOperation == 'louer')
                      Padding(
                        padding: EdgeInsets.only(
                            top: getProportionateScreenHeight(4)),
                        child: Text(
                          getTranslated(context, 'Prix mensuel')!,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(12),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Espacement conditionnel
              if (!isSmallScreen)
                SizedBox(width: getProportionateScreenWidth(16)),

              // Partie Disponibilité
              Flexible(
                flex: 1,
                child: Container(
                  margin: isSmallScreen
                      ? EdgeInsets.only(top: getProportionateScreenHeight(12))
                      : EdgeInsets.zero,
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(16),
                    vertical: getProportionateScreenHeight(8),
                  ),
                  decoration: BoxDecoration(
                    color:
                        isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(getProportionateScreenWidth(20)),
                    border: Border.all(
                      color: isAvailable
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: getProportionateScreenWidth(10),
                        height: getProportionateScreenWidth(10),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Flexible(
                        child: Text(
                          isAvailable
                              ? getTranslated(context, 'Available')!
                              : getTranslated(context, 'Unavailable')!,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Section pour afficher les images
  Widget _buildImageSection(List<dynamic> images) {
    print('=== DEBUG IMAGES ===');
    print('Images reçues: $images');
    print('Nombre d\'images: ${images.length}');
    if (images.isNotEmpty) {
      print('Première image: ${images[0]}');
    }
    print('===================');

    if (images.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              getTranslated(context, "Aucune image disponible.") ??
                  "Aucune image disponible.",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Locale>(
      future: getLocale(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        bool isArabic = snapshot.data?.languageCode == ARABIC;

        return SizedBox(
          height: getProportionateScreenHeight(280),
          child: Column(
            children: [
              // Première ligne : Grande image à gauche et deux petites images à droite
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Grande image à gauche
                    if (images.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: isArabic
                                ? 0.0
                                : getProportionateScreenWidth(4.0),
                            left: isArabic
                                ? getProportionateScreenWidth(4.0)
                                : 0.0,
                          ),
                          child: _buildImage(images[0]['image'], 0, images),
                        ),
                      ),
                    // Deux petites images à droite
                    if (images.length > 1)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            if (images.length > 1)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      bottom:
                                          getProportionateScreenHeight(4.0)),
                                  child: _buildImage(
                                      images[1]['image'], 1, images),
                                ),
                              ),
                            if (images.length > 2)
                              Expanded(
                                child:
                                    _buildImage(images[2]['image'], 2, images),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(4.0)),
              // Deuxième ligne : Trois images en bas
              if (images.length > 3)
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      for (int i = 3; i < 6 && i < images.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(2.0)),
                            child: _buildImage(images[i]['image'], i, images),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      print('URL invalide: null ou vide');
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) {
      print('URL invalide: $url');
      return false;
    }

    print('URL valide: $url');
    return true;
  }

  // Fonction pour afficher chaque image
  Widget _buildImage(String imageUrl, int index, List<dynamic> images) {
    print('Building image $index: $imageUrl');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageView(
              imageUrls:
                  images.map<String>((image) => image['image'] ?? '').toList(),
              initialIndex: index,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: isValidImageUrl(imageUrl)
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Erreur de chargement image: $error');
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image,
                          size: 40, color: Colors.grey),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image,
                      size: 40, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  // Section pour afficher la liste des utilisateurs
  Widget _buildUsersSection() {
    return FutureBuilder<List<User>>(
      future: futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text('Erreur lors du chargement des utilisateurs'));
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun utilisateur trouvé.'));
        } else if (snapshot.hasData) {
          return SizedBox(
            height: getProportionateScreenHeight(100),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                User user = snapshot.data![index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: InkWell(
                    onTap: () {
                      final participantImage = user.image?.isNotEmpty == true
                          ? user.image!
                          : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png';

                      final participantName =
                          user.nomComplet?.isNotEmpty == true
                              ? user.nomComplet!
                              : getTranslated(context, "Utilisateur inconnu")!;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            participantId: user.id,
                            participantImage: participantImage,
                            participantName: participantName,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: pcolor,
                              child: CircleAvatar(
                                radius: 23,
                                backgroundImage: NetworkImage(
                                  user.image?.isNotEmpty == true
                                      ? user.image!
                                      : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png',
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: getProportionateScreenWidth(70),
                          child: Text(
                            user.nomComplet?.isNotEmpty == true
                                ? user.nomComplet!
                                : getTranslated(
                                    context, "Utilisateur inconnu")!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  // Section pour afficher les caractéristiques sous forme de grille
  Widget _buildFeatureInfo() {
    Map<String, dynamic>? propertyData;
    String propertyType = 'unknown';

    if (immobData?['residentiel'] != null) {
      propertyData = immobData?['residentiel'];
      propertyType = 'residentiel';
    } else if (immobData?['terrain'] != null) {
      propertyData = immobData?['terrain'];
      propertyType = 'terrain';
    } else if (immobData?['commercial'] != null) {
      propertyData = immobData?['commercial'];
      propertyType = 'commercial';
    } else {
      propertyData = immobData;
    }

    print('Property type: $propertyType');
    print('Property data: $propertyData');

    // Fonction pour vérifier si une valeur existe et n'est pas égale à 0
    bool isValidValue(dynamic value) {
      if (value == null) return false;
      if (value is String)
        return value.isNotEmpty && value != '0' && value != 'null';
      if (value is num) return value > 0;
      if (value is bool) return value == true;
      return true;
    }

    // Fonction pour obtenir la valeur numérique
    int getNumericValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    List<Map<String, dynamic>> allFeatureItems = [
      {
        'key': 'nombre_de_chambres',
        'image': 'assets/images/chambre.jpeg',
        'text':
            '${getNumericValue(propertyData!['nombre_de_chambres'])} ${getTranslated(context, "Chambres")}',
        'value': propertyData['nombre_de_chambres']
      },
      {
        'key': 'nombre_de_salles_de_bain',
        'image': 'assets/images/douche.jpeg',
        'text':
            '${getNumericValue(propertyData['nombre_de_salles_de_bain'])} ${getTranslated(context, "Salle de bain")}',
        'value': propertyData['nombre_de_salles_de_bain']
      },
      {
        'key': 'nombre_de_garages',
        'image': 'assets/images/garage.jpeg',
        'text':
            '${getNumericValue(propertyData['nombre_de_garages'])} ${getTranslated(context, "Garage")}',
        'value': propertyData['nombre_de_garages']
      },
      {
        'key': 'adresse',
        'image': 'assets/images/localisation.jpeg',
        'text':
            '${propertyData['adresse'] ?? immobData?['adresse'] ?? getTranslated(context, "Adresse non spécifiée")}',
        'value': propertyData['adresse'] ?? immobData?['adresse']
      },
      {
        'key': 'type_operation',
        'image': 'assets/images/type_operation.jpeg',
        'text':
            '${getTranslated(context, propertyData['type_operation'] ?? immobData?['operation']?['type'] ?? "Non spécifié")}',
        'value':
            propertyData['type_operation'] ?? immobData?['operation']?['type']
      },
      {
        'key': 'surface',
        'image': 'assets/images/type_operation.jpeg',
        'text':
            '${getNumericValue(propertyData['surface'] ?? immobData?['surface'])} ${getTranslated(context, "m²")}',
        'value': propertyData['surface'] ?? immobData?['surface']
      },
      {
        'key': 'presence_de_jardin',
        'image': 'assets/images/gardain.jpeg',
        'text': (propertyData['presence_de_jardin'] == true)
            ? '${getTranslated(context, "avec")}'
            : '${getTranslated(context, "sans")}',
        'value': propertyData['presence_de_jardin']
      },
      {
        'key': 'nombre_d_etages',
        'image': 'assets/images/etage.jpeg',
        'text': (propertyData['nombre_d_etages'] != null &&
                propertyData['nombre_d_etages'] != 0)
            ? '${getTranslated(context, "avec")}'
            : '${getTranslated(context, "sans")}',
        'value': propertyData['nombre_d_etages']
      },
      {
        'key': 'presence_de_pisime',
        'image': 'assets/images/pisume.jpeg',
        'text': (propertyData['presence_de_pisime'] == true)
            ? '${getTranslated(context, "avec")}'
            : '${getTranslated(context, "sans")}',
        'value': propertyData['presence_de_pisime']
      },
      {
        'key': 'presence_de_wifi',
        'image': 'assets/images/wifi.jpeg',
        'text': (propertyData['presence_de_wifi'] == true)
            ? '${getTranslated(context, "avec")}'
            : '${getTranslated(context, "sans")}',
        'value': propertyData['presence_de_wifi']
      },
      {
        'key': 'meubler',
        'image': 'assets/images/type_operation.jpeg',
        'text': (propertyData['meubler'] == true)
            ? '${getTranslated(context, "Meubler")}'
            : '${getTranslated(context, "pas Meubler")}',
        'value': propertyData['meubler']
      },
    ];

    // Filtrer les éléments qui existent et ne sont pas égaux à 0
    List<Map<String, dynamic>> featureItems = allFeatureItems.where((item) {
      final value = item['value'];
      final key = item['key'];

      // Cas spéciaux pour certains champs
      if (key == 'adresse') {
        return value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null';
      }
      if (key == 'type_operation') {
        return value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null';
      }
      if (key == 'surface') {
        return getNumericValue(value) > 0;
      }
      if (key == 'nombre_de_chambres' ||
          key == 'nombre_de_salles_de_bain' ||
          key == 'nombre_de_garages') {
        return getNumericValue(value) > 0;
      }
      if (key == 'nombre_d_etages') {
        return value != null && value != 0;
      }
      if (key == 'presence_de_jardin' ||
          key == 'presence_de_pisime' ||
          key == 'presence_de_wifi' ||
          key == 'meubler') {
        return value == true;
      }

      return isValidValue(value);
    }).toList();

    print('📊 Total features: ${allFeatureItems.length}');
    print('✅ Valid features: ${featureItems.length}');
    print(
        '🔍 Filtered features: ${featureItems.map((item) => item['key']).toList()}');

    if (featureItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              getTranslated(context, "Aucune caractéristique disponible")!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.5,
      ),
      itemCount: featureItems.length,
      itemBuilder: (context, index) {
        var item = featureItems[index];
        return _buildFeatureCard(item['image'], item['text']);
      },
    );
  }

  Widget _buildFeatureCard(String imagePath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageForInfrastructure(String type) {
    switch (type) {
      case 'Lycée':
        return 'assets/images/school.png';
      case 'Hôpital':
        return 'assets/images/hopital.png';
      case 'Mosquée':
        return 'assets/images/mosque.jpeg';
      case 'Marché':
        return 'assets/images/store.png';
      case 'Ambassade':
        return 'assets/images/embassad.jpeg';
      default:
        return 'assets/images/store.png';
    }
  }

  Widget _buildInfrastructureSection() {
    Map<String, dynamic>? propertyData;

    if (immobData?['residentiel'] != null) {
      propertyData = immobData?['residentiel'];
    } else if (immobData?['terrain'] != null) {
      propertyData = immobData?['terrain'];
    } else if (immobData?['commercial'] != null) {
      propertyData = immobData?['commercial'];
    } else {
      propertyData = immobData;
    }

    List<dynamic> infrastructures = propertyData!['infrastructures_proches'] ??
        immobData?['infrastructures_proches'] ??
        [];

    return FutureBuilder<String>(
      future: getCurrentLanguage(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(getTranslated(
              context, "Erreur lors du chargement de la langue")!);
        } else {
          final currentLanguage = snapshot.data ?? ARABIC;
          final isArabic = currentLanguage == ARABIC;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, "Entourage du maison")!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3.5,
                ),
                itemCount: infrastructures.length,
                itemBuilder: (context, index) {
                  var infra = infrastructures[index];
                  return _buildInfrastructureCard(
                    isArabic ? infra['nom_ar'] : infra['nom'],
                    _getImageForInfrastructure(
                      isArabic
                          ? infra['type_infrastructure_ar']
                          : infra['type_infrastructure'],
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildInfrastructureCard(String infraName, String imagePath) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              infraName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Map<String, dynamic>? data) {
    Map<String, dynamic>? propertyData;

    if (data?['residentiel'] != null) {
      propertyData = data?['residentiel'];
    } else if (data?['terrain'] != null) {
      propertyData = data?['terrain'];
    } else if (data?['commercial'] != null) {
      propertyData = data?['commercial'];
    } else {
      propertyData = data;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "Localisation du maison")!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: getProportionateScreenHeight(200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[300],
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  double.parse(propertyData?['y'] ?? data?['y'] ?? '48.8566'),
                  double.parse(propertyData?['x'] ?? data?['x'] ?? '2.3522'),
                ),
                zoom: 12.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: LatLng(
                    double.parse(propertyData?['y'] ?? data?['y'] ?? '48.8566'),
                    double.parse(propertyData?['x'] ?? data?['x'] ?? '2.3522'),
                  ),
                  infoWindow: InfoWindow(
                      title:
                          propertyData?['nom_ville'] ?? data?['ville']?['nom']),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showOrderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return OrderDialog(
          immobilierId: widget.id,
          immobilierData: immobData,
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              getTranslated(context, "Avis et commentaires")!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(),
              icon: const Icon(Icons.add, color: pcolor),
              label: Text(
                getTranslated(context, "Ajouter un avis")!,
                style: const TextStyle(color: pcolor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Affichage de la note moyenne
        if (reviews.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: pcolor,
                      ),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (index) => Icon(
                                Icons.star,
                                size: 20,
                                color: index < averageRating.floor()
                                    ? Colors.amber
                                    : Colors.grey[300],
                              )),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reviews.length} ${getTranslated(context, "avis")}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        getTranslated(context, "Note moyenne")!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Liste des reviews
        if (isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text(
                  getTranslated(context, "Aucun avis pour le moment")!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _showAddReviewDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(getTranslated(
                      context, "Soyez le premier à donner votre avis")!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pcolor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewCard(review);
            },
          ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final comment = isArabic && review['comment_ar']?.isNotEmpty == true
        ? review['comment_ar']
        : review['comment'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: pcolor,
                child: Text(
                  (review['user_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['user_name'] ??
                          getTranslated(context, "Utilisateur")!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(
                        DateTime.parse(review['created_at']),
                      ),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < (review['rating'] ?? 0)
                              ? Colors.amber
                              : Colors.grey[300],
                        )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (comment?.isNotEmpty == true)
            Text(
              comment,
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddReviewDialog(
          onSubmit: (rating, comment) {
            createReview(rating, comment);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildDescriptionSection(String description) {
    return _DescriptionSection(description: description);
  }
}

class _DescriptionSection extends StatefulWidget {
  final String description;

  const _DescriptionSection({super.key, required this.description});

  @override
  __DescriptionSectionState createState() => __DescriptionSectionState();
}

class __DescriptionSectionState extends State<_DescriptionSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, "Description de la maison")!,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  maxLines: isExpanded ? null : 3,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded
                            ? getTranslated(context, "Voir moins")!
                            : getTranslated(context, "Voir plus")!,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageView({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(widget.imageUrls[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.5,
            maxScale: PhotoViewComputedScale.contained * 5.0,
            heroAttributes:
                PhotoViewHeroAttributes(tag: widget.imageUrls[index]),
          );
        },
        itemCount: widget.imageUrls.length,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: event?.expectedTotalBytes != null
                  ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}



class OrderDialog extends StatefulWidget {
  final int immobilierId;
  final Map<String, dynamic>? immobilierData;
  final String? merchantCode;

  const OrderDialog({
    super.key,
    required this.immobilierId,
    this.immobilierData,
    this.merchantCode = '023977',
  });

  @override
  State<OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<OrderDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dateDebutController = TextEditingController();
  final TextEditingController dateFinController = TextEditingController();
  final TextEditingController ebankilyPhoneController = TextEditingController();
  final TextEditingController ebankilyPasscodeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  String selectedPaymentMethod = 'reception';
  bool isLoading = false;
  bool showBankilyInstructions = false;
  bool showPaymentDetails = false;
  
  // Variables pour les montants
  double? montantTotal;
  double montantBankily = 0;

  Map<String, dynamic>? reservationResponse;
  Map<String, dynamic>? paymentDetails;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'reception',
      'name': 'Paiement à la réception',
      'nameAr': 'الدفع عند الاستلام',
      'description': 'Payez lors de la réception du bien',
      'descriptionAr': 'ادفع عند استلام العقار',
      'icon': Icons.delivery_dining,
      'color': Colors.green,
    },
    {
      'id': 'ebankily',
      'name': 'Bankili',
      'nameAr': 'بانكيلي',
      'description': 'Paiement via Bankili',
      'descriptionAr': 'الدفع عبر بانكيلي',
      'icon': Icons.payment,
      'color': Colors.blue,
    },
    {
      'id': 'seddad',
      'name': 'Seddad',
      'nameAr': 'سداد',
      'description': 'Paiement via Seddad',
      'descriptionAr': 'الدفع عبر سداد',
      'icon': Icons.payment,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    dateDebutController.text = DateFormat('yyyy-MM-dd').format(now);
    dateFinController.text = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));
    _calculateAmounts();
  }

void _calculateAmounts() {
  if (widget.immobilierData == null) {
    montantTotal = 0;
    montantBankily = 0;
    return;
  }

  // Cas location
  if (widget.immobilierData?['operation']?['type'] == 'louer' ||
      widget.immobilierData?['residentiel']?['type_operation'] == 'louer') {
    final loyer = (widget.immobilierData?['residentiel']?['loyer_mensuel'] ??
                  widget.immobilierData?['loyer_mensuel'] ?? 0)
                .toDouble();
    final dateDebut = DateTime.tryParse(dateDebutController.text);
    final dateFin = DateTime.tryParse(dateFinController.text);

    if (dateDebut != null && dateFin != null) {
      final months = (dateFin.difference(dateDebut).inDays / 30).ceil();
      montantTotal = loyer * months;
    }
  } else {
    montantTotal = (widget.immobilierData?['residentiel']?['montant'] ??
                   widget.immobilierData?['montant'] ??
                   0)
                  .toDouble();
  }

  // Éviter le null avec valeur par défaut
  montantBankily = (montantTotal ?? 0) * 2;
}

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context, 'Réservation')!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Formulaire de réservation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showPaymentDetails && reservationResponse != null) 
                      _buildReservationSuccess(),
                    
                    if (!showPaymentDetails) ...[
                      // Property information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Informations sur l'immobilier",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "ID: ${widget.immobilierId}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (widget.immobilierData != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Adresse: ${widget.immobilierData!['adresse'] ?? 'N/A'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Type: ${widget.immobilierData!['operation']?['type'] ?? widget.immobilierData!['residentiel']?['type_operation'] ?? 'N/A'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (montantTotal != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Montant: ${montantTotal!.toStringAsFixed(0)} MRU",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reservation period
                      Text(
                        "Période de réservation",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateDebutController,
                              decoration: InputDecoration(
                                labelText: "Date début",
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context, dateDebutController),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: dateFinController,
                              decoration: InputDecoration(
                                labelText: "Date fin",
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context, dateFinController),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // User information
                      Text(
                        "Vos informations",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Nom complet",
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Numéro de téléphone",
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: "Notes (optionnel)",
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Payment methods
                      Text(
                        "Moyen de paiement",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...paymentMethods.map((method) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              value: method['id'],
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentMethod = value!;
                                  showBankilyInstructions = false;
                                });
                              },
                              title: Text(
                                isArabic ? method['nameAr'] : method['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                isArabic ? method['descriptionAr'] : method['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: method['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  method['icon'],
                                  color: method['color'],
                                  size: 20,
                                ),
                              ),
                              activeColor: method['color'],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: selectedPaymentMethod == method['id']
                                  ? method['color'].withOpacity(0.05)
                                  : null,
                            ),
                          )),

                      // Bankily instructions
                      if (selectedPaymentMethod == 'ebankily' && showBankilyInstructions)
                        _buildBankilyInstructions(),

                      // Bankily fields
                      if (selectedPaymentMethod == 'ebankily' && widget.merchantCode != null)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            TextField(
                              controller: ebankilyPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Votre numéro Bankili",
                                prefixIcon: const Icon(Icons.phone_android),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: ebankilyPasscodeController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "Code de confirmation Bankili",
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // Buttons
            if (!showPaymentDetails)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          "Annuler",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading 
                            ? null 
                            : () {
                                if (selectedPaymentMethod == 'ebankily' && !showBankilyInstructions) {
                                  setState(() {
                                    showBankilyInstructions = true;
                                  });
                                } else {
                                  _submitReservation();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                selectedPaymentMethod == 'ebankily' && !showBankilyInstructions
                                    ? "Générer code"
                                    : "Confirmer",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankilyInstructions() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Instructions de paiement Bankili",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Code marchand",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    widget.merchantCode ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.blue),
                onPressed: () {
                  if (widget.merchantCode != null) {
                    Clipboard.setData(ClipboardData(text: widget.merchantCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Code copié"),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "1. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "Copiez le code marchand ci-dessus",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "2. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "Ouvrez l'application Bankili",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "3. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "Cliquez sur B-Pay",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "4. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "Entrez le code marchand copié",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "5. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: "Entrez le montant: ${montantBankily.toStringAsFixed(0)} MRU", // Montant doublé
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "6. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "Bankili vous donnera un code de confirmation",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "7. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "Entrez le code de confirmation ci-dessous",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationSuccess() {
    final reservation = reservationResponse?['reservation'];
    final payment = reservationResponse?['payment_details'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                reservationResponse?['message'] ?? "Réservation confirmée",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Numéro de réservation: ${reservation?['id'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Statut: ${reservation?['statut'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Montant total: ${reservation?['montant_total'] ?? ''} MRU",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Moyen de paiement: ${payment?['method'] ?? reservation?['moyen_paiement'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          
          if (payment?['transaction_id'] != null) ...[
            const SizedBox(height: 8),
            Text(
              "Transaction ID: ${payment?['transaction_id'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          
          if (payment?['message'] != null) ...[
            const SizedBox(height: 16),
            Text(
              payment?['message'] ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateAmounts(); // Recalculer les montants quand la date change
      });
    }
  }

  Future<void> _submitReservation() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty || 
        dateDebutController.text.isEmpty || dateFinController.text.isEmpty) {
          
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == 'ebankily' && 
        (ebankilyPhoneController.text.isEmpty || ebankilyPasscodeController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir les informations Bankili"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final String? token = await storage.read(key: "access");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expirée"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Utiliser montantBankily si paiement via Bankily, sinon montantTotal
      final double montantAPayer = selectedPaymentMethod == 'ebankily' 
          ? montantBankily 
          : montantTotal ?? 0;

      final Map<String, dynamic> requestBody = {
        'immobilier_id': widget.immobilierId,
        'date_debut': dateDebutController.text,
        'date_fin': dateFinController.text,
        'moyen_paiement': selectedPaymentMethod,
        'notes': notesController.text,
        'montant_total': montantAPayer, // Envoyer le montant approprié
      };

      if (selectedPaymentMethod == 'ebankily') {
        requestBody['ebankily_phone'] = ebankilyPhoneController.text;
        requestBody['ebankily_passcode'] = ebankilyPasscodeController.text;
      }

      final response = await http.post(
        Uri.parse('https://akarina.online/akareena/reservations/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          reservationResponse = responseData;
          paymentDetails = responseData['payment_details'];
          showPaymentDetails = true;
          isLoading = false;
        });

        await _updateImmobilierStatus(false);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          isLoading = false;
        });
        print('==================+++++++++$errorData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? "Erreur lors de la création de la réservation"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateImmobilierStatus(bool available) async {
    try {
      final storage = const FlutterSecureStorage();
      final String? token = await storage.read(key: "access");

      if (token == null) return;

      await http.patch(
        Uri.parse('https://akarina.online/akareena/imobiers/${widget.immobilierId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'available': available,
        }),
      );
    } catch (e) {
      print("Erreur mise à jour statut immobilier: $e");
    }
  }
}

class AddReviewDialog extends StatefulWidget {
  final Function(int rating, String comment) onSubmit;

  const AddReviewDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int selectedRating = 0;
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTranslated(context, "Ajouter un avis")!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Sélection de la note
            Text(
              getTranslated(context, "Votre note")!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                  child: Icon(
                    Icons.star,
                    size: 40,
                    color: index < selectedRating
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Champ de commentaire
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: getTranslated(context, "Votre commentaire")!,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(getTranslated(context, "Annuler")!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedRating > 0
                        ? () {
                            widget.onSubmit(
                                selectedRating, commentController.text);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pcolor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(getTranslated(context, "Envoyer")!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}