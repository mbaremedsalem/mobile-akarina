import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';


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
        leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar' 
              ? IconBroken.Arrow___Right_2 // Icône pour l'arabe (flèche à droite)
              : IconBroken.Arrow___Left_2, // Icône pour le français (flèche à gauche)
              color: kBlackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title:  Text(getTranslated(context, "Détails de l'immobilier")!,style: TextStyle(color: kBlackColor),),
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
                          
                          _contact(),
                          SizedBox(height: getProportionateScreenHeight(5)),
                           _buildPriceAndStatusHeader(),
                           SizedBox(height: getProportionateScreenHeight(5)),
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
          offset: Offset(0, 2),
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
            borderRadius: BorderRadius.circular(getProportionateScreenWidth(8.0)),
          ),
          child: Text(
            available
                ? getTranslated(context, "Disponible") ?? "Disponible"
                : getTranslated(context, "Non disponible") ?? "Non disponible",
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
    const phoneNumber = '1234567890'; // Remplacez par votre numéro
    const message = 'Bonjour, je vous contacte depuis l\'application';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Impossible d\'ouvrir WhatsApp';
    }
  }

  // Fonction pour le bouton Téléphone
  void _launchPhone() async {
    const phoneNumber = '20203000'; // Remplacez par votre numéro
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
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, color: Colors.white, size: 24),
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
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(getTranslated(context, "Contact")!
                          ,
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
// head price 
Widget _buildPriceAndStatusHeader() {
  // Récupération des données
  final typeOperation = immobData?['type_operation'] ?? 'vendre';
  final montant = double.tryParse(immobData?['montant']?.toString() ?? '0');
  final loyerMensuel = double.tryParse(immobData?['loyer_mensuel']?.toString() ?? '0');
  final periode = immobData?['periode'] ?? 'mois';
  final isAvailable = immobData?['available'] ?? false;

  return LayoutBuilder(
    builder: (context, constraints) {
      final bool isSmallScreen = constraints.maxWidth < 350;
      
      return Container(
        margin: EdgeInsets.symmetric(
       
        ),
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
            // Partie Prix - Adapte la taille en fonction de l'écran
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
                      padding: EdgeInsets.only(top: getProportionateScreenHeight(4)),
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

            // Partie Disponibilité - S'adapte à la largeur disponible
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
                  color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(getProportionateScreenWidth(20)),
                  border: Border.all(
                    color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
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
                          color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
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
  if (images.isEmpty) {
    return Text(getTranslated(context, "Aucune image disponible.") ?? getTranslated(context, "Aucune image disponible.")!);
  }

  return FutureBuilder<Locale>(
    future: getLocale(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // Afficher un indicateur de chargement pendant le chargement de la langue
      }

      bool isArabic = snapshot.data?.languageCode == ARABIC;

      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SizedBox(
          height: getProportionateScreenHeight(280), // Hauteur responsive
          child: Column(
            children: [
              // Première ligne : Grande image à gauche et deux petites images à droite
              Expanded(
                flex: 2, // Prend 2/3 de l'espace disponible
                child: Row(
                  children: [
                    // Grande image à gauche
                    if (images.isNotEmpty)
                      Expanded(
                        flex: 2, // Prend 2/3 de l'espace disponible
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: isArabic ? 0.0 : getProportionateScreenWidth(4.0), // Padding responsive
                            left: isArabic ? getProportionateScreenWidth(4.0) : 0.0,
                          ),
                          child: _buildImage(images[0]['image'], 0, images),
                        ),
                      ),
                    // Deux petites images à droite
                    if (images.length > 1)
                      Expanded(
                        flex: 1, // Prend 1/3 de l'espace disponible
                        child: Column(
                          children: [
                            if (images.length > 1)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: getProportionateScreenHeight(4.0)),
                                  child: _buildImage(images[1]['image'], 1, images),
                                ),
                              ),
                            if (images.length > 2)
                              Expanded(
                                child: _buildImage(images[2]['image'], 2, images),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Espacement entre les lignes
              SizedBox(height: getProportionateScreenHeight(4.0)),
              // Deuxième ligne : Trois images en bas
              if (images.length > 3)
                Expanded(
                  flex: 1, // Prend 1/3 de l'espace disponible
                  child: Row(
                    children: [
                      for (int i = 3; i < 6 && i < images.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(2.0)),
                            child: _buildImage(images[i]['image'], i, images),
                          ),
                        ),
                    ],
                  ),
                ),
              // Texte traduit
            ],
          ),
        ),
      );
    },
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
              padding: const EdgeInsets.symmetric(horizontal: 0.0), // Ajuster le padding
              child: InkWell(
                onTap: () {
                  // Valeurs par défaut pour l'image et le nom
                  final participantImage = user.image?.isNotEmpty == true
                      ? user.image!
                      : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png';

                  final participantName = user.nomComplet?.isNotEmpty == true
                      ? user.nomComplet!
                      : getTranslated(context, "Utilisateur inconnu")!;

                  // Naviguer vers la page de chat avec l'image et l'ID du participant
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        participantId: user.id,
                        participantImage: participantImage, // Utiliser la valeur par défaut si nécessaire
                        participantName: participantName, // Utiliser la valeur par défaut si nécessaire
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
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              user.image?.isNotEmpty == true
                                  ? user.image!
                                  : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png',
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2, // Ajuster la position pour correspondre au design
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green, // Statut en ligne
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Espace entre le cercle et le nom
                    SizedBox(
                      width: 70, // Ajuster la largeur pour les noms
                      child: Text(
                        user.nomComplet?.isNotEmpty == true
                            ? user.nomComplet!
                            : getTranslated(context, "Utilisateur inconnu")!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center, // Centrer le nom
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500, // Ajuster le poids de la police pour l'emphase
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
    {'image': 'assets/images/type_operation.jpeg', 'text': '${immobData?['surface']} ${getTranslated(context, "km")}'},
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
}

class FullScreenImageView extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageView({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

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

  const _DescriptionSection({super.key, required this.description});

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





