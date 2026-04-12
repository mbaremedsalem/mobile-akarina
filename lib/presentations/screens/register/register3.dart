// register3.dart - Version avec mot de passe robuste
import 'dart:io';
import 'package:akarina/business_logic/cubits/cubit/register_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/register_state.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Register3Page extends StatefulWidget {
  final String nom;
  final String prenom;
  final String nni;
  final String telephone;
  final String email;
  final String emplacement;
  final File? identityDocument;

  const Register3Page({
    super.key,
    required this.nom,
    required this.prenom,
    required this.nni,
    required this.telephone,
    required this.email,
    required this.emplacement,
    this.identityDocument,
  });

  @override
  State<Register3Page> createState() => _Register3PageState();
}

class _Register3PageState extends State<Register3Page> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? selectedClientType;
  
  // Variables pour la force du mot de passe
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasDigits = false;
  bool hasSpecialChars = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    setState(() {
      hasMinLength = password.length >= 8;
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasLowercase = password.contains(RegExp(r'[a-z]'));
      hasDigits = password.contains(RegExp(r'[0-9]'));
      hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get isPasswordStrong {
    return hasMinLength && hasUppercase && hasLowercase && hasDigits && hasSpecialChars;
  }

  double get passwordStrength {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigits) count++;
    if (hasSpecialChars) count++;
    return count / 5;
  }

  Color get passwordStrengthColor {
    double strength = passwordStrength;
    if (strength <= 0.4) return Colors.red;
    if (strength <= 0.7) return Colors.orange;
    return Colors.green;
  }

  String get passwordStrengthText {
    double strength = passwordStrength;
    if (strength <= 0.4) return getTranslated(context, "Faible")!;
    if (strength <= 0.7) return getTranslated(context, "Moyen")!;
    return getTranslated(context, "Fort")!;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocListener<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.registerModel.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            _changeToLogin(context);
          } else if (state is RegisterErrorState) {
            print(state.errorMessage);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslated(context, "créer un compte")!,
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.w600,
                              color: kBlackColor,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            getTranslated(context, "Finalisation")!,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w400,
                              color: kgrey700,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Type de compte
                          _buildAccountTypeSelector(screenWidth, screenHeight),
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Résumé des informations
                          _buildInfoSummary(screenWidth, screenHeight),
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Mot de passe
                          _buildPasswordField(
                            controller: passwordController,
                            label: getTranslated(context, "Mot de passe")!,
                            hint: getTranslated(context, "Entrez votre mot de passe")!,
                            isVisible: isPasswordVisible,
                            onToggle: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                            onChanged: _validatePassword,
                            screenWidth: screenWidth,
                          ),
                          
                          // Indicateur de force du mot de passe
                          if (passwordController.text.isNotEmpty) ...[
                            SizedBox(height: screenHeight * 0.01),
                            _buildPasswordStrengthIndicator(screenWidth),
                          ],
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Confirmer mot de passe
                          _buildPasswordField(
                            controller: confirmPasswordController,
                            label: getTranslated(context, "Confirmer le mot de passe")!,
                            hint: getTranslated(context, "Confirmez votre mot de passe")!,
                            isVisible: isConfirmPasswordVisible,
                            onToggle: () {
                              setState(() {
                                isConfirmPasswordVisible = !isConfirmPasswordVisible;
                              });
                            },
                            screenWidth: screenWidth,
                          ),
                          
                          // Message d'erreur si les mots de passe ne correspondent pas
                          if (confirmPasswordController.text.isNotEmpty && 
                              passwordController.text != confirmPasswordController.text)
                            Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.01),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: screenWidth * 0.04, color: Colors.red),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    getTranslated(context, "Les mots de passe ne correspondent pas")!,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.03,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                  
                  SafeArea(
                    child: BlocBuilder<RegisterCubit, RegisterState>(
                      builder: (context, state) {
                        return Defaultbutton(
                          text: state is RegisterLoadingState 
                            ? getTranslated(context, "Inscription en cours...")! 
                            : getTranslated(context, "S'inscrire")!,
                          textcolor: kWhiteColor,
                          borderRadius: 10,
                          height: screenHeight * 0.06,
                          color: (state is RegisterLoadingState || !isPasswordStrong || passwordController.text != confirmPasswordController.text) 
                            ? Colors.grey 
                            : pcolor,
                          onTap: (state is RegisterLoadingState || !isPasswordStrong || passwordController.text != confirmPasswordController.text)
                            ? null 
                            : () {
                                _registerUser(context);
                              },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: passwordStrength,
                  backgroundColor: Colors.grey[200],
                  color: passwordStrengthColor,
                  minHeight: 6,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              passwordStrengthText,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w600,
                color: passwordStrengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.02),
        Wrap(
          spacing: screenWidth * 0.02,
          runSpacing: screenWidth * 0.01,
          children: [
            _buildRequirementChip(
              "8+ caractères",
              hasMinLength,
              screenWidth,
            ),
            _buildRequirementChip(
              "Majuscule",
              hasUppercase,
              screenWidth,
            ),
            _buildRequirementChip(
              "Minuscule",
              hasLowercase,
              screenWidth,
            ),
            _buildRequirementChip(
              "Chiffre",
              hasDigits,
              screenWidth,
            ),
            _buildRequirementChip(
              "Spécial (!@#...)",
              hasSpecialChars,
              screenWidth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementChip(String text, bool isValid, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.01,
      ),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: screenWidth * 0.03,
            color: isValid ? Colors.green : Colors.grey,
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.025,
              color: isValid ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeSelector(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "Type de compte")!,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            color: kBlackColor,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Row(
          children: [
            Expanded(
              child: _buildAccountTypeCard(
                title: getTranslated(context, "Client")!,
                description: getTranslated(context, "Je veux acheter ou louer")!,
                icon: Icons.person,
                isSelected: selectedClientType == 'client',
                onTap: () {
                  setState(() {
                    selectedClientType = 'client';
                  });
                },
                screenWidth: screenWidth,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: _buildAccountTypeCard(
                title: getTranslated(context, "Vendeur")!,
                description: getTranslated(context, "Je veux vendre ou louer")!,
                icon: Icons.home,
                isSelected: selectedClientType == 'owner',
                onTap: () {
                  setState(() {
                    selectedClientType = 'owner';
                  });
                },
                screenWidth: screenWidth,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: isSelected ? pcolor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? pcolor : kgrey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? pcolor : kgrey600,
              size: screenWidth * 0.08,
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
                color: isSelected ? pcolor : kBlackColor,
              ),
            ),
            SizedBox(height: screenWidth * 0.005),
            Text(
              description,
              style: TextStyle(
                fontSize: screenWidth * 0.025,
                color: kgrey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSummary(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: kgrey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.person, '${widget.prenom} ${widget.nom}', screenWidth),
          SizedBox(height: screenHeight * 0.01),
          _buildInfoRow(Icons.badge, widget.nni, screenWidth),
          SizedBox(height: screenHeight * 0.01),
          _buildInfoRow(Icons.phone, widget.telephone, screenWidth),
          SizedBox(height: screenHeight * 0.01),
          _buildInfoRow(Icons.email, widget.email, screenWidth, isExpanded: true),
          SizedBox(height: screenHeight * 0.01),
          _buildInfoRow(Icons.location_on, widget.emplacement, screenWidth, isExpanded: true),
          if (widget.identityDocument != null) ...[
            SizedBox(height: screenHeight * 0.01),
            _buildInfoRow(Icons.credit_card, "Pièce d'identité téléchargée", screenWidth),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, double screenWidth, {bool isExpanded = false}) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.05, color: pcolor),
        SizedBox(width: screenWidth * 0.02),
        if (isExpanded)
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: screenWidth * 0.035),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            text,
            style: TextStyle(fontSize: screenWidth * 0.035),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    Function(String)? onChanged,
    required double screenWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kgrey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(Icons.lock, color: kgrey600),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: kgrey600,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  void _registerUser(BuildContext context) {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validation du type de compte
    if (selectedClientType == null) {
      _showError(context, getTranslated(context, "Veuillez sélectionner un type de compte")!);
      return;
    }

    if (password.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre mot de passe")!);
      return;
    }

    // Validation de la force du mot de passe
    if (!isPasswordStrong) {
      _showError(context, getTranslated(context, "Veuillez choisir un mot de passe plus fort")!);
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez confirmer votre mot de passe")!);
      return;
    }

    if (password != confirmPassword) {
      _showError(context, getTranslated(context, "Les mots de passe ne correspondent pas")!);
      return;
    }

    final nomComplet = '${widget.prenom} ${widget.nom}';
    final numeroTelephone = '+222${widget.telephone}';
    
    context.read<RegisterCubit>().userRegister(
      email: widget.email,
      nomComplet: nomComplet,
      numeroTelephone: numeroTelephone,
      password: password,
      confirmPassword: confirmPassword,
      clientType: selectedClientType!,
      nni: widget.nni,
      emplacement: widget.emplacement,
      carteIdentiteFile: widget.identityDocument,
    );
  }

  void _changeToLogin(BuildContext context) {
    final state = context.findAncestorStateOfType<IndexLoginState>();
    if (state != null) {
      state.changePage(const Login());
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  void _showError(BuildContext context, String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      
      SnackBar(
        
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final state = context.findAncestorStateOfType<IndexLoginState>();
    if (state != null) {
      state.goBack();
    } else {
      Navigator.pop(context);
    }
    return false;
  }
}