import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/chat/chat.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';
import 'package:akarina/presentations/screens/immobillier/add_reviwe.dart';
import 'package:akarina/presentations/screens/immobillier/full_images.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:akarina/size_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:akarina/data/services/connectivity_service.dart';

class MaisonCeremonieDetailPage extends StatefulWidget {
  final String forfaitNom;
  final int maisonId;

  const MaisonCeremonieDetailPage({
    super.key,
    required this.forfaitNom,
    required this.maisonId,
  });

  @override
  State<MaisonCeremonieDetailPage> createState() => _MaisonCeremonieDetailPageState();
}

class _MaisonCeremonieDetailPageState extends State<MaisonCeremonieDetailPage> {
  final TextEditingController dateDebutController = TextEditingController();
  final TextEditingController dateFinController = TextEditingController();

  LatLng _initialPosition = const LatLng(18.0840609, -15.9784200);
  bool isLoading = true;
  Map<String, dynamic>? maisonDetail;
  GoogleMapController? _controller;

  // Variables pour les reviews
  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = false;
  double averageRating = 0.0;
  bool hasInternetConnection = true;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool isSessionActive = false;
  bool _isArabic = false;

  // Variables pour le calendrier
  bool _showCalendar = false;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<String, dynamic>? _disponibiliteData;
  bool _isLoadingDisponibilite = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkSession();
    _checkLanguage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Appeler ici car le contexte est disponible
    _checkLanguage();
  }

  void _checkLanguage() {
    // Vérifier que le contexte est disponible
    try {
      final locale = Localizations.localeOf(context);
      final isArabic = locale.languageCode == 'ar';
      if (_isArabic != isArabic) {
        setState(() {
          _isArabic = isArabic;
        });
      }
    } catch (e) {
      // Si le contexte n'est pas encore disponible, on ignore
      // La méthode sera rappelée via didChangeDependencies
    }
  }

  @override
  void dispose() {
    dateDebutController.dispose();
    dateFinController.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
      if (_showCalendar) {
        _loadDisponibilite();
      }
    });
  }

  Future<void> _loadDisponibilite() async {
    setState(() {
      _isLoadingDisponibilite = true;
    });

    try {
      final token = await storage.read(key: 'access');
      final url = Uri.parse(
          'https://akarina.shop/akareena/maison-ceremonie/${widget.maisonId}/disponibilite/mois/');

      final response = await http.post(
        url,
        headers: token != null && token.isNotEmpty
            ? {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'annee': _selectedYear,
          'mois': _selectedMonth,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _disponibiliteData = data;
          _isLoadingDisponibilite = false;
        });
      } else {
        setState(() {
          _isLoadingDisponibilite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur ${response.statusCode}: Impossible de charger les disponibilités"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingDisponibilite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de connexion: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
      _loadDisponibilite();
    });
  }

  Future<void> _checkSession() async {
    final String? token = await storage.read(key: "access");
    setState(() {
      isSessionActive = token != null && token.isNotEmpty;
    });
  }

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });

    if (!hasConnection) {
      return;
    }

    _loadMaisonDetail();
    _loadReviews();
  }

  Future<void> _loadMaisonDetail() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'access');
      final url = Uri.parse(
          'https://akarina.shop/akareena/forfait/${widget.forfaitNom}/maisons/${widget.maisonId}/');

      final response = await http.get(
        url,
        headers: token != null && token.isNotEmpty
            ? {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        // Parsing des nombres
        ['loyer_mensuel', 'surface', 'ratings'].forEach((key) {
          if (data[key] is String) {
            data[key] = double.tryParse(data[key]) ?? 0.0;
          } else if (data[key] is int) {
            data[key] = (data[key] as int).toDouble();
          } else if (data[key] == null) {
            data[key] = 0.0;
          }
        });

        setState(() {
          maisonDetail = data;
          _initialPosition = LatLng(
            double.tryParse(data['y']?.toString() ?? '18.0840609') ?? 18.0840609,
            double.tryParse(data['x']?.toString() ?? '-15.9784200') ?? -15.9784200,
          );
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur ${response.statusCode}: Impossible de charger les détails"),
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
          content: Text("Erreur de connexion: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== REVIEWS ====================
  Future<void> _loadReviews() async {
    setState(() {
      isLoadingReviews = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://akarina.shop/akareena/maison-ceremonie/${widget.maisonId}/reviews/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          reviews = (responseData['reviews'] as List<dynamic>).cast<Map<String, dynamic>>();
          averageRating = (responseData['average_rating'] as num).toDouble();
          isLoadingReviews = false;
        });
      } else {
        setState(() {
          isLoadingReviews = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingReviews = false;
      });
    }
  }

  Future<void> _createReview(int rating, String comment) async {
    try {
      final String? token = await storage.read(key: "access");
      if (token == null || token.isEmpty) {
        _showLoginRequiredDialog();
        return;
      }

      final response = await http.post(
        Uri.parse('https://akarina.shop/akareena/maison-ceremonie/${widget.maisonId}/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? "Avis créé avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        await _loadReviews();
      } else if (response.statusCode == 401) {
        _showLoginRequiredDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la création de l'avis"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Connexion requise")!),
          content: Text(getTranslated(context, "Vous devez vous connecter pour poster un avis.")!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getTranslated(context, "Annuler")!),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const IndexLogin()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pcolor,
                foregroundColor: Colors.white,
              ),
              child: Text(getTranslated(context, "Se connecter")!),
            ),
          ],
        );
      },
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddReviewDialog(
          onSubmit: (rating, comment) {
            _createReview(rating, comment);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // ==================== RÉSERVATION ====================
  void _showReservationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pcolor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt, size: 40, color: pcolor),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated(context, "Frais de réservation")!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "10 MRU",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: pcolor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslated(context, "Choisissez votre moyen de paiement")!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.9 : 1.0,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final paymentMethods = [
                        {
                          'imagePath': 'assets/images/bankily.png',
                          'name': getTranslated(context, "Bankily")!,
                          'method': 'bankily',
                        },
                        {
                          'imagePath': 'assets/images/saddad.png',
                          'name': getTranslated(context, "Seddade")!,
                          'method': 'seddade',
                        },
                        {
                          'imagePath': 'assets/images/masrivi.png',
                          'name': getTranslated(context, "Masrivi")!,
                          'method': 'masrivi',
                        },
                        {
                          'imagePath': 'assets/images/click.png',
                          'name': getTranslated(context, "Click")!,
                          'method': 'click',
                        },
                      ];

                      final payment = paymentMethods[index];
                      final isSmallScreen = MediaQuery.of(context).size.width < 400;
                      final imageSize = isSmallScreen ? 50.0 : 60.0;
                      final fontSize = isSmallScreen ? 12.0 : 14.0;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _processPayment(payment['method']!);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                            border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: imageSize,
                                height: imageSize,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    payment['imagePath']!,
                                    width: imageSize,
                                    height: imageSize,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.payment, size: imageSize * 0.6, color: Colors.grey[400]);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    payment['name']!,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pcolor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  getTranslated(context, "Sélectionner")!,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 10,
                                    color: pcolor,
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
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    getTranslated(context, "Annuler")!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processPayment(String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: pcolor),
              const SizedBox(width: 8),
              Text(getTranslated(context, "Confirmation")!),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, "Vous allez payer 10 MRU")!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "${getTranslated(context, "Moyen de paiement")!}: ${_getPaymentMethodName(method)}",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        getTranslated(context, "Vous serez redirigé vers l'application de paiement")!,
                        style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getTranslated(context, "Annuler")!, style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmPayment(method);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pcolor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(getTranslated(context, "Confirmer")!),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'bankily':
        return getTranslated(context, "Bankily")!;
      case 'seddade':
        return getTranslated(context, "Seddade")!;
      case 'masrivi':
        return getTranslated(context, "Masrivi")!;
      case 'click':
        return getTranslated(context, "Click")!;
      default:
        return getTranslated(context, "Autre")!;
    }
  }

  void _confirmPayment(String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: pcolor),
                const SizedBox(height: 16),
                Text(
                  getTranslated(context, "Traitement du paiement...")!,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(getTranslated(context, "Paiement réussi")!),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, size: 60, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  getTranslated(context, "Votre réservation a été confirmée avec succès!")!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslated(context, "Un email de confirmation vous a été envoyé")!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(getTranslated(context, "OK")!),
              ),
            ],
          );
        },
      );
    });
  }

  // ==================== CONTACT ====================
  void _launchWhatsApp() async {
    const phoneNumber = '20203000';
    const message = 'Bonjour, je vous contacte depuis l\'application';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchPhone() async {
    const phoneNumber = '20203000';
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ==================== IMAGES ====================
  Widget _buildImageSection(List<dynamic> images) {
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
              getTranslated(context, "Aucune image disponible.")!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final List<dynamic> validMedia = images.where((media) {
      return (media['image'] != null && media['image'].toString().isNotEmpty) ||
          (media['video'] != null && media['video'].toString().isNotEmpty) ||
          (media['video_url'] != null && media['video_url'].toString().isNotEmpty);
    }).toList();

    if (validMedia.isEmpty) {
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
              getTranslated(context, "Aucun média disponible.")!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: getProportionateScreenHeight(280),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (validMedia.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: getProportionateScreenWidth(4.0)),
                      child: _buildMedia(validMedia[0], 0, validMedia),
                    ),
                  ),
                if (validMedia.length > 1)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        if (validMedia.length > 1)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: getProportionateScreenHeight(4.0)),
                              child: _buildMedia(validMedia[1], 1, validMedia),
                            ),
                          ),
                        if (validMedia.length > 2)
                          Expanded(
                            child: _buildMedia(validMedia[2], 2, validMedia),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4.0)),
          if (validMedia.length > 3)
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  for (int i = 3; i < 6 && i < validMedia.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(2.0)),
                        child: _buildMedia(validMedia[i], i, validMedia),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isVideo(String? url) {
    if (url == null || url.isEmpty) return false;
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.wmv', '.flv', '.mkv'];
    final videoPaths = ['/videos/', '/media/videos/', 'video', 'mp4'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext)) ||
        videoPaths.any((path) => lowerUrl.contains(path));
  }

  String _getMediaUrl(dynamic media) {
    // Priorité à l'image
    if (media['image'] != null && media['image'].toString().isNotEmpty) {
      String url = media['image'];
      if (url.startsWith('/')) return 'https://akarina.shop$url';
      return url;
    }
    // Sinon utiliser la vidéo (video_url ou video)
    else if (media['video_url'] != null && media['video_url'].toString().isNotEmpty) {
      String url = media['video_url'];
      if (url.startsWith('/')) return 'https://akarina.shop$url';
      return url;
    } else if (media['video'] != null && media['video'].toString().isNotEmpty) {
      String url = media['video'];
      if (url.startsWith('/')) return 'https://akarina.shop$url';
      return url;
    }
    return '';
  }

  Widget _buildMediaContent(String mediaUrl, bool isVideo) {
    if (mediaUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }

    if (isVideo) {
      return Container(
        color: Colors.black54,
        child: Icon(Icons.videocam, size: 40, color: Colors.white54),
      );
    }

    return Image.network(
      mediaUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildMedia(dynamic media, int index, List<dynamic> allMedia) {
    final mediaUrl = _getMediaUrl(media);
    final isVideo = _isVideo(mediaUrl);

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          _openVideo(context, mediaUrl);
        } else {
          final imageUrls = allMedia
              .where((m) => !_isVideo(_getMediaUrl(m)))
              .map<String>((m) => _getMediaUrl(m))
              .toList();
          final imageIndex = imageUrls.indexOf(mediaUrl);
          if (imageIndex != -1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageView(
                  imageUrls: imageUrls,
                  initialIndex: imageIndex,
                ),
              ),
            );
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              _buildMediaContent(mediaUrl, isVideo),
              if (isVideo)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, size: 30, color: Colors.white),
                    ),
                  ),
                ),
              if (isVideo)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'VIDÉO',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideo(BuildContext context, String videoUrl) {
    String fullVideoUrl = videoUrl;
    if (videoUrl.startsWith('/')) {
      fullVideoUrl = 'https://akarina.shop$videoUrl';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          child: VideoPlayerWidget(videoUrl: fullVideoUrl),
        ),
      ),
    );
  }

  // ==================== GETTERS MULTILINGUES ====================
  String _getText(String? fr, String? ar) {
    return _isArabic ? (ar ?? fr ?? '') : (fr ?? ar ?? '');
  }

  String _getVilleNom() {
    return _getText(
      maisonDetail?['ville_nom'],
      maisonDetail?['ville_nom_ar'],
    );
  }

  String _getAdresse() {
    return maisonDetail?['adresse'] ?? '';
  }

  String _getDescription() {
    return _getText(
      maisonDetail?['description'],
      maisonDetail?['description_ar'],
    );
  }

  String _getPeriode() {
    return _getText(
      maisonDetail?['periode'],
      maisonDetail?['periode_ar'],
    );
  }

  String _getOperationType() {
    final type = maisonDetail?['type_operation'] ?? 'alouer';
    if (_isArabic) {
      return type == 'vendre' ? 'بيع' : 'إيجار';
    }
    return type == 'vendre' ? 'vendre' : 'alouer';
  }

  String _getForfaitNom() {
    return _getText(
      maisonDetail?['forfait_info']?['nom'],
      maisonDetail?['forfait_info']?['nom_ar'],
    );
  }

  String _getForfaitDescription() {
    return _getText(
      maisonDetail?['forfait_info']?['description'],
      maisonDetail?['forfait_info']?['description_ar'],
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    _checkLanguage();

    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          setState(() {
            hasInternetConnection = hasConnection;
          });
          if (hasConnection) _initializeData();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            _isArabic ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2,
            color: kBlackColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, "Détails de la maison")!,
          style: TextStyle(color: kBlackColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final String? token = await storage.read(key: "access");
            if (token == null) {
              _showLoginRequiredDialog();
              return;
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur : $e")),
            );
          }
          _showReservationDialog();
        },
        backgroundColor: pcolor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart),
        label: Text(getTranslated(context, "Commander")!),
      ),
      body: SafeArea(
        child: RefreshableWidget(
          onRefresh: () async {
            await _loadMaisonDetail();
          },
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : maisonDetail == null
                  ? Center(child: Text(getTranslated(context, "Aucune donnée trouvée.")!))
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
                            _buildCalendarSection(),
                            _buildImageSection(maisonDetail?['images'] ?? []),
                            const SizedBox(height: 10),
                            _buildFeatureInfo(),
                            const SizedBox(height: 10),
                            _buildInfrastructureSection(),
                            const SizedBox(height: 10),
                            _buildDescriptionSection(),
                            const SizedBox(height: 10),
                            _buildMapSection(),
                            const SizedBox(height: 10),
                            _buildReviewsSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ==================== CONTACT WIDGET ====================
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
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
                        Icon(Icons.chat_outlined, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          getTranslated(context, "WhatsApp")!,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  // ==================== PRIX ET DISPONIBILITÉ ====================
  Widget _buildPriceAndStatusHeader() {
    final double loyerMensuel = (maisonDetail?['loyer_mensuel'] ?? 0).toDouble();
    final String periode = _getPeriode();
    final String adresse = _getAdresse();
    final double surface = (maisonDetail?['surface'] ?? 0).toDouble();
    final bool withServices = maisonDetail?['avec_services'] ?? false;
    final bool isMeubler = maisonDetail?['meubler'] ?? false;
    final bool isAvailable = maisonDetail?['available'] ?? false;
    final String villeNom = _getVilleNom();

    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: getProportionateScreenWidth(10),
            spreadRadius: getProportionateScreenWidth(3),
            offset: Offset(0, getProportionateScreenHeight(4)),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Ville et adresse
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: pcolor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      villeNom,
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(14),
                        fontWeight: FontWeight.w600,
                        color: pcolor,
                      ),
                    ),
                    if (adresse.isNotEmpty && adresse != villeNom)
                      Text(
                        adresse,
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(12),
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Prix et surface
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, "Prix")!,
                    style: TextStyle(fontSize: getProportionateScreenWidth(12), color: Colors.grey[600]),
                  ),
                  Text(
                    '${loyerMensuel.round()} MRU',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(22),
                      fontWeight: FontWeight.bold,
                      color: pcolor,
                    ),
                  ),
                  if (periode.isNotEmpty)
                    Text(
                      periode,
                      style: TextStyle(fontSize: getProportionateScreenWidth(12), color: Colors.grey[500]),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    getTranslated(context, "Surface")!,
                    style: TextStyle(fontSize: getProportionateScreenWidth(12), color: Colors.grey[600]),
                  ),
                  Text(
                    '${surface.round()} m²',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(19),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  // Badge disponibilité
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable
                              ? getTranslated(context, "Disponible")!
                              : getTranslated(context, "Indisponible")!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Caractéristiques
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (withServices)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cleaning_services, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        getTranslated(context, "Services inclus")!,
                        style: TextStyle(fontSize: 11, color: Colors.blue[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              if (isMeubler)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.weekend, size: 14, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        getTranslated(context, "Meublé")!,
                        style: TextStyle(fontSize: 11, color: Colors.orange[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              // Note
              if (maisonDetail?['ratings'] != null && maisonDetail?['ratings'] > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        (maisonDetail?['ratings'] ?? 0).toStringAsFixed(1),
                        style: TextStyle(fontSize: 11, color: Colors.amber[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CALENDRIER ====================
  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: _toggleCalendar,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pcolor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _showCalendar ? Icons.calendar_today : Icons.calendar_month,
                    color: pcolor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _showCalendar
                        ? getTranslated(context, "Masquer le calendrier")!
                        : getTranslated(context, "Voir les disponibilités")!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _showCalendar ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[400],
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_showCalendar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: pcolor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: pcolor),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            DateFormat(_isArabic ? 'MMMM' : 'MMMM').format(
                              DateTime(_selectedYear, _selectedMonth)
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _selectedYear.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: pcolor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: Icon(Icons.arrow_forward_ios, size: 18, color: pcolor),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.green, getTranslated(context, "Disponible")!),
                      const SizedBox(width: 20),
                      _buildLegendItem(Colors.red, getTranslated(context, "Indisponible")!),
                      const SizedBox(width: 20),
                      _buildLegendItem(pcolor, getTranslated(context, "Aujourd'hui")!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoadingDisponibilite)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_disponibiliteData != null)
                  _buildCalendarGrid()
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            getTranslated(context, "Aucune disponibilité")!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_disponibiliteData != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          pcolor.withOpacity(0.05),
                          pcolor.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pcolor.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.calendar_month,
                          getTranslated(context, "Total")!,
                          _disponibiliteData!['statistiques']['jours_totaux'].toString(),
                          Colors.grey[700]!,
                        ),
                        _buildStatItem(
                          Icons.check_circle,
                          getTranslated(context, "Disponible")!,
                          _disponibiliteData!['statistiques']['jours_disponibles'].toString(),
                          Colors.green,
                        ),
                        _buildStatItem(
                          Icons.cancel,
                          getTranslated(context, "Indisponible")!,
                          _disponibiliteData!['statistiques']['jours_indisponibles'].toString(),
                          Colors.red,
                        ),
                        _buildStatItem(
                          Icons.trending_up,
                          getTranslated(context, "Taux")!,
                          "${_disponibiliteData!['statistiques']['taux_disponibilite'].toStringAsFixed(1)}%",
                          pcolor,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final disponibilites = _disponibiliteData!['disponibilites'] as List<dynamic>;
    final List<String> weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final List<String> weekDaysAr = ['إثن', 'ثلاث', 'أربع', 'خميس', 'جمعة', 'سبت', 'أحد'];

    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    int firstWeekday = firstDay.weekday - 1;
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final totalDays = firstWeekday + daysInMonth;
    final numberOfWeeks = (totalDays / 7).ceil();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: pcolor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(
              7,
              (index) => Expanded(
                child: Text(
                  _isArabic ? weekDaysAr[index] : weekDays[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: pcolor,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          numberOfWeeks,
          (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: List.generate(
                  7,
                  (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                    final date = DateTime(_selectedYear, _selectedMonth, dayNumber);
                    final isInMonth = date.month == _selectedMonth;

                    if (!isInMonth) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          child: const SizedBox.shrink(),
                        ),
                      );
                    }

                    final dateStr = DateFormat('yyyy-MM-dd').format(date);
                    final disponibilite = disponibilites.firstWhere(
                      (d) => d['date'] == dateStr,
                      orElse: () => {'disponible': true},
                    );
                    final isAvailable = disponibilite['disponible'] ?? true;
                    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());

                    String dayName = '';
                    if (_isArabic) {
                      dayName = disponibilite['jour_semaine_ar'] ?? '';
                    } else {
                      dayName = disponibilite['jour_semaine'] ?? '';
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isAvailable) {
                            setState(() {
                              dateDebutController.text = dateStr;
                              dateFinController.text = dateStr;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Date sélectionnée: $dateStr"),
                                duration: const Duration(seconds: 1),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isAvailable 
                                ? (isToday ? Colors.green[100] : Colors.green[50])
                                : (isToday ? Colors.red[100] : Colors.red[50]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAvailable 
                                  ? (isToday ? Colors.green[400]! : Colors.green[200]!)
                                  : (isToday ? Colors.red[400]! : Colors.red[200]!),
                              width: isToday ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayNumber.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isAvailable ? Colors.green[600] : Colors.red[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==================== CARACTÉRISTIQUES ====================
  Widget _buildFeatureInfo() {
    final String villeNom = _getVilleNom();
    final String adresse = _getAdresse();
    final double surface = (maisonDetail?['surface'] ?? 0).toDouble();
    final bool avecServices = maisonDetail?['avec_services'] ?? false;
    final bool meubler = maisonDetail?['meubler'] ?? false;
    final double ratings = (maisonDetail?['ratings'] ?? 0).toDouble();

    List<Map<String, dynamic>> featureItems = [];

    if (villeNom.isNotEmpty) {
      featureItems.add({
        'image': 'assets/images/localisation.jpeg',
        'text': villeNom,
      });
    }

    if (surface > 0) {
      featureItems.add({
        'image': 'assets/images/type_operation.jpeg',
        'text': '${surface.round()} ${getTranslated(context, "m²")}',
      });
    }

    if (avecServices) {
      featureItems.add({
        'image': 'assets/images/type_operation.jpeg',
        'text': getTranslated(context, "Services inclus")!,
      });
    }

    if (meubler) {
      featureItems.add({
        'image': 'assets/images/type_operation.jpeg',
        'text': getTranslated(context, "Meublé")!,
      });
    }

    if (ratings > 0) {
      featureItems.add({
        'image': 'assets/images/type_operation.jpeg',
        'text': '${ratings.toStringAsFixed(1)} ★',
      });
    }

    // Ajouter le type d'opération
    featureItems.add({
      'image': 'assets/images/type_operation.jpeg',
      'text': _getOperationType(),
    });

    if (featureItems.isEmpty) {
      return const SizedBox.shrink();
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
                item['image'],
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['text'],
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== INFRASTRUCTURES ====================
  Widget _buildInfrastructureSection() {
    final List<dynamic> infrastructures = maisonDetail?['infrastructures_proches'] ?? [];

    if (infrastructures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "Entourage du maison")!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    _getImageForInfrastructure(
                      _isArabic ? infra['type_infrastructure_ar'] : infra['type_infrastructure'],
                    ),
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isArabic ? infra['nom_ar'] : infra['nom'],
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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

  // ==================== DESCRIPTION ====================
  Widget _buildDescriptionSection() {
    final String description = _getDescription();

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          _DescriptionSection(
            description: description,
            isArabic: _isArabic,
          ),
        ],
      ),
    );
  }

  // ==================== MAP ====================
  Widget _buildMapSection() {
    final String villeNom = _getVilleNom();

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
                target: _initialPosition,
                zoom: 12.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: _initialPosition,
                  infoWindow: InfoWindow(title: villeNom),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==================== REVIEWS ====================
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
              onPressed: _showAddReviewDialog,
              icon: const Icon(Icons.add, color: pcolor),
              label: Text(
                getTranslated(context, "Ajouter un avis")!,
                style: const TextStyle(color: pcolor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

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
                          color: index < averageRating.floor() ? Colors.amber : Colors.grey[300],
                        ),
                      ),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        getTranslated(context, "Note moyenne")!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

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
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.add),
                  label: Text(getTranslated(context, "Soyez le premier à donner votre avis")!),
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
              final comment = _isArabic && review['comment_ar']?.isNotEmpty == true
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['user_name'] ?? getTranslated(context, "Utilisateur")!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.parse(review['created_at'])),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                              color: index < (review['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (comment?.isNotEmpty == true)
                      Text(
                        comment,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: _isArabic ? 'Arabic' : null,
                        ),
                        // textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ==================== DESCRIPTION SECTION ====================
class _DescriptionSection extends StatefulWidget {
  final String description;
  final bool isArabic;

  const _DescriptionSection({
    required this.description,
    required this.isArabic,
  });

  @override
  __DescriptionSectionState createState() => __DescriptionSectionState();
}

class __DescriptionSectionState extends State<_DescriptionSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.description,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            // textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
            // fontFamily: widget.isArabic ? 'Arabic' : null,
          ),
        ),
        Align(
          alignment: widget.isArabic ? Alignment.centerLeft : Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.isArabic ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Text(
                  isExpanded
                      ? getTranslated(context, "Voir moins")!
                      : getTranslated(context, "Voir plus")!,
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(width: 5),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}