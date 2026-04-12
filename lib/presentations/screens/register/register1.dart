// register1.dart (version corrigée)
import 'dart:io';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'register2.dart';

class Register1Page extends StatefulWidget {
  const Register1Page({super.key});

  @override
  State<Register1Page> createState() => _Register1PageState();
}

class _Register1PageState extends State<Register1Page> {
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final nniController = TextEditingController();
  
  File? _identityDocument;
  String? _documentPath;
  bool _isUploading = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    nniController.dispose();
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
                          getTranslated(context, "Informations personnelles")!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w400,
                            color: kgrey700,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        _buildIdentityCard(screenWidth, screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        
                        _buildTextField(
                          controller: nomController,
                          label: getTranslated(context, "Nom")!,
                          hint: getTranslated(context, "Entrez votre nom")!,
                          icon: Icons.person_outline,
                          screenWidth: screenWidth,
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        _buildTextField(
                          controller: prenomController,
                          label: getTranslated(context, "Prénom")!,
                          hint: getTranslated(context, "Entrez votre prénom")!,
                          icon: Icons.person,
                          screenWidth: screenWidth,
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        _buildTextField(
                          controller: nniController,
                          label: getTranslated(context, "NNI")!,
                          hint: getTranslated(context, "Entrez votre NNI")!,
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          screenWidth: screenWidth,
                        ),
                        
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

  Widget _buildIdentityCard(double screenWidth, double screenHeight) {
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: pcolor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: pcolor,
                  size: screenWidth * 0.07,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, "Pièce d'identité")!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                        color: kBlackColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      getTranslated(context, "Téléchargez votre carte d'identité ou passeport")!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: kgrey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.03,
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _identityDocument != null ? pcolor : kgrey300,
                  width: _identityDocument != null ? 2 : 1,
                ),
              ),
              child: _isUploading
                  ? Center(
                      child: SizedBox(
                        height: screenHeight * 0.05,
                        width: screenHeight * 0.05,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _identityDocument != null
                      ? _buildDocumentPreview(screenWidth, screenHeight)
                      : _buildUploadPlaceholder(screenWidth, screenHeight),
            ),
          ),
          
          if (_identityDocument != null) ...[
            SizedBox(height: screenHeight * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _removeDocument,
                  icon: Icon(
                    Icons.delete_outline,
                    size: screenWidth * 0.04,
                    color: Colors.red,
                  ),
                  label: Text(
                    getTranslated(context, "Supprimer")!,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: screenWidth * 0.1,
          color: kgrey600,
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          getTranslated(context, "Appuyez pour télécharger")!,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: kgrey600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          getTranslated(context, "PNG, JPG (Max 5MB)")!,
          style: TextStyle(
            fontSize: screenWidth * 0.025,
            color: kgrey500,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPreview(double screenWidth, double screenHeight) {
    final String fileName = _identityDocument!.path.split('/').last;
    final bool isImage = _identityDocument!.path.toLowerCase().endsWith('.jpg') ||
                         _identityDocument!.path.toLowerCase().endsWith('.jpeg') ||
                         _identityDocument!.path.toLowerCase().endsWith('.png');
    
    return Row(
      children: [
        Container(
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            color: pcolor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _identityDocument!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: screenWidth * 0.07,
                ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName.length > 25 ? '${fileName.substring(0, 22)}...' : fileName,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: kBlackColor,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                _getFileSize(_identityDocument!),
                style: TextStyle(
                  fontSize: screenWidth * 0.025,
                  color: kgrey600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: screenWidth * 0.06,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required double screenWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kgrey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: kgrey600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getTranslated(context, "Choisir une source")!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: getTranslated(context, "Appareil photo")!,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: getTranslated(context, "Galerie")!,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kgrey100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: pcolor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kgrey700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final int fileSizeInBytes = await file.length();
        if (fileSizeInBytes > 5 * 1024 * 1024) {
          _showError(context, getTranslated(context, "Le fichier ne doit pas dépasser 5MB")!);
          return;
        }
        
        setState(() {
          _identityDocument = file;
          _documentPath = pickedFile.path;
        });
      }
    } catch (e) {
      _showError(context, getTranslated(context, "Erreur lors du téléchargement")!);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeDocument() {
    setState(() {
      _identityDocument = null;
      _documentPath = null;
    });
  }

  String _getFileSize(File file) {
    final int bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _validateAndNavigate(BuildContext context) {
    final nom = nomController.text.trim();
    final prenom = prenomController.text.trim();
    final nni = nniController.text.trim();

    if (nom.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre nom")!);
      return;
    }

    if (prenom.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre prénom")!);
      return;
    }

    if (nni.isEmpty) {
      _showError(context, getTranslated(context, "Veuillez entrer votre NNI")!);
      return;
    }

    if (nni.length != 10) {
      _showError(context, getTranslated(context, "Le NNI doit contenir 10 chiffres")!);
      return;
    }

    if (_identityDocument == null) {
      _showError(context, getTranslated(context, "Veuillez télécharger votre pièce d'identité")!);
      return;
    }

    _navigateToRegister2(context);
  }

  void _navigateToRegister2(BuildContext context) {
    final state = context.findAncestorStateOfType<IndexLoginState>();
    
    if (state != null) {
      state.changePage(Register2Page(
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim(),
        nni: nniController.text.trim(),
        identityDocument: _identityDocument,
      ));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Register2Page(
            nom: nomController.text.trim(),
            prenom: prenomController.text.trim(),
            nni: nniController.text.trim(),
            identityDocument: _identityDocument,
          ),
        ),
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