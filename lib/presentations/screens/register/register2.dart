// register2.dart - Version sans OTP
import 'dart:io';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register3.dart';

class Register2Page extends StatefulWidget {
  final String nom;
  final String prenom;
  final String nni;
  final File? identityDocument;

  const Register2Page({
    super.key,
    required this.nom,
    required this.prenom,
    required this.nni,
    this.identityDocument,
  });

  @override
  State<Register2Page> createState() => _Register2PageState();
}

class _Register2PageState extends State<Register2Page> {
  final telephoneController = TextEditingController();
  final emailController = TextEditingController();
  final emplacementController = TextEditingController();
  
  @override
  void dispose() {
    telephoneController.dispose();
    emailController.dispose();
    emplacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return WillPopScope(
      onWillPop: _onWillPop,
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
                          getTranslated(context, "Informations de contact")!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w400,
                            color: kgrey700,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Téléphone
                        _buildPhoneField(screenWidth),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Email
                        _buildEmailField(screenWidth),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Emplacement
                        _buildLocationField(screenWidth),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
                
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.01),
                    child: Defaultbutton(
                      text: getTranslated(context, "suivant")!,
                      textcolor: kWhiteColor,
                      borderRadius: 10,
                      height: screenHeight * 0.06,
                      color: pcolor,
                      onTap: () {
                        _validateAndNavigate(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kgrey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: telephoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        decoration: InputDecoration(
          labelText: getTranslated(context, "Numéro de Téléphone")!,
          hintText: getTranslated(context, "Entrez votre numéro")!,
          prefixIcon: Icon(Icons.phone, color: kgrey600),
          prefixText: "+222 ",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kgrey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: getTranslated(context, "Email")!,
          hintText: getTranslated(context, "Entrez votre email")!,
          prefixIcon: Icon(Icons.email, color: kgrey600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kgrey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: emplacementController,
        decoration: InputDecoration(
          labelText: getTranslated(context, "Emplacement")!,
          hintText: getTranslated(context, "Entrez votre ville/région")!,
          prefixIcon: Icon(Icons.location_on, color: kgrey600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  void _validateAndNavigate(BuildContext context) {
    final telephone = telephoneController.text.trim();
    final email = emailController.text.trim();
    final emplacement = emplacementController.text.trim();

    if (telephone.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre numéro de téléphone")!);
      return;
    }

    if (telephone.length != 8) {
      _showError(context, getTranslated(context, "Le numéro doit avoir 8 chiffres")!);
      return;
    }

    if (!telephone.startsWith('2') && !telephone.startsWith('3') && !telephone.startsWith('4')) {
      _showError(context, getTranslated(context, "Numéro de téléphone invalide")!);
      return;
    }

    if (email.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre email")!);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError(context, getTranslated(context, "Email invalide")!);
      return;
    }

    if (emplacement.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre emplacement")!);
      return;
    }

    _navigateToRegister3(context);
  }

  void _navigateToRegister3(BuildContext context) {
    final state = context.findAncestorStateOfType<IndexLoginState>();
    
    final register3Page = Register3Page(
      nom: widget.nom,
      prenom: widget.prenom,
      nni: widget.nni,
      telephone: telephoneController.text.trim(),
      email: emailController.text.trim(),
      emplacement: emplacementController.text.trim(),
      identityDocument: widget.identityDocument,
    );
    
    if (state != null) {
      state.changePage(register3Page);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => register3Page),
      );
    }
  }

  void _showError(BuildContext context, String message) {
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