import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

class Register extends StatefulWidget {
  Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();

  // Données du formulaire
  String? prenom;
  String? nom;
  String? email;
  String? nni;
  String phone = '';
  String? password;
  String? confirmPassword;
  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // Validation des étapes
  bool nniValid = false;
  bool personalInfoValid = false;
  bool passwordValid = false;

  Future<void> registerUser() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${NetworkService().baseUrl}user/register/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'email': email,
          'nom_complet': '$prenom $nom',
          'numero_telephone': '+222$phone',
          'nni': nni,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        showToast(
          'Inscription réussie!',
          context: context,
          backgroundColor: Colors.green,
        );
                Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IndexLogin()
        ),
      );
         
      } else {
        final error = jsonDecode(response.body);
        
        showToast(
          error['message'] ?? 'Erreur lors de l\'inscription',
          context: context,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      
      
      showToast(
        'Erreur de connexion${e.toString()}',
        context: context,
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Étape 1: NNI
              _buildStep(
                stepNumber: 1,
                title: getTranslated(context, "Informations d'identification")!,
                isActive: _currentStep >= 0,
                isCompleted: nniValid,
                content: _currentStep == 0 && !nniValid
                    ? Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              label: getTranslated(context, "Numéro national d'identification")!,
                              icon: Icons.credit_card,
                              maxLength: 10,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v!.isEmpty) return getTranslated(context, "videerror")!;
                                if (v.length != 10) return getTranslated(context, "nnicourt")!;
                                return null;
                              },
                              onChanged: (v) => nni = v,
                            ),
                            const SizedBox(height: 20),
                            _buildNextButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    nniValid = true;
                                    _currentStep += 1;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    : null,
              ),

              // Étape 2: Informations personnelles
              _buildStep(
                stepNumber: 2,
                title: getTranslated(context, "Informations personnelles")!,
                isActive: _currentStep >= 1,
                isCompleted: personalInfoValid,
                content: _currentStep == 1 && !personalInfoValid
                    ? Form(
                        key: _formKey2,
                        child: Column(
                          children: [
                            _buildTextField(
                              label: getTranslated(context, "prenom")!,
                              icon: Icons.person,
                              validator: (v) => v!.isEmpty ? getTranslated(context, "videerror")! : null,
                              onChanged: (v) => prenom = v,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: getTranslated(context, "Nom")!,
                              icon: Icons.person_outline,
                              validator: (v) => v!.isEmpty ? getTranslated(context, "videerror")! : null,
                              onChanged: (v) => nom = v,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: getTranslated(context, "Email")!,
                              icon: Icons.mail_outlined,
                              validator: (v) => v!.isEmpty ? getTranslated(context, "videerror")! : null,
                              onChanged: (v) => email = v,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: getTranslated(context, "Numéro de Téléphone")!,
                              icon: Icons.phone,
                              maxLength: 8,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v!.isEmpty) return getTranslated(context, "videerror")!;
                                if (v.length != 8) return getTranslated(context, "Le numéro doit avoir 8 chiffres")!;
                                return null;
                              },
                              onChanged: (v) => phone = v,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildBackButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentStep -= 1;
                                      nniValid = false;
                                    });
                                  },
                                ),
                                _buildNextButton(
                                  onPressed: () {
                                    if (_formKey2.currentState!.validate()) {
                                      setState(() {
                                        personalInfoValid = true;
                                        _currentStep += 1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : null,
              ),

              // Étape 3: Mot de passe
              _buildStep(
                stepNumber: 3,
                title: getTranslated(context, "Création du mot de passe")!,
                isActive: _currentStep >= 2,
                isCompleted: passwordValid,
                content: _currentStep == 2
                    ? Column(
                        children: [
                          _buildPasswordField(
                            label: getTranslated(context, "code")!,
                            obscureText: obscurePassword,
                            maxLength: 4,
                            validator: (v) {
                              if (v!.isEmpty) return getTranslated(context, "videerror")!;
                              if (v.length != 4) return getTranslated(context, "doit etre  4 caractères");
                              return null;
                            },
                            onChanged: (v) => password = v,
                            onToggleVisibility: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            label: getTranslated(context, "Confirmer le mot de passe")!,
                            obscureText: obscureConfirmPassword,
                            maxLength: 4,
                            validator: (v) {
                              if (v!.isEmpty) return getTranslated(context, "videerror")!;
                              if (v != password) return getTranslated(context, "mots de passe non identiques")!;
                              return null;
                            },
                            onChanged: (v) => confirmPassword = v,
                            onToggleVisibility: () {
                              setState(() {
                                obscureConfirmPassword = !obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBackButton(
                                onPressed: () {
                                  setState(() {
                                    _currentStep -= 1;
                                    personalInfoValid = false;
                                  });
                                },
                              ),
                              loading
                                  ? const CircularProgressIndicator()
                                  : _buildConfirmButton(
                                      onPressed: registerUser,
                                    ),
                            ],
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
    Widget? content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                  ? Colors.green
                  : isActive 
                    ? Colors.black 
                    : Colors.grey[300],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${getTranslated(context, "ÉTAPE $stepNumber")} ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 21),
          child: Container(
            height: content != null ? 40 : 20,
            width: 2,
            color: isCompleted ? Colors.green : Colors.grey[300],
          ),
        ),
        if (content != null) content,
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          counterText: '',
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool obscureText,
    int? maxLength,
    required String? Function(String?)? validator,
    required void Function(String) onChanged,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        maxLength: maxLength,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNextButton({required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child:  Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(getTranslated(context, "suivant")!),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }

  Widget _buildBackButton({required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child:  Text(getTranslated(context, "Retourner")!),
    );
  }

  Widget _buildConfirmButton({required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(getTranslated(context, "confirmer")!),
    );
  }
}





// import 'dart:async';
// import 'dart:convert';
// import 'package:akarina/size_config.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_styled_toast/flutter_styled_toast.dart';

// class Register extends StatefulWidget {
//   const Register({Key? key}) : super(key: key);

//   @override
//   _RegisterState createState() => _RegisterState();
// }

// class _RegisterState extends State<Register> {
//   final _formKey = GlobalKey<FormState>();
//   final storage = FlutterSecureStorage();
  
//   int _currentStep = 0;
//   bool loading = false;
//   bool _step1Validated = false;
//   bool _step2Validated = false;
  
//   // Données du formulaire
//   String? firstName;
//   String? lastName;
//   String? email;
//   String? documentType = 'NNI';
//   String? documentNumber;
//   String? phoneNumber;
//   String? password;
//   String? confirmPassword;
  
//   final List<String> documentTypes = ['NNI', 'NIF', 'RC'];
  
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(

//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Stepper(
//               currentStep: _currentStep,
//               onStepContinue: _continue,
//               onStepCancel: _cancel,
//               onStepTapped: (step) => setState(() => _currentStep = step),
//               steps: [
//                 _buildPersonalInfoStep(),
//                 _buildContactStep(),
//                 _buildSecurityStep(),
//               ],
//             ),
//             if (loading) CircularProgressIndicator(),
//           SizedBox(height: 20,),

//           ],
//         ),
//       ),
//     );
//   }

//   Step _buildPersonalInfoStep() {
//     return Step(
//       title: Text('Informations personnelles'),
//       content: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             TextFormField(
//               decoration: InputDecoration(labelText: 'Prénom*'),
//               validator: (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
//               onChanged: (value) => firstName = value,
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               decoration: InputDecoration(labelText: 'Nom*'),
//               validator: (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
//               onChanged: (value) => lastName = value,
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               decoration: InputDecoration(labelText: 'Email*'),
//               keyboardType: TextInputType.emailAddress,
//               validator: (value) {
//                 if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
//                 if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
//                   return 'Email invalide';
//                 }
//                 return null;
//               },
//               onChanged: (value) => email = value,
//             ),
//             SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: documentType,
//               decoration: InputDecoration(labelText: 'Type de document*'),
//               items: documentTypes.map((type) {
//                 return DropdownMenuItem(
//                   value: type,
//                   child: Text(type),
//                 );
//               }).toList(),
//               validator: (value) => value == null ? 'Sélectionnez un type de document' : null,
//               onChanged: (value) => setState(() => documentType = value),
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               decoration: InputDecoration(
//                 labelText: 'Numéro de document*',
//                 hintText: documentType == 'NNI' ? '10 chiffres' : documentType == 'NIF' ? '13 chiffres' : 'RCXXXXX'
//               ),
//               validator: (value) {
//                 if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
//                 if (documentType == 'NNI' && value!.length != 10) {
//                   return 'Le NNI doit avoir 10 chiffres';
//                 }
//                 if (documentType == 'NIF' && value!.length != 13) {
//                   return 'Le NIF doit avoir 13 chiffres';
//                 }
//                 return null;
//               },
//               onChanged: (value) => documentNumber = value,
//               keyboardType: TextInputType.number,
//               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//             ),
//           ],
//         ),
//       ),
//       isActive: _currentStep >= 0,
//       state: _step1Validated ? StepState.complete : 
//             (_currentStep > 0 ? StepState.indexed : StepState.editing),
//     );
//   }

//   Step _buildContactStep() {
//     return Step(
//       title: Text('Contact'),
//       content: Column(
//         children: [
//           TextFormField(
//             decoration: InputDecoration(
//               labelText: 'Numéro de téléphone*',
//               hintText: 'Ex: 31234567',
//               prefixText: '+221 '
//             ),
//             keyboardType: TextInputType.phone,
//             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//             validator: (value) {
//               if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
//               if (value!.length != 8) return 'Doit avoir 8 chiffres';
//               if (!value.startsWith('2') && !value.startsWith('3') && !value.startsWith('4')) {
//                 return 'Doit commencer par 2, 3 ou 4';
//               }
//               return null;
//             },
//             onChanged: (value) => phoneNumber = value,
//           ),
//         ],
//       ),
//       isActive: _currentStep >= 1,
//       state: _step2Validated ? StepState.complete : 
//             (_currentStep > 1 ? StepState.indexed : StepState.editing),
//     );
//   }

//   Step _buildSecurityStep() {
//     return Step(
//       title: Text('Sécurité'),
//       content: Column(
//         children: [
//           TextFormField(
//             decoration: InputDecoration(labelText: 'Mot de passe*'),
//             obscureText: true,
//             validator: (value) {
//               if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
//               if (value!.length < 6) return 'Minimum 6 caractères';
//               return null;
//             },
//             onChanged: (value) => password = value,
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             decoration: InputDecoration(labelText: 'Confirmer le mot de passe*'),
//             obscureText: true,
//             validator: (value) {
//               if (value != password) return 'Les mots de passe ne correspondent pas';
//               return null;
//             },
//             onChanged: (value) => confirmPassword = value,
//           ),
//         ],
//       ),
//       isActive: _currentStep >= 2,
//       state: StepState.editing,
//     );
//   }

//   void _continue() {
//     if (_currentStep == 0) {
//       if (_formKey.currentState!.validate()) {
//         setState(() {
//           _step1Validated = true;
//           _currentStep += 1;
//         });
//       }
//     } 
//     else if (_currentStep == 1) {
//       if (phoneNumber?.isNotEmpty ?? false && phoneNumber!.length == 8 && 
//           (phoneNumber!.startsWith('2') || phoneNumber!.startsWith('3') || phoneNumber!.startsWith('4'))) {
//         setState(() {
//           _step2Validated = true;
//           _currentStep += 1;
//         });
//       } else {
//         showToast(
//           'Numéro de téléphone invalide',
//           context: context,
//           position: StyledToastPosition.top,
//           duration: Duration(seconds: 3),
//         );
//       }
//     }
//     else if (_currentStep == 2) {
//       if (password?.isNotEmpty ?? false && password == confirmPassword) {
//         _submitRegistration();
//       } else {
//         showToast(
//           'Veuillez vérifier votre mot de passe',
//           context: context,
//           position: StyledToastPosition.top,
//           duration: Duration(seconds: 3),
//         );
//       }
//     }
//   }

//   void _cancel() {
//     if (_currentStep > 0) {
//       setState(() => _currentStep -= 1);
//     } else {
//       Navigator.of(context).pop();
//     }
//   }

//   Future<void> _submitRegistration() async {
//     setState(() => loading = true);
    
//     try {
//       final Map<String, dynamic> registrationData = {
//         'email': email,
//         'nom_complet': '$firstName $lastName',
//         'numero_telephone': phoneNumber,
//         'nni': documentType == 'NNI' ? documentNumber : null,
//         'nif': documentType == 'NIF' ? documentNumber : null,
//         'rc': documentType == 'RC' ? documentNumber : null,
//         'password': password,
//         'confirm_password': confirmPassword,
//       };

//       registrationData.removeWhere((key, value) => value == null);
      
//       final response = await http.post(
//         Uri.parse('https://akarina.online/user/register/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(registrationData),
//       ).timeout(Duration(seconds: 30));

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 201) {
//         showToast(
//           'Compte créé avec succès!',
//           context: context,
//           position: StyledToastPosition.top,
//           duration: Duration(seconds: 3),
//         );
        
//         Future.delayed(Duration(seconds: 3), () {
//           Navigator.pushReplacementNamed(context, '/login');
//         });
//       } else {
//         String errorMessage = 'Erreur lors de la création du compte';
//         if (responseData.containsKey('errors')) {
//           if (responseData['errors'] is Map) {
//             errorMessage = responseData['errors'].values.join('\n');
//           } else if (responseData['errors'] is String) {
//             errorMessage = responseData['errors'];
//           }
//         } else if (responseData.containsKey('message')) {
//           errorMessage = responseData['message'];
//         }
        
//         showToast(
//           errorMessage,
//           context: context,
//           position: StyledToastPosition.top,
//           duration: Duration(seconds: 5),
//         );
//       }
//     } on http.ClientException catch (e) {
//       showToast(
//         'Erreur de connexion: ${e.message}',
//         context: context,
//         position: StyledToastPosition.top,
//         duration: Duration(seconds: 5),
//       );
//     } on TimeoutException {
//       showToast(
//         'La requête a expiré. Veuillez réessayer',
//         context: context,
//         position: StyledToastPosition.top,
//         duration: Duration(seconds: 5),
//       );
//     } catch (e) {
//       showToast(
//         'Une erreur inattendue est survenue',
//         context: context,
//         position: StyledToastPosition.top,
//         duration: Duration(seconds: 5),
//       );
//       print('Erreur: $e');
//     } finally {
//       if (mounted) {
//         setState(() => loading = false);
//       }
//     }
//   }
// }