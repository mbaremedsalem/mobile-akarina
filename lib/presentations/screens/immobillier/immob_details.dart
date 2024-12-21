import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/models/user.dart';

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
                          SizedBox(height: getProportionateScreenHeight(10)), 
                          // Section pour les utilisateurs
                          _buildUsersSection(),
                          SizedBox(height: getProportionateScreenHeight(20)),
                          // Disponibilité
                          // Informations principales (icônes des caractéristiques)
                          _buildFeatureInfo(),
                          const SizedBox(height: 20),

                          // Entourage du maison (icônes des infrastructures)
                          _buildInfrastructureSection(),
                          const SizedBox(height: 20),

                          // Description de la maison
                          _buildDescriptionSection(immobData?['description'] ?? getTranslated(context, "Pas de description disponible.")),
                          const SizedBox(height: 20),

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

  // Fonction pour afficher chaque image
  Widget _buildImage(String imageUrl, int index, List<dynamic> images) {
    return GestureDetector(
      onTap: () {
        // Ouvrir l'image en plein écran
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageView(
              imageUrls: images.map<String>((image) => image['image']).toList(),
              initialIndex: index,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
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
        return Center(child: Text('Erreur lors du chargement des utilisateurs'));
      } else if (snapshot.hasData && snapshot.data!.isEmpty) {
        return Center(child: Text('Aucun utilisateur trouvé.'));
      } else if (snapshot.hasData) {
        return SizedBox(
          height: getProportionateScreenHeight(100), // Adjust height for user circle and name
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              User user = snapshot.data![index];
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0), // Adjust padding
                child: InkWell(
                                      onTap: () {
                      // Naviguer vers la page de chat avec l'image et l'ID du participant
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            participantId: user.id,
                            participantImage: user.image, // Passer l'image
                            participantName: user.nomComplet, // Passer le nom pour l'AppBar
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
                            radius: 30,
                            backgroundImage: NetworkImage(user.image),
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
                          user.nomComplet,
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
        return SizedBox.shrink();
      }
    },
  );
}

// Section pour afficher les caractéristiques sous forme de grille
Widget _buildFeatureInfo() {
  List<Map<String, dynamic>> featureItems = [
    {'icon': Icons.house, 'text': 'Built in ${immobData?['annee_de_construction']}'},
    {'icon': Icons.bed, 'text': '${immobData?['nombre_de_chambres']} Chambres'},
    {'icon': Icons.garage, 'text': '${immobData?['nombre_de_garages']} Garage'},
    {'icon': Icons.kitchen, 'text': '4 Kitchens'},
    {'icon': Icons.home, 'text': '6 Hall'},
  ];

  return GridView.builder(
    shrinkWrap: true,  // Ensures that the GridView takes only the necessary height
    physics: NeverScrollableScrollPhysics(), // Prevent scrolling inside GridView
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,  // Number of items per row
      crossAxisSpacing: 10,  // Horizontal space between items
      mainAxisSpacing: 10,  // Vertical space between items
      childAspectRatio: 3.5,  // Width to height ratio (adjust for your design)
    ),
    itemCount: featureItems.length,
    itemBuilder: (context, index) {
      var item = featureItems[index];
      return _buildFeatureCard(item['icon'], item['text']);
    },
  );
}

Widget _buildFeatureCard(IconData icon, String text) {
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
        Icon(icon, size: 30, color: pcolor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}


// Section pour afficher les infrastructures proches sous forme de grille
Widget _buildInfrastructureSection() {
  List<dynamic> infrastructures = immobData?['infrastructures_proches'] ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Entourage du maison',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true, // Ensures GridView takes only necessary space
        physics: NeverScrollableScrollPhysics(), // Prevents internal scrolling
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of items per row
          crossAxisSpacing: 10, // Horizontal spacing between items
          mainAxisSpacing: 10, // Vertical spacing between rows
          childAspectRatio: 3.5, // Adjust to control height/width ratio
        ),
        itemCount: infrastructures.length,
        itemBuilder: (context, index) {
          var infra = infrastructures[index];
          return _buildInfrastructureCard(infra['nom']);
        },
      ),
    ],
  );
}

Widget _buildInfrastructureCard(String infraName) {
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
        Icon(Icons.location_city, color: pcolor),
        const SizedBox(width: 10),
        Expanded( // To prevent overflow and handle long text
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

// Section de la description de la maison
Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description du maison',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // Section Google Maps pour la localisation
  Widget _buildMapSection(Map<String, dynamic>? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation du maison',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
