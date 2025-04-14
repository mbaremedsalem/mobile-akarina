import 'dart:convert';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:http/http.dart' as http;


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
