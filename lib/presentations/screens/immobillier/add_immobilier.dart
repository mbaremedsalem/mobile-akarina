import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'dart:ui' as ui;

import 'package:permission_handler/permission_handler.dart';

// import 'package:geolocator/geolocator.dart';

class PostAnnonceScreen extends StatefulWidget {
  const PostAnnonceScreen({super.key});

  @override
  _PostAnnonceScreenState createState() => _PostAnnonceScreenState();
}

class _PostAnnonceScreenState extends State<PostAnnonceScreen> {
  String? selectedType;
  String? selectedImmoType;
  String? selectedVille;
  String? selectedOperationType;
  String? selectedPaymentCondition;
  String? selectedPaymentPeriod;
  String? selectedVenteCondition;

  int currentState = 0;
  bool isLoaded = false;
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  TextEditingController descriptionController = TextEditingController();
  TextEditingController descriptionArController = TextEditingController();
  TextEditingController prixController = TextEditingController();
  TextEditingController montantController = TextEditingController();
  TextEditingController surfaceController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController roomsController = TextEditingController();
  TextEditingController xCoordController = TextEditingController();
  TextEditingController yCoordController = TextEditingController();
  TextEditingController villeNomController = TextEditingController();
  TextEditingController villeNomArController = TextEditingController();
  TextEditingController villeRegionController = TextEditingController();
  TextEditingController villeRegionArController = TextEditingController();

  final storage = const FlutterSecureStorage();
  final String apiUrl = 'https://akarina.online/akareena/residentiel/create/';

  // Options pour les dropdowns
  final List<String> immoTypes = ['appartement', 'duplex', 'Maisonceremonie','commercial','Terrain'];

  final List<String> operationTypes = ['alouer', 'vendre'];

  final List<String> paymentConditions = [
    'Paiement mensuel',
    'Paiement trimestriel',
    'Paiement annuel'
  ];

  final List<String> venteConditions = [
    'Paiement cache',
    'Paiement cheque',
    'Paiement applicatife'
  ];
  final List<String> paymentPeriods = [
    'Par Jour',
    'Hebdomodaire',
    'Mensuelle',
    'Annuelle'
  ];

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      setState(() {
        selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });
    } catch (e) {
      showToast(
        'Erreur lors de la sélection des images: $e',
        // ignore: use_build_context_synchronously
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  }



  Future<void> submitResidentiel() async {
    try {
      debugPrint('[SubmitResidentiel] Début de la soumission');

      setState(() {
        isLoaded = true;
      });

      String? token = await storage.read(key: "access");
      String? userId = await storage.read(key: "id");
      debugPrint(
          '[SubmitResidentiel] Token: ${token != null ? "présent" : "absent"}');
      debugPrint('[SubmitResidentiel] UserID: $userId');

      if (token == null || userId == null) {
        debugPrint('[SubmitResidentiel] Erreur: Utilisateur non connecté');
        showToast(
          'Vous devez être connecté pour poster une annonce',
          context: context,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        );
        setState(() {
          isLoaded = false;
        });
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Bearer $token';

      // Log des données du formulaire
      debugPrint('[SubmitResidentiel] Données du formulaire:');
      debugPrint('- Type: $selectedImmoType');
      debugPrint('- Description: ${descriptionController.text}');
      debugPrint('- Adresse: ${addressController.text}');
      debugPrint('- Surface: ${surfaceController.text}');
      debugPrint('- Nombre d\'images: ${selectedImages.length}');

      // Ajout des champs de formulaire
      request.fields['type'] = selectedImmoType ?? '';
      request.fields['user_id'] = userId;
      request.fields['description'] = descriptionController.text;
      request.fields['description_ar'] = descriptionArController.text;
      request.fields['adresse'] = addressController.text;
      request.fields['surface'] = surfaceController.text;
      request.fields['x'] = xCoordController.text;
      request.fields['y'] = yCoordController.text;
      request.fields['nombre_de_chambres'] = roomsController.text;
      request.fields['presence_de_balcon'] = 'true';

      // Informations sur la ville
      request.fields['ville[nom]'] = villeNomController.text;
      request.fields['ville[nom_ar]'] = villeNomArController.text;
      request.fields['ville[region]'] = villeRegionController.text;
      request.fields['ville[region_ar]'] = villeRegionArController.text;

      // Informations sur l'opération
      request.fields['operation[type]'] = selectedOperationType ?? '';
      request.fields['operation[loyer_mensuel]'] = prixController.text;
      request.fields['operation[condition_de_alouer]'] =
          selectedPaymentCondition ?? '';
      request.fields['operation[periode]'] = selectedPaymentPeriod ?? '';

      request.fields['operation[montant]'] = montantController.text;
      request.fields['operation[condition_de_vent]'] =
          selectedVenteCondition ?? '';
      // Ajout des images
      for (var image in selectedImages) {
        var stream = http.ByteStream(image.openRead());
        var length = await image.length();
        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: path.basename(image.path),
        );
        request.files.add(multipartFile);
        debugPrint('[SubmitResidentiel] Image ajoutée: ${image.path}');
      }

      debugPrint('[SubmitResidentiel] Envoi de la requête...');
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      debugPrint('[SubmitResidentiel] Réponse reçue:');
      debugPrint('- Status Code: ${response.statusCode}');
      debugPrint('- Body: $responseString');

      var jsonResponse = json.decode(responseString);

      if (response.statusCode == 201) {
        debugPrint('[SubmitResidentiel] Succès: Annonce créée');
        showToast(
          'Annonce créée avec succès',
          context: context,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        );
        resetForm();
      } else {
        debugPrint('[SubmitResidentiel] Erreur API: ${jsonResponse['error']}');
        showToast(
          jsonResponse['error'] ?? 'Erreur lors de la création de l\'annonce',
          context: context,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('[SubmitResidentiel] Erreur réseau: ${e.toString()}');
      debugPrint('[SubmitResidentiel] StackTrace: ${e.toString()}');
      showToast(
        'Erreur de connexion. Vérifiez votre internet',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } on SocketException catch (e) {
      debugPrint('[SubmitResidentiel] Erreur socket: ${e.toString()}');
      showToast(
        'Problème de connexion au serveur',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } on TimeoutException catch (e) {
      debugPrint('[SubmitResidentiel] Timeout: ${e.toString()}');
      showToast(
        'Le serveur a mis trop de temps à répondre',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } on FormatException catch (e) {
      debugPrint('[SubmitResidentiel] Format JSON invalide: ${e.toString()}');
      showToast(
        'Erreur dans le format des données',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } catch (e, stackTrace) {
      debugPrint('[SubmitResidentiel] Erreur inattendue: ${e.toString()}');
      debugPrint('[SubmitResidentiel] StackTrace: $stackTrace');
      showToast(
        'Une erreur inattendue est survenue',
        context: context,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoaded = false;
        });
      }
      debugPrint('[SubmitResidentiel] Fin de la soumission');
    }
  }

  void resetForm() {
    setState(() {
      selectedType = null;
      selectedImmoType = null;
      selectedVille = null;
      selectedOperationType = null;
      selectedPaymentCondition = null;
      selectedPaymentPeriod = null;

      selectedImages.clear();

      descriptionController.clear();
      descriptionArController.clear();
      prixController.clear();
      surfaceController.clear();
      addressController.clear();
      roomsController.clear();
      xCoordController.clear();
      yCoordController.clear();
      villeNomController.clear();
      villeNomArController.clear();
      villeRegionController.clear();
      villeRegionArController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du type d'annonce (Immobilier/Projet)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: kgrey300),
                borderRadius:
                    BorderRadius.circular(getProportionateScreenWidth(7)),
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
                    child: _buildStateButton(
                        isActive: currentState == 0,
                        text: getTranslated(context, "Immobilier")!),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentState = 1;
                      });
                    },
                    child: _buildStateButton(
                        isActive: currentState == 1,
                        text: getTranslated(context, "Projet")!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            currentState == 0
                ? buildImmobilierForm()
                : const ProjectSubmissionForm(),
          ],
        ),
      ),
    );
  }

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

  Widget buildImmobilierForm() {
    return Column(
      children: [
      
      Center(
      child: Container(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.blue[50],  // Fond bleu clair
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
              size: 24,
            ),
            SizedBox(height: 10),
            Text(
              getTranslated(context, "information")!.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              getTranslated(context, "Chaque ajout d’immobilier entraînera un prélèvement automatique de 50 MRU sur votre solde.")!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 13),
        DropdownButtonFormField<String>(
          value: selectedImmoType,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Type d'Immobilier")!,
            border: const OutlineInputBorder(),
          ),
          items: immoTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(getTranslated(context, type)!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedImmoType = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Description (FR)
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Description (Français)"),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Description (AR)
        TextField(
            controller: descriptionArController,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Description"),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            // textDirection: TextDirection.rtl,
            textDirection: ui.TextDirection.ltr),
        const SizedBox(height: 16),

        // Adresse
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Adresse"),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Surface
        TextField(
          controller: surfaceController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Surface"),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: xCoordController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, "Longitude (X)"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: yCoordController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, "Latitude (Y)"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Defaultbutton(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapSelectorPage()),
            );

            if (result != null && result is Map<String, double>) {
              double latitude = result['latitude']!;
              double longitude = result['longitude']!;
              print(
                  'Coordonnées sélectionnées (retournées): Latitude: $latitude, Longitude: $longitude');
              // Fais quelque chose avec les coordonnées (par exemple, les afficher dans un widget)
              setState(() {
                xCoordController.text = longitude.toStringAsFixed(6);
                yCoordController.text = latitude.toStringAsFixed(6);
              });
            }
          },
          color: Colors.blue,
          textcolor: Colors.white,
          text: getTranslated(context, "Utiliser ma position actuelle"),
          borderRadius: getProportionateScreenWidth(5),
          width: double.infinity,
          height: getProportionateScreenHeight(45),
        ),

        const SizedBox(height: 10),
        // Nombre de chambres
        TextField(
          controller: roomsController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Nombre de chambres"),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Informations sur la ville
        Text(
          getTranslated(context, "Informations sur la ville")!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Nom ville (FR)
        TextField(
          controller: villeNomController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Nom de la ville (FR)"),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Nom ville (AR)
        TextField(
            controller: villeNomArController,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Nom de la ville (AR)"),
              border: const OutlineInputBorder(),
            ),
            // textDirection: TextDirection.rtl,
            textDirection: ui.TextDirection.ltr),
        const SizedBox(height: 16),

        // Région (FR)
        TextField(
          controller: villeRegionController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Région (FR)"),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Région (AR)
        TextField(
            controller: villeRegionArController,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Région (AR)"),
              border: const OutlineInputBorder(),
            ),
            // textDirection: TextDirection.rtl,
            textDirection: ui.TextDirection.ltr),
        const SizedBox(height: 16),

        // Informations sur l'opération
        Text(
          getTranslated(context, "Informations sur l'opération")!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Type d'opération
        DropdownButtonFormField<String>(
          value: selectedOperationType,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Type d'opération"),
            border: const OutlineInputBorder(),
          ),
          items: operationTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(getTranslated(context, type)!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedOperationType = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Prix/Loyer
        selectedOperationType == 'alouer'
            ? TextField(
                controller: prixController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, "Loyer mensuel"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              )
            :
            // Prix/Loyer
            TextField(
                controller: montantController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, "Prix de vente"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
        const SizedBox(height: 16),
        // Condition de paiement
        if (selectedOperationType == 'alouer') ...[
         
          DropdownButtonFormField<String>(
            value: selectedPaymentCondition,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Condition de paiement"),
              border: const OutlineInputBorder(),
            ),
            items: paymentConditions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Text(getTranslated(context, condition)!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentCondition = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          // Période de paiement
          DropdownButtonFormField<String>(
            value: selectedPaymentPeriod,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Période de paiement"),
              border: const OutlineInputBorder(),
            ),
            items: paymentPeriods.map((period) {
              return DropdownMenuItem<String>(
                value: period,
                child: Text(getTranslated(context, period)!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentPeriod = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
        ],

        // Condition de achat
        if (selectedOperationType == 'vendre') ...[
          DropdownButtonFormField<String>(
            value: selectedVenteCondition,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Condition de Vente"),
              border: const OutlineInputBorder(),
            ),
            items: venteConditions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedVenteCondition = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        // Sélection des images
        Text(
          getTranslated(context, "Images (minimum 1, maximum 6)")!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    children: [
                      Image.file(
                        selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        ElevatedButton(
          onPressed: pickImages,
          child: Text(getTranslated(context, "Ajouter des images")!),
        ),
        const SizedBox(height: 16),

        // Bouton de soumission
        isLoaded
            ? spiner()
            : Defaultbutton(
                onTap: submitResidentiel,
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

// Project submission form code remains unchanged

class ProjectSubmissionForm extends StatefulWidget {
  const ProjectSubmissionForm({super.key});

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
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
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
    return SingleChildScrollView(
      // Ensure scroll for large content
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
          const SizedBox(height: 20),
          Text(
            getTranslated(context, "Soumettre un Projet Immobilier")!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            getTranslated(context,
                "Chez Akareena, nous nous engageons à traiter votre demande rapidement et efficacement. Remplissez le formulaire ci-dessous pour nous fournir les détails de votre projet. Nous reviendrons vers vous dès que possible.")!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Dropdown for selecting project type
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Type de Projet")!,
            ),
            value: selectedType,
            items: [
              getTranslated(context, "appartement")!,
              getTranslated(context, "Maison")!,
              getTranslated(context, "Terrain")!
            ]
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
              });
            },
          ),
          const SizedBox(height: 20),
          // Address input field
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Adresse")!,
            ),
          ),
          const SizedBox(height: 20),
          // Budget input field
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Budget")!,
            ),
          ),
          const SizedBox(height: 20),
          // Description input field
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: getTranslated(context, "Description")!,
            ),
          ),
          const SizedBox(height: 20),
          // Date pickers for project start and end dates
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: getTranslated(context, "Début du Projet")!,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, startDateController),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: getTranslated(context, "Fin du Projet")!,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, endDateController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
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

class MapSelectorPage extends StatefulWidget {
  const MapSelectorPage({super.key});

  @override
  _MapSelectorPageState createState() => _MapSelectorPageState();
}

class _MapSelectorPageState extends State<MapSelectorPage> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(18.0735, -15.9582), // Centre sur Nouakchott
    zoom: 12, // Zoom plus proche pour mieux voir la ville
  );

  void _onMapTapped(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    print(
        'Latitude sélectionnée: ${_selectedLocation!.latitude}, Longitude sélectionnée: ${_selectedLocation!.longitude}');
    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Sélectionner un lieu',
          style: TextStyle(color: kBlackColor),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: _kInitialPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        onTap: _onMapTapped,
        markers: _selectedLocation == null
            ? {}
            : {
                Marker(
                  markerId: MarkerId('selected-location'),
                  position: _selectedLocation!,
                ),
              },
      ),
    );
  }
}
