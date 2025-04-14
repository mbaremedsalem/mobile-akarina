import 'dart:convert';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final FlutterSecureStorage storage = const FlutterSecureStorage();


  String appVersion = "Chargement..."; // Variable pour stocker la version


  @override
  void initState() {
    super.initState();
    fetchUserData();
    getAppVersion(); 
  }


  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "Version ${packageInfo.version}"; // Exemple : Version 1.0.3
    });
  }
Future<void> fetchUserData() async {
  try {
    final String? token = await storage.read(key: "access");
    
    if (token == null) {
      _showSessionExpiredDialog();
      return;
    }

    final response = await http.get(
      Uri.parse("https://akarina.online/user/profile/"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
        isLoading = false;
      });
    } else if (response.statusCode == 401) {
      // Token expiré, afficher un alertDialog
      _showSessionExpiredDialog();
    } else {
      throw Exception("Erreur API : ${response.statusCode}");
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur : $e")),
    );
  }
}

// Fonction pour afficher une alerte quand la session a expiré
void _showSessionExpiredDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Empêche la fermeture en cliquant en dehors
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(getTranslated(context, "Session Expirée")!),
        content:  Text(getTranslated(context, "Votre session a expiré. Veuillez vous reconnecter.")!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const IndexLogin()),
              );// Déconnexion et redirection
            },
            child: Text(getTranslated(context, "Se reconnecter")!),
          ),
        ],
      );
    },
  );
}

// Fonction pour supprimer le token et rediriger vers la page de connexion
Future<void> deleteAccount() async {
  try {
    final String? token = await storage.read(key: "access");
    final userId = await storage.read(key: "id");

  
    if (token == null || userId == null) {
      throw Exception("Token ou ID utilisateur introuvable");
    }

    final response = await http.delete(
      Uri.parse("https://akarina.online/user/delete/$userId/"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'] ?? getTranslated(context, "Compte supprimé")!)),
      );
      // Rediriger vers la page de connexion ou une autre page après suppression
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IndexLogin()
        ),
      );
    } else {
      throw Exception("Erreur lors de la suppression : ${response.statusCode}");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur : $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("Erreur lors du chargement des données"))
              : SingleChildScrollView(
                  
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: SizedBox(
                                height: 290,
                                child: Stack(
                                  alignment: AlignmentDirectional.bottomCenter,
                                  children: [
                                    Align(
                                      alignment: AlignmentDirectional.topStart,
                                      child: InkWell(
                                        onTap: ()
                                        {
                                          
                                        },
                                        child: Container(
                                          decoration:  const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.blue, pcolor],
                                            ),
                                            borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                            ),
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(
                                                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ7QMuuuZRnuUieJtizaSWdii8ecWfjZPI9-Q&s'
                                                  ),
                                            ),
                                          ),
                                          width: double.infinity,
                                          height: 235,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: (){
                                        
                                      },
                                      child: Stack(
                                        alignment: AlignmentDirectional.bottomEnd,
                                        children: [
                                          CircleAvatar(
                                            radius: 64,
                                            backgroundColor: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            child: CircleAvatar(
                                              radius: 60,
                                              backgroundImage: NetworkImage(
                                                 userData?['image'] ??
                                                'https://via.placeholder.com/150',
                                              ),
                                            ),
                                          ),
                                          if(userData?['activation_status'] == true)
                                          const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircleAvatar(
                                              radius: 10,
                                              backgroundColor: Colors.green,
                                              child: Icon(Icons.done,color: Colors.white,size: 18,),
                                            ),
                                          ),
                                        ],
                                      )
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      
                      // Nom complet
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Text(
                              userData?['nom_complet'] ?? "Nom inconnu",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          
                        // Téléphone
                        Text(
                          userData?['numero_telephone'] ?? "Téléphone inconnu",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Badge "Compte vérifié"
                        if (userData?['activation_status'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.green, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  "Compte vérifié",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        // Informations détaillées
                        const Divider(),
                        buildInfoRow(
                            "Adresse", userData?['adrese'] ?? 'Adresse inconnue'),
                        buildInfoRow("NNI", userData?['nni'] ?? '-'),
                        buildInfoRow(
                            "Email", userData?['email'] ?? '-'),
                         InkWell(
                          onTap: (){
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const IndexLogin()
                                ),
                              );
                          },
                          child: const Row(
                            children: [
                              Text("Log Out",style:TextStyle(fontSize: 16,color: Colors.grey),),
                              Spacer(),
                              Icon(Icons.logout),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        // Boutons

                        Row(
                          children: [
                            Expanded(
                              child: Defaultbutton(
                                height: getProportionateScreenHeight(45),
                                width: double.infinity, // Prend toute la largeur disponible
                                text: getTranslated(context, "Edit"),
                                onTap: () async {
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfilePage(userData: userData!),
                                    ),
                                  );

                                },
                                color: pcolor,
                                textcolor: kWhiteColor,
                              ),
                            ),
                            const SizedBox(width: 10), // Espacement entre les boutons
                            Expanded(
                              child: Defaultbutton(
                                height: getProportionateScreenHeight(45),
                                width: double.infinity, // Prend toute la largeur disponible
                                text: getTranslated(context, "Suprimmer"),
                                onTap: () async {
                                    // Afficher une boîte de dialogue de confirmation
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:  Text(getTranslated(context, "confirmer")!),
                                      content:  Text(
                                        getTranslated(context, "supgroupe")!,
                                      ),
                                      actions: [
                                        // Bouton Annuler
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Ferme la boîte de dialogue
                                          },
                                          child:  Text(getTranslated(context, "Annuler")!),
                                        ),
                                        // Bouton Supprimer
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(); // Ferme la boîte de dialogue
                                            await deleteAccount(); // Appeler la fonction de suppression
                                          },
                                          child: Text(
                                            getTranslated(context, "Supprimer")!,
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                },
                                color: kredcolor,
                                textcolor: kWhiteColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Text(
                          appVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer
                         Text(
                          "${getTranslated(context, "Développé par")!} agharinaa.mr",
                          style: TextStyle(color: Colors.grey),
                        ),
                          ],
                        ),
                      ),

                      
                    ],
                  ),
                ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}





class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  File? imageFile;
  final ImagePicker picker = ImagePicker();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool? isLoaded = false;
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['nom_complet']);
    addressController = TextEditingController(text: widget.userData['adrese']);
    phoneController = TextEditingController(
        text: widget.userData['numero_telephone']);
    emailController = TextEditingController(text: widget.userData['email']);
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> updateProfile() async {    
    setState(() {
      isLoaded=true;
    });
    if (!_formKey.currentState!.validate()) return;

    final token = await storage.read(key: "access");
    if (token == null) return;

    final uri = Uri.parse("https://akarina.online/user/update-profile/");
    final request = http.MultipartRequest("PUT", uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['nom_complet'] = nameController.text;
    request.fields['adrese'] = addressController.text;
    request.fields['numero_telephone'] = phoneController.text;
    request.fields['email'] = emailController.text;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile!.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {  
      setState(() {
        isLoaded=false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(getTranslated(context, "Profil mis à jour avec succès")!)),
      );
      Navigator.pop(context, true); // Retourner à la page précédente
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(getTranslated(context, "Erreur lors de la mise à jour")!)),
      );
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
        title:  Text(getTranslated(context, "Modifier le profil")!,
        style: TextStyle(color: kBlackColor)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: imageFile != null
                      ? FileImage(imageFile!)
                      : NetworkImage(widget.userData['image'] ??
                          'https://via.placeholder.com/150') as ImageProvider,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration:  InputDecoration(labelText: getTranslated(context, "Nom complet")!,),
                validator: (value) =>
                    value!.isEmpty ? getTranslated(context, "Ce champ est obligatoire"): null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Adresse"),
                validator: (value) =>
                    value!.isEmpty ? "Ce champ est obligatoire" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Téléphone"),
                validator: (value) =>
                    value!.isEmpty ? "Ce champ est obligatoire" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value!.isEmpty ? "Ce champ est obligatoire" : null,
              ),
              const SizedBox(height: 30),
              isLoaded!
              ?spiner()
              :Defaultbutton(
                                height: getProportionateScreenHeight(45),
                                width: double.infinity, // Prend toute la largeur disponible
                                text: getTranslated(context, "Edit"),
                                onTap: () async {
                                  
                                    updateProfile();

                                },
                                color: pcolor,
                                textcolor: kWhiteColor,
                              ),
                           

            ],
          ),
        ),
      ),
    );
  }
}
