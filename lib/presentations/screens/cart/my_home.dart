import 'dart:ffi';

import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/label.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/input.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}


class _MyHomeState extends State<MyHome> {
  List<PropertyType?> centresList = [];
  PropertyType? selectedProperty;
  TextEditingController montantController = TextEditingController();
  TextEditingController regionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  List<dynamic> filteredProperties = [];
  bool is_loading=true;
  @override
  void initState() {
    super.initState();
    centresList = [
      PropertyType(name: 'Appartement'),
      PropertyType(name: 'Duplex'),
      PropertyType(name: 'Commercial'),
      PropertyType(name: 'Terrain'),
      PropertyType(name: 'Residentiel'),
    ];
  }
  final storage = FlutterSecureStorage();
  late NetworkService? networkService;
  Future<void> fetchProperties() async {
    if (selectedProperty != null) {
      String? type = selectedProperty?.name;
      String montant = montantController.text;
      String region = regionController.text;
      String location = locationController.text;

      final url = Uri.parse(
        'https://akarina-9865f1a90dee.herokuapp.com/akareena/models/filter/$type/?region=$region&location=$location&max_rent=$montant'
      );
      
      final response = await http.get(
        url,
      );

      if (response.statusCode == 200) {

        setState(() {
          filteredProperties = json.decode(response.body);
          is_loading=true;
        });
        
      } else {
        print('Failed to load properties: ${response.statusCode}');

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 0),
      child: Column(
        children: [
          // Your existing widgets here
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              Expanded(
                child: Container(
                width: double.infinity, // Largeur maximale
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Marges internes
                decoration: BoxDecoration(
                  border: Border.all(color: pcolor), // Bordure
                  borderRadius: BorderRadius.circular(10), // Coins arrondis
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PropertyType?>(
                    value: selectedProperty,  // L'option actuellement sélectionnée
                    icon: const Icon(Icons.arrow_downward),  // Icône du menu déroulant
                    hint: Text(
                        getTranslated(context, 'Selectionner le Type')!,
                        style: textstyle.copyWith(
                          fontSize: getProportionateScreenWidth(12),
                        ),
                      ),
                    iconSize: 24,  // Taille de l'icône
                    elevation: 16,  // Élévation du menu
                    style: const TextStyle(color: pcolor),  // Style du texte
                    onChanged: (PropertyType? newValue) {
                      setState(() {
                        selectedProperty = newValue;  // Met à jour la valeur sélectionnée
                      });
                    },
                    items: centresList.map((PropertyType? item) {
                      return DropdownMenuItem<PropertyType?>(
                        value: item,
                        child: Text(getTranslated(context, '${item?.name}')!,),
                      );
                    }).toList(),
                  ),
                ),
              ),
                            
              ),
              
              SizedBox(width: getProportionateScreenWidth(3)),
              Expanded(
                child: defaultInputField(
                controller: montantController,
                type: TextInputType.number,
                text: getTranslated(context, 'montant')!,
                prefix: Icons.euro_rounded,
                
                ), 

              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(6),),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: 
                defaultInputField(
                controller: locationController,
                type: TextInputType.text,
                text: getTranslated(context, 'location')!,
                prefix: Icons.location_on_outlined,
                
                ),          
              ),
              
              SizedBox(width: getProportionateScreenWidth(3)),
              Expanded(
                child: defaultInputField(
                controller: regionController,
                type: TextInputType.text,
                text: getTranslated(context, 'region')!,
                prefix: Icons.recycling_outlined,
                
                ), 
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(6),),
          is_loading?
               Defaultbutton(
                          onTap:(){
                            setState(() {
                              is_loading=false;
                              });
                            fetchProperties();
                          } ,
                          color: pcolor,
                          textcolor: kWhiteColor,
                          text: getTranslated(context, 'Search')!,
                          borderRadius: getProportionateScreenWidth(5),
                          width: getProportionateScreenWidth(500),
                          height: getProportionateScreenHeight(30),
                        )
                        :spiner(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredProperties.length,
                            itemBuilder: (context, index) {
                              var property = filteredProperties[index];
                              return 
                              Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                        InkWell(
                                        onTap: (){
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ImmobDetails(id: property['id']),
                                              ),
                                    );
                                },
                                child: Container(
                                  height: getProportionateScreenHeight(100),
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    image: DecorationImage(
                          //                                       String imageUrl = 'https://via.placeholder.com/150';
                          // if (property['images'] != null && property['images'].isNotEmpty) {
                          //   imageUrl = immobilier['images'][0]['image'];
                          // }
                                      image: NetworkImage((property['images'] != null && property['images'].isNotEmpty)?'https://akarina-9865f1a90dee.herokuapp.com${property['images'][0]['image']}':'https://via.placeholder.com/150'),
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  property['montant'] != null ?'${property['montant']} MRU':'${property['loyer_mensuel']} MRU/Mensielle',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      color: index < double.parse(property['ratings']) ? Colors.amber : Colors.grey,
                                      size: 20,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                   const Icon(Icons.door_back_door, size: 24),
                                   const SizedBox(
                                    width: 10,
                                   ),
                                   Text(
                                    '${property['nombre_de_chambres']}',
                                     style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600
                                      ),
                                    ),
                                ],
                              ),
                              Container(
                                width: getProportionateScreenWidth(2),
                                height: getProportionateScreenHeight(14),
                                color: kgrey900,
                                ),
                                Row(
                                children: [
                                   const Icon(Icons.bathtub, size: 24),
                                   const SizedBox(
                                    width: 10,
                                   ),
                                   Text(
                                    '${property['nombre_de_salles_de_bain']}',
                                     style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600
                                      ),
                                    ),
                                ],
                              ),
                              Container(
                                width: getProportionateScreenWidth(2),
                                height: getProportionateScreenHeight(14),
                                color: kgrey900,
                                ),
                              Row(
                                children: [
                                   const Icon(Icons.balcony, size: 24),
                                   const SizedBox(
                                    width: 10,
                                   ),
                                   property.containsKey('presence_de_balcon') && property['presence_de_balcon'] != null
                                    ? Container(
                                        // width: getProportionateScreenWidth(30),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          color: property['presence_de_balcon'] ? kgreencolor : kredcolor,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              property['presence_de_balcon']
                                                  ? getTranslated(context, 'Available')!
                                                  : getTranslated(context, 'Unavailable')!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(),
                                ],
                              ),
                              
                              Container(
                                width: getProportionateScreenWidth(2),
                                height: getProportionateScreenHeight(14),
                                color: kgrey900,
                                ),
                               Row(
                                children: [
                                   const Icon(Icons.garage, size: 24),
                                   const SizedBox(
                                    width: 10,
                                   ),
                                   Text(
                                    '${property['nombre_de_garages']}',
                                     style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                         
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                 Row(
                                  children: [
                                   Container(
                                      // width: getProportionateScreenWidth(30),
                                      decoration:  BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                                        color:property['available'] ? kgreencolor : kredcolor),
                                      child:  Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            property['available'] ? getTranslated(context, 'Available')!:getTranslated(context, 'Unavailable')!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            ),
                                            ),
                                          )
                                          ),
                                     const Icon(Icons.location_on, color: Colors.red),
                                  ],
                                ),
                                const Spacer(),
                                Text(property['adresse']),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

              },
            ),
          ),
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';

// class FilterPage extends StatefulWidget {
//   @override
//   _FilterPageState createState() => _FilterPageState();
// }

// class _FilterPageState extends State<FilterPage> {
//   String? selectedCity;
//   String? selectedQuarter;
//   bool isFurnished = false;
//   TextEditingController minPriceController = TextEditingController();
//   TextEditingController maxPriceController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Filtrer'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Ville Dropdown
//             DropdownButtonFormField<String>(
//               value: selectedCity,
//               hint: Text('Ville'),
//               items: <String>['Nouakchott', 'Nouadhibou', 'Atar']
//                   .map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedCity = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//               ),
//             ),
//             SizedBox(height: 16.0),
//             // Quartier Dropdown
//             DropdownButtonFormField<String>(
//               value: selectedQuarter,
//               hint: Text('Quartier'),
//               items: <String>['Tevragh Zeina', 'Ksar', 'Sebkha']
//                   .map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedQuarter = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//               ),
//             ),
//             SizedBox(height: 16.0),
//             // Prix Range
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: minPriceController,
//                     decoration: InputDecoration(
//                       hintText: 'De',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                 ),
//                 SizedBox(width: 8.0),
//                 Expanded(
//                   child: TextField(
//                     controller: maxPriceController,
//                     decoration: InputDecoration(
//                       hintText: 'À',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.0),
//             // Boutons Louer / Acheter
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     // Action for "Louer"
//                   },
//                   child: Text('Louer'),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.black, backgroundColor: Colors.white,
//                     side: BorderSide(color: Colors.grey),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20.0),
//                     ),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     // Action for "Acheter"
//                   },
//                   child: Text('Acheter'),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.black, backgroundColor: Colors.white,
//                     side: BorderSide(color: Colors.grey),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.0),
//             // Meublé Switch
//             Row(
//               children: [
//                 Switch(
//                   value: isFurnished,
//                   onChanged: (value) {
//                     setState(() {
//                       isFurnished = value;
//                     });
//                   },
//                 ),
//                 Text('Meublé ?'),
//               ],
//             ),
//             Spacer(),
//             // Filtrer Button
//             ElevatedButton(
//               onPressed: () {
//                 // Action for filtering
//               },
//               child: Text('Filtrer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFFB38E5D), // Color matching the design
//                 // minimumSize: Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

