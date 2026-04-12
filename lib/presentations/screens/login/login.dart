import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/login_state.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/login_model.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/input.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/layout/layout.dart';
import 'package:akarina/presentations/screens/register/register1.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'index_login.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final telephonecontroller = TextEditingController();
  final passcontroller = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  bool isPasswordVisible = false;
  
  // Animations principales
  late AnimationController _mainAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Animations séquentielles pour les champs
  late AnimationController _fieldsAnimationController;
  late List<Animation<double>> _fieldFadeAnimations;
  late List<Animation<Offset>> _fieldSlideAnimations;
  
  // Animation pour le bouton
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation principale
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Animations séquentielles des champs
    _fieldsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fieldFadeAnimations = List.generate(4, (index) {
      return CurvedAnimation(
        parent: _fieldsAnimationController,
        curve: Interval(
          index * 0.12,
          1.0,
          curve: Curves.easeOutQuad,
        ),
      );
    });
    
    _fieldSlideAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _fieldsAnimationController,
        curve: Interval(
          index * 0.12,
          1.0,
          curve: Curves.easeOutBack,
        ),
      ));
    });
    
    // Animation du bouton
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Démarrage des animations
    _mainAnimationController.forward();
    _fieldsAnimationController.forward();
    
    // Ajout des listeners pour les FocusNodes
    _phoneFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
    if (_phoneFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    telephonecontroller.dispose();
    passcontroller.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    
    _mainAnimationController.dispose();
    _fieldsAnimationController.dispose();
    _buttonAnimationController.dispose();
    
    super.dispose();
  }

  @override
// Dans votre fichier login.dart
@override
Widget build(BuildContext context) {
  return BlocConsumer<LoginCubit, LoginStates>(
    listener: (context, state) {
      if (state is LoginErrorState) {
        _showAnimatedSnackBar(state.error, Colors.red);
        if (mounted) {
          _buttonAnimationController.reverse();
        }
      } 
      else if (state is LoginSuccessState) {
        _handleLoginSuccess(context, state.loginModel);
      }
      else if (state is LoginAccountBlockedState) {
        // Compte bloqué
        _handleAccountBlocked(context, state);
        if (mounted) {
          _buttonAnimationController.reverse();
        }
      }
      else if (state is LoginAccountInactiveState) {
        // Compte inactif
        _handleAccountInactive(context, state);
        if (mounted) {
          _buttonAnimationController.reverse();
        }
      }
      else if (state is LoginLoadingState) {
        if (mounted) {
          _buttonAnimationController.forward();
        }
      }
    },
    builder: (context, state) {
      return _buildLoginForm(context, state);
    },
  );
}

// Ajoutez ces méthodes dans votre classe Login
void _handleAccountBlocked(BuildContext context, LoginAccountBlockedState state) {
  HapticFeedback.heavyImpact();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.block,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              getTranslated(context, "Compte Bloqué")!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.contact_support,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getTranslated(context, "Veuillez contacter l'administration pour réactiver votre compte")!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, "Contactez-nous")!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        // Appel téléphonique
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _makePhoneCall("20203000");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone, size: 20, color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // WhatsApp
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _openWhatsApp("20203000");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chat, size: 20, color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // SMS
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _sendSMS("20203000", message: "Bonjour, mon compte est bloqué. Pouvez-vous m'aider?");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sms, size: 20, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Email
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _sendEmail("contact@akarina.com");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.email, size: 20, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
          child: Text(getTranslated(context, "Fermer")!),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.help),
          label: Text(getTranslated(context, "Aide")!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

void _handleAccountInactive(BuildContext context, LoginAccountInactiveState state) {
  HapticFeedback.heavyImpact();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              getTranslated(context, "Compte Inactif")!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getTranslated(context, "Activez votre compte pour accéder à tous nos services")!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(getTranslated(context, "Plus tard")!),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Rediriger vers la page d'activation
            _showActivationDialog(context);
          },
          icon: Icon(Icons.check_circle),
          label: Text(getTranslated(context, "Activer maintenant")!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// Ajoutez ces méthodes utilitaires si nécessaire
void _showActivationDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated(context, "Activation du compte")!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(getTranslated(context, "Entrez le code d'activation reçu par SMS")!),
            const SizedBox(height: 16),
            TextFormField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: getTranslated(context, "Code d'activation")!,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getTranslated(context, "Annuler")!),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implémentez l'appel API d'activation ici
              Navigator.pop(context);
              _showAnimatedSnackBar(
                getTranslated(context, "Compte activé avec succès!")!,
                Colors.green,
              );
            },
            child: Text(getTranslated(context, "Activer")!),
          ),
        ],
      ),
    );
  }



// Méthode pour les appels téléphoniques
void _makePhoneCall(String phoneNumber) async {
  Navigator.pop(context); // Fermer le modal
  
  // Formater le numéro de téléphone
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  
  try {
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      _showAnimatedSnackBar(
        getTranslated(context, "Appel en cours...")!,
        Colors.green,
      );
    } else {
      _showAnimatedSnackBar(
        getTranslated(context, "Impossible de passer l'appel")!,
        Colors.red,
      );
    }
  } catch (e) {
    _showAnimatedSnackBar(
      getTranslated(context, "Erreur lors de l'appel")!,
      Colors.red,
    );
  }
}

// Méthode pour ouvrir WhatsApp
void _openWhatsApp(String phoneNumber) async {
  Navigator.pop(context); // Fermer le modal
  
  // Formater le numéro pour WhatsApp (sans les espaces)
  String formattedNumber = phoneNumber.replaceAll(' ', '');
  
  // Essayer d'abord avec le schéma WhatsApp
  final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$formattedNumber');
  
  try {
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
      _showAnimatedSnackBar(
        getTranslated(context, "Ouverture WhatsApp...")!,
        Colors.green,
      );
    } else {
      // Fallback: ouvrir le navigateur avec le lien WhatsApp Web
      final Uri whatsappWebUri = Uri.parse('https://wa.me/$formattedNumber');
      if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri);
        _showAnimatedSnackBar(
          getTranslated(context, "Ouverture WhatsApp Web...")!,
          Colors.green,
        );
      } else {
        _showAnimatedSnackBar(
          getTranslated(context, "WhatsApp n'est pas installé")!,
          Colors.red,
        );
      }
    }
  } catch (e) {
    _showAnimatedSnackBar(
      getTranslated(context, "Erreur lors de l'ouverture de WhatsApp")!,
      Colors.red,
    );
  }
}

// Méthode pour envoyer un SMS
void _sendSMS(String phoneNumber, {String? message}) async {
  Navigator.pop(context); // Fermer le modal
  
  // Formater le numéro
  String formattedNumber = phoneNumber.replaceAll(' ', '');
  
  // Construire l'URI SMS
  final Uri smsUri = message != null
      ? Uri(scheme: 'sms', path: formattedNumber, query: 'body=$message')
      : Uri(scheme: 'sms', path: formattedNumber);
  
  try {
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      _showAnimatedSnackBar(
        getTranslated(context, "Ouverture SMS...")!,
        Colors.green,
      );
    } else {
      _showAnimatedSnackBar(
        getTranslated(context, "Impossible d'envoyer le SMS")!,
        Colors.red,
      );
    }
  } catch (e) {
    _showAnimatedSnackBar(
      getTranslated(context, "Erreur lors de l'envoi du SMS")!,
      Colors.red,
    );
  }
}

// Méthode pour envoyer un email
void _sendEmail(String email) async {
  Navigator.pop(context); // Fermer le modal
  
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: email,
    query: 'subject=${Uri.encodeComponent(getTranslated(context, "Support Akarina")!)}&body=${Uri.encodeComponent(getTranslated(context, "Bonjour, j'ai besoin d'aide concernant mon compte...")!)}',
  );
  
  try {
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      _showAnimatedSnackBar(
        getTranslated(context, "Ouverture de l'application email...")!,
        Colors.green,
      );
    } else {
      _showAnimatedSnackBar(
        getTranslated(context, "Aucune application email trouvée")!,
        Colors.red,
      );
    }
  } catch (e) {
    _showAnimatedSnackBar(
      getTranslated(context, "Erreur lors de l'ouverture de l'email")!,
      Colors.red,
    );
  }
}

  Widget _buildLoginForm(BuildContext context, LoginStates state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedTitles(),
                      SizedBox(height: getProportionateScreenHeight(28)),
                      _buildAnimatedFormFields(state),
                      SizedBox(height: getProportionateScreenHeight(24)),
                      _buildAnimatedLoginButton(state),
                      SizedBox(height: getProportionateScreenHeight(24)),
                      _buildAnimatedRegisterSection(),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      _buildAnimatedContactButton(),
                      SizedBox(height: getProportionateScreenHeight(16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildAnimatedTitles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 30 * (1 - clampedValue)),
              child: Opacity(
                opacity: clampedValue,
                child: child,
              ),
            );
          },
          child: Text(
            getTranslated(context, "cnx")!,
            style: const TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuad,
          builder: (context, double value, child) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 20 * (1 - clampedValue)),
              child: Opacity(
                opacity: clampedValue * 0.8,
                child: child,
              ),
            );
          },
          child: Text(
            getTranslated(context, "Bienvenue, connectez-vous à votre compte")!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: kgrey700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildAnimatedFormFields(LoginStates state) {
    return Column(
      children: [
        FadeTransition(
          opacity: _fieldFadeAnimations[0],
          child: SlideTransition(
            position: _fieldSlideAnimations[0],
            child: _buildModernInputField(
              controller: telephonecontroller,
              focusNode: _phoneFocusNode,
              label: getTranslated(context, "Numéro de Téléphone")!,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return getTranslated(context, "telobligatoire");
                }
                if (value.length != 8) {
                  return getTranslated(context, "telnonvalide");
                }
                if (!value.startsWith('2') && !value.startsWith('3') && !value.startsWith('4')) {
                  return getTranslated(context, "telnonvalide");
                }
                return null;
              },
            ),
          ),
        ),
        
        SizedBox(height: getProportionateScreenHeight(18)),
        
        FadeTransition(
          opacity: _fieldFadeAnimations[1],
          child: SlideTransition(
            position: _fieldSlideAnimations[1],
            child: _buildModernInputField(
              controller: passcontroller,
              focusNode: _passwordFocusNode,
              label: getTranslated(context, "code")!,
              icon: Icons.lock_outline,
              isPassword: !isPasswordVisible,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    key: ValueKey(isPasswordVisible),
                    size: 20,
                    color: kgrey600,
                  ),
                ),
                onPressed: _togglePasswordVisibility,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ),
        
        FadeTransition(
          opacity: _fieldFadeAnimations[2],
          child: SlideTransition(
            position: _fieldSlideAnimations[2],
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _animateButtonTap(() {
                  _showForgotPasswordDialog(context);
                }),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  getTranslated(context, "Mot de passe oublié ?")!,
                  style: TextStyle(
                    fontSize: 13,
                    color: kgrey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final hasFocus = focusNode?.hasFocus ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: hasFocus ? Colors.white : kgrey50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: pcolor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hasFocus ? pcolor : kgrey600, 
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon, 
            size: 22, 
            color: hasFocus ? pcolor : kgrey600,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: pcolor, width: 1.5),
          ),
          filled: true,
          fillColor: hasFocus ? Colors.white : kgrey50,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAnimatedLoginButton(LoginStates state) {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: SizedBox(
        width: double.infinity,
        child: Defaultbutton1(
          text: getTranslated(context, "Se connecter")!,
          textcolor: kWhiteColor,
          borderRadius: 16,
          height: getProportionateScreenHeight(52),
          color: pcolor,
          isLoading: state is LoginLoadingState,
          onTap: state is LoginLoadingState 
              ? null 
              : () => _performLoginWithAnimation(context),
        ),
      ),
    );
  }

  Widget _buildAnimatedRegisterSection() {
    return FadeTransition(
      opacity: _fieldFadeAnimations[3],
      child: SlideTransition(
        position: _fieldSlideAnimations[3],
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                getTranslated(context, "Vous n'avez pas un compte?")!,
                style: TextStyle(
                  fontSize: 14,
                  color: kgrey700,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _animateButtonTap(() => _changeToRegister1(context)),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      getTranslated(context, "créer un compte")!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: pcolor,
                        decoration: TextDecoration.underline,
                        decorationColor: pcolor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContactButton() {
    return FadeTransition(
      opacity: _fieldFadeAnimations[3],
      child: SlideTransition(
        position: _fieldSlideAnimations[3],
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _animateButtonTap(() {
                _showContactModal(context);
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: kgrey300, width: 1.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: kgrey700),
                    const SizedBox(width: 8),
                    Text(
                      getTranslated(context, "Contactez-nous")!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kgrey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Dialog pour l'envoi du code de réinitialisation
void _showForgotPasswordDialog(BuildContext context) {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pcolor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: pcolor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Titre
                Text(
                  getTranslated(context, "Réinitialiser le mot de passe")!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  getTranslated(context, "Entrez votre adresse email pour recevoir un code de réinitialisation")!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: kgrey600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Champ email
                Container(
                  decoration: BoxDecoration(
                    color: kgrey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: getTranslated(context, "Adresse email")!,
                      prefixIcon: Icon(Icons.email_outlined, color: pcolor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kgrey50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          getTranslated(context, "Annuler")!,
                          style: TextStyle(
                            fontSize: 16,
                            color: kgrey600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading 
                            ? null 
                            : () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty) {
                                  _showAnimatedSnackBar(
                                    getTranslated(context, "Veuillez entrer votre email")!,
                                    Colors.red,
                                  );
                                  return;
                                }
                                
                                if (!email.contains('@') || !email.contains('.')) {
                                  _showAnimatedSnackBar(
                                    getTranslated(context, "Email invalide")!,
                                    Colors.red,
                                  );
                                  return;
                                }
                                
                                setState(() {
                                  isLoading = true;
                                });
                                
                                // Appel API pour envoyer le code
                                final success = await _sendResetCode(email);
                                
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  
                                  if (success) {
                                    // Fermer le premier dialog
                                    Navigator.pop(context);
                                    // Afficher le deuxième dialog avec un délai
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (mounted) {
                                        _showResetPasswordPage(email);
                                      }
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pcolor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                getTranslated(context, "Envoyer")!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Page de réinitialisation avec code
void _showResetPasswordPage(String email) {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pcolor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.password,
                    color: pcolor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Titre
                Text(
                  getTranslated(context, "Nouveau mot de passe")!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  getTranslated(context, "Entrez le code reçu par email et votre nouveau mot de passe")!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: kgrey600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Champ code
                Container(
                  decoration: BoxDecoration(
                    color: kgrey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: getTranslated(context, "Code de réinitialisation")!,
                      prefixIcon: Icon(Icons.security, color: pcolor),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kgrey50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Champ nouveau mot de passe
                Container(
                  decoration: BoxDecoration(
                    color: kgrey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: newPasswordController,
                    obscureText: !isNewPasswordVisible,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: getTranslated(context, "Nouveau code")!,
                      prefixIcon: Icon(Icons.lock_outline, color: pcolor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kgrey50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Champ confirmation
                Container(
                  decoration: BoxDecoration(
                    color: kgrey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: getTranslated(context, "Confirmer le code")!,
                      prefixIcon: Icon(Icons.lock_outline, color: pcolor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kgrey50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          getTranslated(context, "Annuler")!,
                          style: TextStyle(
                            fontSize: 16,
                            color: kgrey600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading 
                            ? null 
                            : () async {
                                final code = codeController.text.trim();
                                final newPassword = newPasswordController.text.trim();
                                final confirmPassword = confirmPasswordController.text.trim();
                                
                                if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                                  _showAnimatedSnackBar(
                                    getTranslated(context, "Veuillez remplir tous les champs")!,
                                    Colors.red,
                                  );
                                  return;
                                }
                                
                                if (newPassword != confirmPassword) {
                                  _showAnimatedSnackBar(
                                    getTranslated(context, "Les codes ne correspondent pas")!,
                                    Colors.red,
                                  );
                                  return;
                                }
                                
                                if (newPassword.length != 4) {
                                  _showAnimatedSnackBar(
                                    getTranslated(context, "Le code doit contenir 4 chiffres")!,
                                    Colors.red,
                                  );
                                  return;
                                }
                                
                                setState(() {
                                  isLoading = true;
                                });
                                
                                // Appel API pour réinitialiser le mot de passe
                                final success = await _resetPassword(email, code, newPassword, confirmPassword);
                                
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  
                                  if (success) {
                                    // Fermer le dialog de réinitialisation
                                    Navigator.pop(context);
                                    
                                    // Afficher un message de succès
                                    _showAnimatedSnackBar(
                                      getTranslated(context, "Mot de passe réinitialisé avec succès!")!,
                                      Colors.green,
                                    );
                                    
                                    // Redirection vers la page de login après un délai
                                    Future.delayed(const Duration(milliseconds: 1500), () {
                                      if (mounted) {
                                        // Optionnel: fermer tous les dialogs et retourner au login
                                        Navigator.popUntil(context, (route) => route.isFirst);
                                      }
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pcolor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                getTranslated(context, "Réinitialiser")!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// API: Envoyer le code de réinitialisation - RETOURNE UN BOOLEAN
Future<bool> _sendResetCode(String email) async {
  try {
    final response = await http.post(
      Uri.parse('https://akarina.shop/user/auth/send-reset-code/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _showAnimatedSnackBar(
        data['message'] ?? getTranslated(context, "Code envoyé avec succès")!,
        Colors.green,
      );
      return true;
    } else {
      final data = jsonDecode(response.body);
      _showAnimatedSnackBar(
        data['message'] ?? getTranslated(context, "Erreur lors de l'envoi du code")!,
        Colors.red,
      );
      return false;
    }
  } catch (e) {
    _showAnimatedSnackBar(
      getTranslated(context, "Erreur de connexion")!,
      Colors.red,
    );
    return false;
  }
}

// API: Réinitialiser le mot de passe - RETOURNE UN BOOLEAN
Future<bool> _resetPassword(String email, String code, String newPassword, String confirmPassword) async {
  try {
    final response = await http.post(
      Uri.parse('https://akarina.shop/user/auth/reset-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _showAnimatedSnackBar(
        data['message'] ?? getTranslated(context, "Mot de passe réinitialisé avec succès")!,
        Colors.green,
      );
      return true;
    } else {
      final data = jsonDecode(response.body);
      _showAnimatedSnackBar(
        data['message'] ?? getTranslated(context, "Erreur lors de la réinitialisation")!,
        Colors.red,
      );
      return false;
    }
  } catch (e) {
    _showAnimatedSnackBar(
      getTranslated(context, "Erreur de connexion")!,
      Colors.red,
    );
    return false;
  }
}


  void _showContactModal(BuildContext context) {
    final String phoneNumber = "20 20 30 00";
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kgrey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTranslated(context, "Contactez-nous")!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: pcolor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getTranslated(context, "Choisissez votre moyen de contact préféré")!,
                style: TextStyle(
                  fontSize: 14,
                  color: kgrey600,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildContactItem(
                        icon: Icons.phone,
                        iconColor: Colors.green,
                        title: getTranslated(context, "Téléphone fixe")!,
                        value: phoneNumber,
                        onTap: () => _makePhoneCall(phoneNumber.replaceAll(' ', '')),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.chat,
                        iconColor: Colors.green,
                        title: "WhatsApp",
                        value: phoneNumber,
                        subtitle: "Cliquez pour envoyer un message",
                        onTap: () => _openWhatsApp(phoneNumber.replaceAll(' ', '')),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.facebook,
                        iconColor: Colors.blue,
                        title: "Facebook",
                        value: "Akarina Officiel",
                        subtitle: "@akarina_officiel",
                        onTap: () => _openFacebook(),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.camera_alt,
                        iconColor: Colors.yellow,
                        title: "Snapchat",
                        value: "@akarina_officiel",
                        subtitle: "Ajoutez-nous sur Snapchat",
                        onTap: () => _openSnapchat(),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.music_note,
                        iconColor: Colors.black,
                        title: "TikTok",
                        value: "@akarina_officiel",
                        subtitle: "Suivez-nous sur TikTok",
                        onTap: () => _openTikTok(),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.email,
                        iconColor: Colors.red,
                        title: "Gmail",
                        value: "contact@akarina.com",
                        subtitle: "Envoyez-nous un email",
                        onTap: () => _sendEmail("contact@akarina.com"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pcolor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      getTranslated(context, "Fermer")!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kgrey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kgrey200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: kgrey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kgrey800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: kgrey500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kgrey200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: kgrey600,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _openFacebook() async {
    Navigator.pop(context);
    _showAnimatedSnackBar(
      getTranslated(context, "Ouverture Facebook...")!,
      Colors.blue,
    );
  }

  void _openSnapchat() async {
    Navigator.pop(context);
    _showAnimatedSnackBar(
      getTranslated(context, "Ouverture Snapchat...")!,
      Colors.yellow,
    );
  }

  void _openTikTok() async {
    Navigator.pop(context);
    _showAnimatedSnackBar(
      getTranslated(context, "Ouverture TikTok...")!,
      Colors.black,
    );
  }


  Future<void> _performLoginWithAnimation(BuildContext context) async {
    final phone = telephonecontroller.text.trim();
    final password = passcontroller.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showAnimatedSnackBar(
        getTranslated(context, "Veuillez remplir tous les champs")!,
        Colors.red,
      );
      return;
    }

    _buttonAnimationController.forward();
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    context.read<LoginCubit>().userLogin(
      phone: phone,
      password: password,
    );
  }

  void _handleLoginSuccess(BuildContext context, LoginModel loginModel) {
    _showAnimatedSnackBar(
      '${getTranslated(context, "Bienvenue")!} ${loginModel.message}!',
      Colors.green,
    );
    
    HapticFeedback.heavyImpact();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Layout()),
          (route) => false,
        );
      }
    });
  }

  void _showAnimatedSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : 
              color == Colors.blue ? Icons.info : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 6,
      ),
    );
  }

  void _animateButtonTap(VoidCallback onTap) async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    onTap();
  }

  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
    HapticFeedback.lightImpact();
  }

  void _changeToRegister1(BuildContext context) {
    final state = context.findAncestorStateOfType<IndexLoginState>();
    state?.changePage(Register1Page());
  }
}