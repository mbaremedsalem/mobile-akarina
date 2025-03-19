
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/skeleton/home_skeleton.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/appartement/appartement.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Category extends StatefulWidget {
  // final String token;

  const Category({Key? key}) : super(key: key);

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  Map<String, dynamic>? categories;
  bool isLoading = true;
  bool isClicked = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: 
        isLoading
          ?  ImmobilierCategorykeleton()
          : categories == null
              ? const Center(child: Text('Erreur lors de la récupération des catégories'))
              : ListView(
                  children: [
                    _buildCategoryTile("Appartement", categories!['appartements']),
                    _buildCategoryTile("Duplex", categories!['duplexes']),
                    _buildCategoryTile("Commercial", categories!['commerciaux']),
                    _buildCategoryTile("Terrain", categories!['terrains']),
                    _buildCategoryTile("Residentiel", categories!['residentiels']),
                  ],
                ),
   
    );
  }

  Widget _buildCategoryTile(String categoryName, Map<String, dynamic> categoryData) {
           String imagePath;
            if (categoryData['name'] == 'Appartement') {
              imagePath = 'assets/images/appartement.png';
            } else if (categoryData['name'] == 'Duplex') {
              imagePath = 'assets/images/duplex 1.png';
            } else if (categoryData['name'] == 'Commercial') {
              imagePath = 'assets/images/commercial.jpg';
            } else if (categoryData['name'] == 'Terrain') {
              imagePath = 'assets/images/terrain 1.png';
            } else if (categoryData['name'] == 'Residentiel') {
              imagePath = 'assets/images/maison meuble 1.png';
            } else {
              imagePath = 'assets/images/default.png'; // Image par défaut si aucune condition n'est satisfaite
            }
            return InkWell(
              onTap: (){
                
              },
              child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: (){
                                
                              },
                              child: Container(
                                height: getProportionateScreenHeight(33),
                                width: MediaQuery.of(context).size.width,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    topRight: Radius.circular(7),
                                  ),
                                  color: pcolor
                                ),
                                child:  Center(
                                child: Text(categoryData['name']+'   '+'${categoryData['count']}',
                                style: const TextStyle(
                                color: kWhiteColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900
                              ),
                              ),
                              ),
                              ),
                            ),
              
                            Stack(
                              children: [
                                InkWell(
                                  onTap: (){
                                    // Déterminer l'URL de l'API en fonction de la catégorie
                                    String apiUrl;
                                    switch (categoryName.toLowerCase()) {
                                      case 'appartement':
                                        apiUrl = 'https://akarina.online/akareena/appartements/';
                                        break;
                                      case 'duplex':
                                        apiUrl = 'https://akarina.online/akareena/duplexes/';
                                        break;
                                      case 'commercial':
                                        apiUrl = 'https://akarina.online/akareena/commerciaux/';
                                        break;
                                      case 'terrain':
                                        apiUrl = 'https://akarina.online/akareena/terrains/';
                                        break;
                                      case 'residentiel':
                                        apiUrl = 'https://akarina.online/akareena/residentiels/';
                                        break;
                                      default:
                                        apiUrl = ''; // Gérer les cas non prévus
                                    }                
                                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  Appartement(apiUrl: apiUrl,count:categoryData['count'])));
              
                                  },
                                  child: Container(
                                    height: getProportionateScreenHeight(100),
                                    width: MediaQuery.of(context).size.width,
                                    decoration:  BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                      image: DecorationImage(
                                        image: 
                                         AssetImage(imagePath)
                                          , 
                                        fit: BoxFit.cover, 
                                      ),
                                    ),
                                  ),
                                ),
                                 Positioned(
                                  left: 10,
                                  top: 10,
                                  right: 10,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: getProportionateScreenWidth(80),
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(5)),
                                          color: pcolor),
                                        child: const Center(
                                          child: Text(
                                            '3 days ago',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
              
                                      const Icon(
                                        IconBroken.Heart,
                                        color: kredcolor,
                                      ),
                                    ],
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



