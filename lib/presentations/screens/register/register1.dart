// Inscription — POST https://admin-akarina.akarina.shop/api/inscription/
import 'package:akarina/data/data_providers/account_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/services/fcm_service.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:akarina/presentations/utils/app_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Register1Page extends StatefulWidget {
  const Register1Page({super.key});

  @override
  State<Register1Page> createState() => _Register1PageState();
}

class _Register1PageState extends State<Register1Page> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeParrainController = TextEditingController();

  bool _estGestionnaire = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeParrainController.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? _t("videerror") : null;

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = _t("mots de passe non identiques"));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AccountService().register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        telephone: '222${_phoneController.text.trim()}',
        estGestionnaire: _estGestionnaire,
        codeParrain: _codeParrainController.text.trim().isEmpty ? null : _codeParrainController.text.trim(),
      );

      // Connexion automatique après une inscription réussie.
      final token = await AccountService().login(_usernameController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: "admin_token", value: token);
        FCMService.registerTokenAfterLogin();
        if (!mounted) return;
        enterAppRoot(context);
      } else {
        // Compte créé mais connexion auto échouée : on renvoie vers le login.
        final state = context.findAncestorStateOfType<IndexLoginState>();
        if (state != null) {
          state.goBack();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t("créer un compte"),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kBlackColor),
              ),
              const SizedBox(height: 4),
              Text(
                _t("Rejoignez Agharina en quelques secondes"),
                style: TextStyle(fontSize: 13.5, color: kgrey700),
              ),
              const SizedBox(height: 22),

              if (_errorMessage != null) ...[
                _buildErrorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],

              _buildSection(
                title: _t("Informations personnelles"),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _firstNameController,
                          label: _t("Prénom"),
                          icon: Icons.person_outline,
                          validator: _req,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _lastNameController,
                          label: _t("Nom"),
                          icon: Icons.person_outline,
                          validator: _req,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _usernameController,
                    label: _t("Nom d'utilisateur"),
                    icon: Icons.alternate_email_rounded,
                    validator: _req,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _emailController,
                    label: _t("Email"),
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return _t("videerror");
                      if (!v.contains('@') || !v.contains('.')) return _t("Email invalide");
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildPhoneField(),
                ],
              ),
              const SizedBox(height: 18),

              _buildSection(
                title: _t("Sécurité"),
                children: [
                  _buildPasswordField(
                    controller: _passwordController,
                    label: _t("Mot de passe"),
                    obscure: _obscurePassword,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return _t("videerror");
                      if (v.length < 6) return _t("Le mot de passe doit contenir au moins 6 caractères");
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: _t("Confirmer le mot de passe"),
                    obscure: _obscureConfirmPassword,
                    onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    validator: _req,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildSection(
                title: _t("Type de compte"),
                children: [_buildAccountTypeToggle()],
              ),
              const SizedBox(height: 18),

              _buildSection(
                title: _t("Code de parrainage"),
                trailing: _buildOptionalChip(),
                children: [
                  _buildField(
                    controller: _codeParrainController,
                    label: _t("Code de parrainage"),
                    icon: Icons.card_giftcard_rounded,
                    validator: null,
                  ),
                ],
              ),
              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pcolor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(
                          _t("Créer mon compte"),
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () {
                    final state = context.findAncestorStateOfType<IndexLoginState>();
                    if (state != null) {
                      state.goBack();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13.5, color: kgrey700),
                      children: [
                        TextSpan(text: '${_t("Déjà un compte ?")} '),
                        TextSpan(
                          text: _t("Se connecter"),
                          style: const TextStyle(color: pcolor, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kgrey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _t("Facultatif"),
        style: TextStyle(fontSize: 10.5, color: kgrey700, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kgrey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kgrey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kBlackColor),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kgrey600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kgrey300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kgrey300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: pcolor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
      validator: (v) {
        if (v == null || v.isEmpty) return _t("videerror");
        if (v.length != 8) return _t("Le numéro doit avoir 8 chiffres");
        return null;
      },
      decoration: InputDecoration(
        labelText: _t("Numéro de Téléphone"),
        prefixIcon: Container(
          alignment: Alignment.center,
          width: 56,
          child: Text('+222', style: TextStyle(color: kgrey700, fontWeight: FontWeight.w600, fontSize: 13.5)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kgrey300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kgrey300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: pcolor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: kgrey600),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: kgrey600),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kgrey300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kgrey300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: pcolor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
      ),
    );
  }

  Widget _buildAccountTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: _accountTypeCard(
            title: _t("Particulier"),
            subtitle: _t("Je cherche un bien"),
            icon: Icons.person_rounded,
            selected: !_estGestionnaire,
            onTap: () => setState(() => _estGestionnaire = false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _accountTypeCard(
            title: _t("Gestionnaire"),
            subtitle: _t("Je publie des biens"),
            icon: Icons.apartment_rounded,
            selected: _estGestionnaire,
            onTap: () => setState(() => _estGestionnaire = true),
          ),
        ),
      ],
    );
  }

  Widget _accountTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? pcolor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? pcolor : kgrey300, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? pcolor : kgrey600, size: 22),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? pcolor : kBlackColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10.5, color: kgrey600), textAlign: TextAlign.center),
          ],
        ),
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
