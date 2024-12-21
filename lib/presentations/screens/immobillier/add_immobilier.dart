import 'dart:convert';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:intl/intl.dart';

class PostAnnonceScreen extends StatefulWidget {
  @override
  _PostAnnonceScreenState createState() => _PostAnnonceScreenState();
}

class _PostAnnonceScreenState extends State<PostAnnonceScreen> {
  String? selectedType;
  String? selectedimmo;
  String? selectedVille;
  String? selectedZone;
  List<dynamic> villes = [];
  int currentState = 0;
  bool isLoaded = false;

  TextEditingController descriptionController = TextEditingController();
  TextEditingController prixController = TextEditingController();
  TextEditingController surfaceController = TextEditingController();

  final storage = FlutterSecureStorage(); // Pour stocker les données de manière sécurisée
  final String apiUrl = 'https://akarina-9865f1a90dee.herokuapp.com/akareena/imobiers/new/';

  @override
  void initState() {
    super.initState();
    fetchVilles();
  }

  // Fonction pour récupérer les villes depuis l'API
  Future<void> fetchVilles() async {
    try {
      final response = await http.get(Uri.parse('https://akarina-9865f1a90dee.herokuapp.com/akareena/get-ville/'));
      if (response.statusCode == 200) {
        setState(() {
          villes = json.decode(response.body);
        });
      } else {
        throw Exception('Erreur lors du chargement des villes.');
      }
    } catch (error) {
      showToast('Erreur de chargement des villes', backgroundColor: Colors.red, duration: Duration(seconds: 4));
    }
  }



  // Fonction pour soumettre l'annonce immobilière
Future<void> submitAnnonce(BuildContext context) async {
  setState(() {
    isLoaded = true;
  });

  String? token = await storage.read(key: "access"); // Lire le token depuis le stockage sécurisé
  final url = Uri.parse(apiUrl);

  // Préparation des données à envoyer
  Map<String, dynamic> body = {
    "nom": selectedVille, // Assurez-vous que c'est un ID depuis la liste des villes
    "type": selectedType,
    "loyer_mensuel": int.parse(prixController.text),
    "immobilier_type": selectedimmo,
    "adresse": selectedZone,
    "surface": surfaceController.text,
    "description": descriptionController.text,
    "etage": 3, // Valeur par défaut
    "presence_de_balcon": true,
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token', // Utiliser le token dans l'en-tête Authorization
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      // Stocker l'ID de l'immobilier dans le stockage sécurisé
      await storage.write(key: 'idimmo', value: jsonResponse['id'].toString());

      // Afficher un toast de succès
      showToast(
        jsonResponse['message'],
        context: context, // Ensure context is passed here
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      );
    } else {
      final errorResponse = json.decode(response.body);
      showToast(
        errorResponse['error'] ?? 'Une erreur est survenue',
        context: context, // Ensure context is passed here
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      );
    }
  } catch (e) {
    showToast(
      'Erreur réseau. Veuillez réessayer.',
      context: context, // Ensure context is passed here
      backgroundColor: Colors.red,
      duration: Duration(seconds: 4),
    );
  } finally {
    setState(() {
      isLoaded = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête pour basculer entre "Immobilier" et "Projet"
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: kgrey300),
                borderRadius: BorderRadius.circular(getProportionateScreenWidth(7)),
                color: kgrey100,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(5),
                vertical: getProportionateScreenHeight(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentState = 0;
                      });
                    },
                    child: _buildStateButton(isActive: currentState == 0, text:getTranslated(context, "Immobilier")!),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentState = 1;
                      });
                    },
                    child: _buildStateButton(isActive: currentState == 1, text: getTranslated(context, "Projet")!),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            currentState == 0 ? buildImmobilierForm() : ProjectSubmissionForm(),
          ],
        ),
      ),
    );
  }

  // Widget pour le bouton de bascule entre les formulaires
  Widget _buildStateButton({required bool isActive, required String text}) {
    return Container(
      height: getProportionateScreenHeight(37),
      width: getProportionateScreenWidth(155),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(5)),
        color: isActive ? kWhiteColor : kgrey100,
        boxShadow: [
          BoxShadow(
            color: isActive ? kgrey300 : kgrey100,
            offset: const Offset(0.0, 0.0),
            blurRadius: 10.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textScaleFactor: 1.0,
          style: textstyle.copyWith(
            fontSize: getProportionateScreenWidth(14),
            color: kBlackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Formulaire pour l'immobilier
  Widget buildImmobilierForm() {
    return Column(
      children: [
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners for the card
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding inside the card
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image on the left side
              Image.network(
                'https://www.bpm.mr/uploads/2/2020-09/bankily.JPG', // Replace with correct image URL
                height: 40,
                width: 40,
                fit: BoxFit.cover, // Ensure the image covers the container proportionally
              ),
              SizedBox(width: 16), // Space between image and text
              // Column for price, duration, and contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '6,600 ${getTranslated(context, "MRU")}', // Price
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4), // Slight space between text
                    Text(
                      '6 ${getTranslated(context, "mois")}', // Duration
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8), // Space between text and contact
                    Text(
                      '${getTranslated(context, "Contact")}: 47100063', // Contact information
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Copy icon on the right
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  // Action to copy contact details
                },
              ),
            ],
          ),
        ),
      ),
      // End of the Card Layout

      SizedBox(height: 8), // Space between card and the next element

      // GestureDetector for choosing screenshot
      GestureDetector(
        onTap: () {
          // Action for choosing a payment screenshot
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload, size: 30, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  '${getTranslated(context, "Cliquez pour choisir capture d'écran du paiement")}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),

        SizedBox(height: 10),
        // Dropdown pour sélectionner la ville
        DropdownButtonFormField<int>(
          value: selectedVille != null ? int.tryParse(selectedVille!) : null,
          onChanged: (int? newValue) {
            setState(() {
              selectedVille = newValue?.toString();  // Store the city ID as a string
            });
          },
          items: villes.map<DropdownMenuItem<int>>((ville) {
            return DropdownMenuItem<int>(
              value: ville['id'],  // Use the city ID as the value
              child: Text(ville['nom']),  // Display the city name
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: getTranslated(context, "Ville"),
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        // Dropdown pour le type d'annonce
        DropdownButtonFormField<String>(
          value: selectedType,
          onChanged: (newValue) {
            setState(() {
              selectedType = newValue;
            });
          },
          items: [getTranslated(context, "vendre")!,getTranslated(context, "alouer")!].map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          decoration: InputDecoration(labelText:getTranslated(context, "Type d'Annonce")!, border: OutlineInputBorder()),
        ),
        SizedBox(height: 16),
        // Dropdown pour le type d'immobilier
        DropdownButtonFormField<String>(
          value: selectedimmo,
          onChanged: (newValue) {
            setState(() {
              selectedimmo = newValue;
            });
          },
          items: [getTranslated(context, "appartement")!,getTranslated(context, "duplex")!,getTranslated(context, "commercial")!].map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          decoration: InputDecoration(labelText:getTranslated(context, "Type d'Immobilier"), border: OutlineInputBorder()),
        ),
        SizedBox(height: 16),
        // Champ pour le prix
        TextFormField(
          controller: prixController,
          decoration: InputDecoration(labelText: getTranslated(context, "Prix"), border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        // Champ pour la surface
        TextFormField(
          controller: surfaceController,
          decoration: InputDecoration(labelText: getTranslated(context, "Surface"), border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        // Dropdown pour la zone
        DropdownButtonFormField<String>(
          value: selectedZone,
          onChanged: (newValue) {
            setState(() {
              selectedZone = newValue;
            });
          },
          items: ['Tevragh Zeina', 'Arafat', 'Sebkha'].map((zone) {
            return DropdownMenuItem<String>(
              value: zone,
              child: Text(zone),
            );
          }).toList(),
          decoration: InputDecoration(labelText: getTranslated(context, "Adresse"), border: OutlineInputBorder()),
        ),
        SizedBox(height: 16),
        // Champ pour la description
        TextField(
          controller: descriptionController,
          maxLines: 4,
          decoration: InputDecoration(border: OutlineInputBorder(), labelText: getTranslated(context, "Description")),
        ),
        SizedBox(height: 20),
        // Bouton de soumission
        isLoaded
            ? spiner() // Affichage du spinner si isLoaded est vrai
            : Defaultbutton(
                onTap: (){
                  submitAnnonce(context);
                }, // Appeler la fonction submitAnnonce lors de l'appui sur le bouton
                color: pcolor,
                textcolor: kWhiteColor,
                text: getTranslated(context, "Soumettre"),
                borderRadius: getProportionateScreenWidth(5),
                width: getProportionateScreenWidth(500),
                height: getProportionateScreenHeight(45),
              ),
      ],
    );
  }
}



        //   SizedBox(height: 20),
        // // Image/Video upload section
        // GestureDetector(
        //   onTap: () {
        //     // Action for selecting images or videos
        //   },
        //   child: Container(
        //     height: 150,
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(10),
        //       border: Border.all(color: Colors.grey),
        //     ),
        //     child: Center(
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           Icon(Icons.upload, size: 30, color: Colors.grey),
        //           SizedBox(height: 8),
        //           Text('Images ou vidéos du bien immobilier', style: TextStyle(color: Colors.grey)),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
// Project submission form code remains unchanged


class ProjectSubmissionForm extends StatefulWidget {
  @override
  _ProjectSubmissionFormState createState() => _ProjectSubmissionFormState();
}

class _ProjectSubmissionFormState extends State<ProjectSubmissionForm> {
  String? selectedType;
  TextEditingController addressController = TextEditingController();
  TextEditingController budgetController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

  // Date picker function
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(  // Ensure scroll for large content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/svg/logo.svg',
              width: 100,
              height: 100,
            ),
          ),
          SizedBox(height: 20),
          Text(
            getTranslated(context, "Soumettre un Projet Immobilier")!,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            getTranslated(context, "Chez Akareena, nous nous engageons à traiter votre demande rapidement et efficacement. Remplissez le formulaire ci-dessous pour nous fournir les détails de votre projet. Nous reviendrons vers vous dès que possible.")!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 20),
          // Dropdown for selecting project type
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: getTranslated(context, "Type de Projet")!,
            ),
            value: selectedType,
            items: [getTranslated(context, "appartement")!, getTranslated(context, "Maison")!,getTranslated(context, "Terrain")!]
                .map((label) => DropdownMenuItem(
                      child: Text(label),
                      value: label,
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
              });
            },
          ),
          SizedBox(height: 20),
          // Address input field
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: getTranslated(context, "Adresse")!,
            ),
          ),
          SizedBox(height: 20),
          // Budget input field
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: getTranslated(context, "Budget")!,
            ),
          ),
          SizedBox(height: 20),
          // Description input field
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: getTranslated(context, "Description")!,
            ),
          ),
          SizedBox(height: 20),
          // Date pickers for project start and end dates
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: getTranslated(context, "Début du Projet")!,
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, startDateController),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: getTranslated(context, "Fin du Projet")!,
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, endDateController),
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          // Submit button
          Defaultbutton(
            onTap: () {
              // Handle project submission
            },
            color: pcolor,
            textcolor: kWhiteColor,
            text: getTranslated(context, 'Soumettre')!,
            borderRadius: getProportionateScreenWidth(5),
            width: getProportionateScreenWidth(500),
            height: getProportionateScreenHeight(45),
          ),
        ],
      ),
    );
  }
}
