import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/models/user.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';


import 'dart:developer';

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class ImmobDetails extends StatefulWidget {
  final int id;

  const ImmobDetails({Key? key, required this.id}) : super(key: key);

  @override
  State<ImmobDetails> createState() => _ImmobDetailsState();
}

class _ImmobDetailsState extends State<ImmobDetails> {
  LatLng _initialPosition = const LatLng(48.8566, 2.3522);
  bool isLoading = true;
  Map<String, dynamic>? immobData;
  GoogleMapController? _controller;
  late Future<List<User>> futureUsers;

  @override
  void initState() {
    super.initState();
    fetchImmobDetails();
    futureUsers = NetworkService().fetchUsers(context);
  }

  Future<void> fetchImmobDetails() async {
    try {
      var data = await NetworkService().fetchImmobDetails(widget.id);
      setState(() {
        immobData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(getTranslated(context, "Détails de l'immobilier")!),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : immobData == null
                ?  Center(child: Text(getTranslated(context, "Aucune donnée trouvée.")!))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section pour les images
                          _buildImageSection(immobData?['images'] ?? []),
                          // Removed or reduced the SizedBox height to reduce space
                          SizedBox(height: getProportionateScreenHeight(5)), 
                          // Section pour les utilisateurs
                          _buildUsersSection(),
                         
                          // Disponibilité
                          // Informations principales (icônes des caractéristiques)
                          _buildFeatureInfo(),
                          const SizedBox(height: 10),

                          // Entourage du maison (icônes des infrastructures)
                          _buildInfrastructureSection(),
                          const SizedBox(height: 10),

                          // Description de la maison
                          FutureBuilder<String>(
                          future: getCurrentLanguage(context), // Appelle la méthode pour récupérer la langue actuelle
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator(); // Affiche un loader pendant le chargement
                            } else if (snapshot.hasError) {
                              return Text(getTranslated(context, "Erreur lors du chargement de la langue")!); // Gestion des erreurs
                            } else {
                              // Récupère la langue actuelle
                              final currentLanguage = snapshot.data ?? ARABIC;

                              // Sélectionne la bonne description en fonction de la langue
                              final descriptionKey = currentLanguage == ARABIC ? 'description_ar' : 'description';

                              return _buildDescriptionSection(
                                immobData?[descriptionKey] ?? getTranslated(context, "Pas de description disponible."),
                              );

                            }
                          },
                        ),

                          const SizedBox(height: 10),

                          // Localisation du maison (Google Maps)
                          _buildMapSection(immobData),
                          
                        ],
                      ),
                    ),
                  ),
      ),
    );

  }




  // Section pour afficher les images
  Widget _buildImageSection(List<dynamic> images) {
    if (images.isEmpty) {
      return const Text('Aucune image disponible.');
    }

    return Container(
      height: getProportionateScreenHeight(280),
      child: Column(
        children: [
          Row(
            children: [
              // Grande image à gauche
              if (images.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: _buildImage(images[1]['image'], 1, images),
                        ),
                      if (images.length > 2)
                        _buildImage(images[2]['image'], 2, images),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4.0),
          // Trois images en bas
          if (images.length > 3)
            Row(
              children: [
                for (int i = 3; i < 6 && i < images.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: _buildImage(images[i]['image'], i, images),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
bool isValidImageUrl(String? url) {
  return url != null && url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true;
}
  // Fonction pour afficher chaque image
Widget _buildImage(String imageUrl, int index, List<dynamic> images) {
  return GestureDetector(
    onTap: () {
      // Ouvrir l'image en plein écran
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageView(
            imageUrls: images.map<String>((image) => image['image'] ?? '').toList(),
            initialIndex: index,
          ),
        ),
      );
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: isValidImageUrl(imageUrl)
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
              },
            )
          : const Icon(Icons.broken_image, size: 80, color: Colors.grey), // Placeholder en cas d'URL invalide
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
        return const Center(child: Text('Erreur lors du chargement des utilisateurs'));
      } else if (snapshot.hasData && snapshot.data!.isEmpty) {
        return const Center(child: Text('Aucun utilisateur trouvé.'));
      } else if (snapshot.hasData) {
        return SizedBox(
          height: getProportionateScreenHeight(90), // Adjust height for user circle and name
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              User user = snapshot.data![index];
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0), // Adjust padding
                child: InkWell(
                                      onTap: () {
                      // Naviguer vers la page de chat avec l'image et l'ID du participant
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            participantId: user.id,
                            participantImage: user.image!, // Passer l'image
                            participantName: user.nomComplet!, // Passer le nom pour l'AppBar
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
                            radius: 32,
                            backgroundColor: pcolor,
                            child: 
                            CircleAvatar(
                            radius: 30,
                            backgroundImage: user.image != null && user.image!.isNotEmpty
                                ? NetworkImage(user.image!)
                                : const NetworkImage('https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png'),
                            ),
                            
                            // CircleAvatar(
                            //   radius: 30,
                            //   backgroundImage: NetworkImage(user.image!),
                            // ),
                          ),
                          Positioned(
                            bottom: 2, // Adjust position to fit the design
                            right: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green, // Online status
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Space between circle and name
                      SizedBox(
                        width: 70, // Adjust width to fit names
                        child: Text(
                          user.nomComplet!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center, // Center align the name
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500, // Adjust font weight for emphasis
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
  List<Map<String, dynamic>> featureItems = [
    {'image': 'assets/images/chambre.jpeg', 'text': '${immobData?['nombre_de_chambres']} ${getTranslated(context, "Chambres")}'},
    {'image': 'assets/images/douche.jpeg', 'text': '${immobData?['nombre_de_salles_de_bain']} ${getTranslated(context, "Salle de bain")}'},
    {'image': 'assets/images/garage.jpeg', 'text': '${immobData?['nombre_de_garages']} ${getTranslated(context, "Garage")}'},
    {'image': 'assets/images/localisation.jpeg', 'text': '${immobData?['adresse']}'},
    {'image': 'assets/images/type_operation.jpeg', 'text': '${getTranslated(context, "${immobData?['type_operation']}")}'},
    {'image': 'assets/images/type_operation.jpeg', 'text': '${immobData?['surface']}'},
    {'image': 'assets/images/gardain.jpeg', 'text': immobData?['presence_de_jardin']?'${getTranslated(context, "avec")}':'${getTranslated(context, "sans")}'},
    {'image': 'assets/images/etage.jpeg', 'text': immobData?['nombre_d_etages'] != null?'${getTranslated(context, "avec")}':'${getTranslated(context, "sans")}'},
    {'image': 'assets/images/pisume.jpeg', 'text': immobData?['presence_de_pisime']?'${getTranslated(context, "avec")}':'${getTranslated(context, "sans")}'},
    {'image': 'assets/images/wifi.jpeg', 'text': immobData?['presence_de_wifi']?'${getTranslated(context, "avec")}':'${getTranslated(context, "sans")}'},
    {'image': 'assets/images/type_operation.jpeg', 'text': immobData?['meubler'] ? '${getTranslated(context, "Meubler")}' : '${getTranslated(context, "pas Meubler")}'},
  ];

  return GridView.builder(
    shrinkWrap: true,  // Ensures that the GridView takes only the necessary height
    physics: const NeverScrollableScrollPhysics(), // Prevent scrolling inside GridView
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,  // Number of items per row
      crossAxisSpacing: 10,  // Horizontal space between items
      mainAxisSpacing: 10,  // Vertical space between items
      childAspectRatio: 3.5,  // Width to height ratio (adjust for your design)
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
          imagePath, // Utiliser l'image passée en paramètre
          width: 30, // Taille de l'image
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

// Section pour afficher les infrastructures proches sous forme de grille


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
      return 'assets/images/store.png'; // Image par défaut si le type est inconnu
  }
}
Widget _buildInfrastructureSection() {
  List<dynamic> infrastructures = immobData?['infrastructures_proches'] ?? [];

  return FutureBuilder<String>(
    future: getCurrentLanguage(context), // Récupère la langue sélectionnée
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator(); // Affiche un loader pendant le chargement
      } else if (snapshot.hasError) {
        return Text(getTranslated(context, "Erreur lors du chargement de la langue")!);
      } else {
        final currentLanguage = snapshot.data ?? ARABIC; // Définit la langue par défaut
        final isArabic = currentLanguage == ARABIC; // Vérifie si la langue est l'arabe

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
                return _buildInfrastructureCard(
                  isArabic ? infra['nom_ar'] : infra['nom'], // Nom en fonction de la langue
                  _getImageForInfrastructure(
                    isArabic ? infra['type_infrastructure_ar'] : infra['type_infrastructure'],
                  ), // Image selon le type et la langue
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
          imagePath, // Utilise l'image selon le type
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

// Section Google Maps pour la localisation
Widget _buildMapSection(Map<String, dynamic>? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          getTranslated(context, "Localisation du maison")!,
          style:const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  double.parse(data?['y'] ?? '48.8566'),
                  double.parse(data?['x'] ?? '2.3522'),
                ),
                zoom: 12.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: LatLng(
                    double.parse(data?['y'] ?? '48.8566'),
                    double.parse(data?['x'] ?? '2.3522'),
                  ),
                  infoWindow: InfoWindow(title: data?['nom_ville']),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }











  // Fonction pour afficher la popup
  void showPaymentPopup(BuildContext context) {
    final currentContext = context; // Sauvegarde du contexte actuel
    showDialog(
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Choisissez une méthode de paiement",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildPaymentCard(
                  context,
                  "Masrivi",
                  "assets/images/masrivi.png",
                  () => createTransaction(currentContext, "10", "929", "Achat de produits"),
                ),
                _buildPaymentCard(context, "Bankily", "assets/images/bankily.png", () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bankily sélectionné")),
                  );
                }),
                _buildPaymentCard(context, "Seddadd", "assets/images/seddadd.png", () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Seddadd sélectionné")),
                  );
                }),
                _buildPaymentCard(context, "Stripe", "assets/images/stripe.png", () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Stripe sélectionné")),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  // Fonction pour construire une carte de méthode de paiement
  Widget _buildPaymentCard(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(); // Ferme la popup
        onTap(); // Exécute l'action spécifique à la méthode de paiement
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour créer une transaction


// Fonction pour créer une transaction
Future<void> createTransaction(BuildContext context, String amount, String currency, String description) async {
  const String apiUrl = "http://165.227.85.96/ayadi/create_transaction/";

  try {
    // Requête POST vers l'API
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "amount": amount,
        "currency": currency,
        "description": description,
      }),
    );

    if (response.statusCode == 200) {
      log("✅ Response Status Code: 200");
      log("📝 Response Body:\n${response.body}");

      // Vérifier si la réponse est JSON ou HTML
      if (response.headers["content-type"]?.contains("application/json") == true) {
        final responseData = jsonDecode(response.body);
        final paymentUrl = responseData['payment_url'];

        if (paymentUrl != null && context.mounted) {
          log("✅ URL de paiement récupérée: $paymentUrl");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebView(
                paymentUrl: paymentUrl,
                onPaymentSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Successful')),
                  );
                },
                onPaymentError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Failed')),
                  );
                },
              ),
            ),
          );
        } else {
          log("❌ Erreur : URL de paiement introuvable");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur : URL de paiement introuvable")),
          );
        }
      } else {
        // Si la réponse est HTML, extraire l'URL depuis le formulaire
        final regex = RegExp(r'action="([^"]+)"');
        final match = regex.firstMatch(response.body);

        if (match != null && context.mounted) {
          final extractedUrl = match.group(1);
          log("✅ URL de paiement extraite: $extractedUrl");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebView(
                paymentUrl: extractedUrl!,
                onPaymentSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Successful')),
                  );
                },
                onPaymentError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Failed')),
                  );
                },
              ),
            ),
          );
        } else {
          log("❌ Impossible d'extraire l'URL de paiement");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur : Impossible d'extraire l'URL de paiement")),
          );
        }
      }
    } else {
      log("❌ Erreur HTTP ${response.statusCode} - ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${response.statusCode} - ${response.body}")),
      );
    }
  } catch (e, stacktrace) {
    log("🚨 Exception: $e");
    log("📜 Stacktrace: $stacktrace");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }
}




}

class FullScreenImageView extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageView({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}


Widget _buildDescriptionSection(String description) {
  return _DescriptionSection(description: description);
}

class _DescriptionSection extends StatefulWidget {
  final String description;

  const _DescriptionSection({Key? key, required this.description}) : super(key: key);

  @override
  __DescriptionSectionState createState() => __DescriptionSectionState();
}

class __DescriptionSectionState extends State<_DescriptionSection> {
  bool isExpanded = false; // Indique si le texte est étendu

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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              // Utilisation de TextPainter pour vérifier si le texte dépasse 3 lignes
              final textPainter = TextPainter(
                text: TextSpan(
                  text: widget.description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                maxLines: 3,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final exceedsLimit = textPainter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.description,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      maxLines: isExpanded ? null : 3, // Afficher tout ou limiter à 3 lignes
                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (exceedsLimit)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded; // Bascule entre étendu et limité
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ?getTranslated(context, "Voir moins")!:getTranslated(context, "Voir plus")!,
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
            },
          ),
        ],
      ),
    );
  }
}





// -------------  ////////
// Fonction pour afficher la popup

// Page WebView pour afficher la session de paiement


// Page WebView pour afficher la session de paiement
class PaymentWebView extends StatefulWidget {
  final String paymentUrl; // URL pour le WebView
  final Function? onPaymentSuccess; // Callback pour succès
  final Function? onPaymentError; // Callback pour erreur

  const PaymentWebView({
    Key? key,
    required this.paymentUrl,
    this.onPaymentSuccess,
    this.onPaymentError,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    final WebViewController controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            _progressNotifier.value = progress; // Met à jour la progression
          },
          onPageStarted: (String url) {
            log('Page started loading: $url');
          },
          onPageFinished: (String url) {
            log('Page finished loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            log('Redirecting to: ${request.url}');
            if (request.url.contains('success')) {
              widget.onPaymentSuccess?.call();
              Navigator.pop(context);
              return NavigationDecision.prevent;
            } else if (request.url.contains('error')) {
              widget.onPaymentError?.call();
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },

        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            ValueListenableBuilder<int>(
              valueListenable: _progressNotifier,
              builder: (context, progress, child) {
                return progress < 100
                    ? LinearProgressIndicator(value: progress / 100.0)
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
