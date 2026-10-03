import 'dart:convert';
import 'dart:io';
import 'package:akarina/data/data_providers/account_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/main.dart';
import 'package:intl/intl.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/cart/my_home.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';

import 'package:akarina/presentations/screens/profile/settings.dart';
import 'package:akarina/presentations/utils/price_utils.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:akarina/data/services/fcm_service.dart';
import 'package:akarina/presentations/utils/app_mode.dart';
import 'package:pin_code_fields/pin_code_fields.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool isLoading = true;
  bool hasInternetConnection = true;
  String? adminToken;
  Map<String, dynamic>? profile;
  PointsSummary? points;
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => appVersion = "Version ${info.version}");
  }

  Future<void> _initializeData() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (!mounted) return;
    setState(() => hasInternetConnection = hasConnection);
    if (!hasConnection) return;

    final token = await storage.read(key: "admin_token");
    if (!mounted) return;
    if (token == null) {
      setState(() {
        adminToken = null;
        isLoading = false;
      });
      return;
    }
    adminToken = token;
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = adminToken;
    if (token == null) return;
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        AccountService().fetchProfile(token),
        AccountService().fetchPoints(token),
      ]);
      if (!mounted) return;
      final fetchedProfile = results[0] as Map<String, dynamic>?;
      if (fetchedProfile == null) {
        // Jeton invalide ou expiré : on repasse en état non connecté.
        await storage.delete(key: "admin_token");
        if (!mounted) return;
        setState(() {
          adminToken = null;
          profile = null;
          points = null;
          isLoading = false;
        });
        return;
      }
      setState(() {
        profile = fetchedProfile;
        points = results[1] as PointsSummary?;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${getTranslated(context, "Erreur")!}: $e")),
      );
    }
  }

  Future<void> _logout() async {
    await FCMService.unregisterToken();
    await storage.delete(key: "admin_token");
    if (!mounted) return;
    setState(() {
      adminToken = null;
      profile = null;
      points = null;
    });
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  @override
  Widget build(BuildContext context) {
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          if (!mounted) return;
          setState(() => hasInternetConnection = hasConnection);
          if (hasConnection) _initializeData();
        },
      );
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: pcolor)),
      );
    }

    if (adminToken == null || profile == null) {
      return _buildLoggedOutView();
    }

    return _buildLoggedInView();
  }

  // ================================================================ non connecté

  Widget _buildLoggedOutView() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: pcolor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(IconBroken.Profile, size: 48, color: pcolor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t("Vous n'êtes pas connecté"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _t("Connectez-vous pour accéder à votre profil, vos points de fidélité et vos réservations."),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 24),
              Defaultbutton(
                text: _t("Se connecter"),
                color: pcolor,
                textcolor: kWhiteColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IndexLogin()),
                ).then((_) => _initializeData()),
              ),
              const SizedBox(height: 32),
              _buildSettingsCard(),
              const SizedBox(height: 20),
              if (appVersion.isNotEmpty)
                Center(child: Text(appVersion, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================ connecté

  Widget _buildLoggedInView() {
    final p = profile!;
    final nomComplet = [p['first_name'], p['last_name']]
        .where((s) => (s ?? '').toString().trim().isNotEmpty)
        .join(' ')
        .trim();
    final displayName = nomComplet.isNotEmpty ? nomComplet : (p['username']?.toString() ?? '');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshableWidget(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(displayName),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    _buildInfoCard(p),
                    const SizedBox(height: 16),
                    _buildPointsCard(p),
                    if ((points?.historique ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildHistoriqueCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                    const SizedBox(height: 16),
                    _buildSettingsCard(),
                    const SizedBox(height: 20),
                    if (appVersion.isNotEmpty)
                      Text(appVersion, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName) {
    final initiale = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return ClipPath(
      clipper: WaveClipperOne(flip: true, reverse: false),
      child: Container(
        height: 190,
        width: double.infinity,
        color: pcolor,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text(
                  initiale,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: pcolor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                displayName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> p) {
    final email = p['email']?.toString() ?? '';
    final telephone = p['telephone']?.toString() ?? '';
    final username = p['username']?.toString() ?? '';

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t("Informations personnelles"),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _openEditSheet,
                icon: Icon(Icons.edit_outlined, color: pcolor, size: 20),
              ),
            ],
          ),
          const Divider(height: 20),
          _infoRow(Icons.person_outline, _t("Nom d'utilisateur"), username),
          if (email.isNotEmpty) _infoRow(Icons.email_outlined, _t("Email"), email),
          if (telephone.isNotEmpty) _infoRow(Icons.phone_outlined, _t("telephone"), telephone),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(Map<String, dynamic> p) {
    final solde = points?.soldePoints ?? p['points_fidelite'] ?? 0;
    final nbFilleuls = p['nb_filleuls']?.toString() ?? '0';
    final estGestionnaire = p['est_gestionnaire'] == true;
    final codeInvitation = p['code_invitation']?.toString();
    final lienInvitation = p['lien_invitation']?.toString();
    final dateCreation = DateTime.tryParse(p['date_creation']?.toString() ?? '');

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, color: pcolor, size: 22),
              const SizedBox(width: 8),
              Text(_t("Compte Agharina"), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
              if (estGestionnaire) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: pcolor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_t("Gestionnaire"), style: TextStyle(color: pcolor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statTile(Icons.stars_rounded, _t("Points de fidélité"), '$solde', Colors.amber.shade700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(Icons.group_rounded, _t("Filleuls"), nbFilleuls, Colors.teal),
              ),
            ],
          ),
          if (codeInvitation != null) ...[
            const SizedBox(height: 14),
            const Divider(),
            _infoRow(Icons.card_giftcard_rounded, _t("Code de parrainage"), codeInvitation),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: lienInvitation ?? codeInvitation));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Copié"))));
                },
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: Text(_t("Copier le lien d'invitation")),
              ),
            ),
          ],
          if (dateCreation != null)
            _infoRow(
              Icons.calendar_today_rounded,
              _t("Membre depuis"),
              '${dateCreation.day.toString().padLeft(2, '0')}/${dateCreation.month.toString().padLeft(2, '0')}/${dateCreation.year}',
            ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey[600]), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildHistoriqueCard() {
    final format = DateFormat('dd/MM/yyyy');
    final historique = points!.historique;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: pcolor, size: 20),
              const SizedBox(width: 8),
              Text(_t("Historique des points"), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),
          for (var i = 0; i < historique.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            _buildMouvementRow(historique[i], format),
          ],
        ],
      ),
    );
  }

  Widget _buildMouvementRow(MouvementPoints m, DateFormat format) {
    final positif = m.estGagne;
    final couleur = positif ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: couleur.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(positif ? Icons.add_rounded : Icons.remove_rounded, color: couleur, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              if (m.dateCreation != null)
                Text(format.format(m.dateCreation!), style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${positif ? '+' : ''}${m.points}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: couleur),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return _buildCard(
      child: Column(
        children: [
          _actionRow(
            icon: IconBroken.Filter,
            label: _t("Ma sélection"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: Icon(
                        Localizations.localeOf(context).languageCode == 'ar' ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2,
                        color: kBlackColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(_t("Ma sélection"), style: TextStyle(color: kBlackColor)),
                    centerTitle: true,
                  ),
                  body: const MyHome(),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _actionRow(
            icon: Icons.settings_outlined,
            label: _t("Paramètres"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          const Divider(height: 1),
          _actionRow(
            icon: IconBroken.Logout,
            label: _t("Déconnexion"),
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _actionRow({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? pcolor),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c))),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ================================================================ paramètres (langue + thème)

  Widget _buildSettingsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t("Préférences"), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          InkWell(
            onTap: _showLanguageDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.language_rounded, size: 20, color: pcolor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_t("Langue"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  FutureBuilder<String>(
                    future: getCurrentLanguage(context),
                    builder: (context, snapshot) {
                      final code = snapshot.data;
                      final label = code == 'ar' ? 'العربية' : (code == 'en' ? 'English' : 'Français');
                      return Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]));
                    },
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 20, color: pcolor),
              const SizedBox(width: 12),
              Expanded(child: Text(_t("Mode sombre"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              Switch(
                value: MyApp.themeModeOf(context) == ThemeMode.dark,
                activeColor: pcolor,
                onChanged: (value) {
                  MyApp.setThemeMode(context, value ? ThemeMode.dark : ThemeMode.light);
                  setState(() {});
                },
              ),
            ],
          ),
          const Divider(height: 20),
          InkWell(
            onTap: _showAppModeDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.apartment_rounded, size: 20, color: pcolor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_t("Mode de l'application"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  FutureBuilder<String?>(
                    future: currentAppMode(),
                    builder: (context, snapshot) {
                      final label = snapshot.data == kAppModeCeremonie
                          ? _t("Maisons de cérémonie")
                          : _t("Agharina complet");
                      return Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]));
                    },
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppModeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_t("Mode de l'application"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            _appModeOption(Icons.celebration_rounded, _t("Maisons de cérémonie"), kAppModeCeremonie),
            _appModeOption(Icons.apartment_rounded, _t("Agharina complet"), kAppModeComplet),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _appModeOption(IconData icon, String label, String mode) {
    return ListTile(
      leading: Icon(icon, color: pcolor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context);
        applyAppMode(context, mode);
      },
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_t("Langue"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            _languageOption('العربية', ARABIC),
            _languageOption('Français', FRENSH),
            _languageOption('English', ENGLISH),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String label, String code) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        final locale = await setLocale(code);
        if (!mounted) return;
        MyApp.setLocale(context, locale);
        Navigator.pop(context);
        setState(() {});
      },
    );
  }

  // ================================================================ édition

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _EditProfileSheet(
        profile: profile!,
        token: adminToken!,
        onSaved: (updated) {
          setState(() => profile = updated);
        },
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String token;
  final ValueChanged<Map<String, dynamic>> onSaved;

  const _EditProfileSheet({required this.profile, required this.token, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile['first_name']?.toString() ?? '');
    _lastNameController = TextEditingController(text: widget.profile['last_name']?.toString() ?? '');
    _telephoneController = TextEditingController(text: widget.profile['telephone']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.profile['email']?.toString() ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _t(String key) => getTranslated(context, key) ?? key;

  Future<void> _save() async {
    // PATCH partielle : on n'envoie que les champs réellement modifiés.
    final fields = <String, dynamic>{};
    void addIfChanged(String key, TextEditingController controller) {
      final value = controller.text.trim();
      if (value != (widget.profile[key]?.toString() ?? '')) {
        fields[key] = value;
      }
    }

    addIfChanged('first_name', _firstNameController);
    addIfChanged('last_name', _lastNameController);
    addIfChanged('telephone', _telephoneController);
    addIfChanged('email', _emailController);

    if (fields.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await AccountService().updateProfile(widget.token, fields);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (updated != null) {
        widget.onSaved(updated);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t("Profil mis à jour avec succès")), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t("Erreur")), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t("Erreur")}: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(_t("Modifier le profil"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: _t("Prénom"),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: _t("Nom"),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _t("telephone"),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _t("Email"),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pcolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_t("Edit"), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class CreditCardWidget extends StatelessWidget {
  final String balance;
  final bool showBalance;
  final VoidCallback onToggleBalance;
  final String accountNumber;
  final String accountId;
  final String status;
  final String date;
  final BuildContext context;

  const CreditCardWidget({
    super.key,
    required this.balance,
    required this.showBalance,
    required this.onToggleBalance,
    required this.accountNumber,
    required this.accountId,
    required this.status,
    required this.date,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  getTranslated(this.context, "compte_bancaire")!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Ligne solde + œil
            _buildBalanceRow(),
            
            // Affichage du solde
            _buildBalanceDisplay(),
            const SizedBox(height: 10),
            
            // Détails du compte
            _buildAccountDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow() {
    return Row(
      children: [
        Text(
          getTranslated(context, "solde")!,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggleBalance,
          child: Row(
            children: [
              Icon(
                showBalance ? Icons.visibility_off : Icons.visibility,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                showBalance ? getTranslated(context, "cacher")! : getTranslated(context, "afficher")!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: showBalance
          ? PriceText(
              '$balance MRU',
              key: const ValueKey('solde'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            )
          : Text(
              '••••••••',
              key: const ValueKey('cache'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
    );
  }

  Widget _buildAccountDetails() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.numbers, color: Colors.white.withOpacity(0.8), size: 18),
            const SizedBox(width: 6),
            Text(
              '${getTranslated(context, "numero_compte")!} $accountNumber',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(width: 16),
            Icon(Icons.verified_user, color: Colors.white.withOpacity(0.8), size: 18),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                color: status == 'active' ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              date,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
            const SizedBox(width: 16),
            Icon(Icons.key, color: Colors.white.withOpacity(0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              '${getTranslated(context, "id_compte")!} $accountId',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      ],
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
    phoneController = TextEditingController(text: widget.userData['numero_telephone']);
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
      isLoaded = true;
    });
    
    if (!_formKey.currentState!.validate()) {
      setState(() {
        isLoaded = false;
      });
      return;
    }

    final token = await storage.read(key: "access");
    if (token == null) {
      setState(() {
        isLoaded = false;
      });
      return;
    }

    try {
      final uri = Uri.parse("https://akarina.shop/user/update-profile/");
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
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {  
        setState(() {
          isLoaded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getTranslated(context, "Profil mis à jour avec succès")!)),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${getTranslated(context, "Erreur")!}: ${response.statusCode} - $responseBody")),
        );
        setState(() {
          isLoaded = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${getTranslated(context, "Erreur")!}: $e")),
      );
      setState(() {
        isLoaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar' 
              ? IconBroken.Arrow___Right_2
              : IconBroken.Arrow___Left_2,
            color: kBlackColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, "Modifier le profil")!,
          style: TextStyle(color: kBlackColor),
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
                      : NetworkImage(widget.userData['image'] ?? 'https://via.placeholder.com/150') as ImageProvider,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: nameController,
                labelText: getTranslated(context, "Nom complet")!,
                validator: (value) => value!.isEmpty ? getTranslated(context, "Ce champ est obligatoire") : null,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                controller: addressController,
                labelText: getTranslated(context, "Adresse")!,
                validator: (value) => value!.isEmpty ? getTranslated(context, "Ce champ est obligatoire") : null,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                controller: phoneController,
                labelText: getTranslated(context, "Téléphone")!,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? getTranslated(context, "Ce champ est obligatoire") : null,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                controller: emailController,
                labelText: getTranslated(context, "Email")!,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? getTranslated(context, "Ce champ est obligatoire") : null,
              ),
              const SizedBox(height: 30),
              isLoaded! ? spiner() : _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Widget _buildUpdateButton() {
    return Defaultbutton(
      height: getProportionateScreenHeight(45),
      width: double.infinity,
      text: getTranslated(context, "Edit")!,
      onTap: updateProfile,
      color: pcolor,
      textcolor: kWhiteColor,
    );
  }
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final TextEditingController amountController = TextEditingController();
  String? selectedPaymentMethod;
  bool isLoading = false;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // final List<Map<String, dynamic>> paymentMethods = [
  //   {
  //     'id': 'bankili',
  //     'name': 'Bankili',
  //     'nameAr': 'بانكيلي',
  //     'image': 'assets/images/bankily.png',
  //     'description': 'Paiement via Bankili',
  //     'descriptionAr': 'الدفع عبر بانكيلي',
  //     'color': Colors.blue,
  //   },
  //   {
  //     'id': 'seddad',
  //     'name': 'Seddad',
  //     'nameAr': 'سداد',
  //     'image': 'assets/images/saddad.png',
  //     'description': 'Paiement via Seddad',
  //     'descriptionAr': 'الدفع عبر سداد',
  //     'color': Colors.green,
  //   },
  // ];

final List<Map<String, dynamic>> paymentMethods = [
  {
    'id': 'bankili',
    'name': 'Bankili',
    'nameAr': 'بانكيلي',
    'image': 'assets/images/bankily.png',
    'description': 'Paiement via Bankili - Bientôt',
    'descriptionAr': 'الدفع عبر بانكيلي - قريباً',
    'color': Colors.grey, // Changé en gris
    'enabled': false, // ❌ Désactivé
  },
  {
    'id': 'seddad',
    'name': 'Seddad',
    'nameAr': 'سداد',
    'image': 'assets/images/saddad.png',
    'description': 'Paiement via Seddad',
    'descriptionAr': 'الدفع عبر سداد',
    'color': Colors.green,
    'enabled': true, // ✅ Activé
  },
];
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            isArabic ? IconBroken.Arrow___Right_2 : IconBroken.Arrow___Left_2,
            color: kBlackColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated(context, "Chargement du compte")!,
          style: TextStyle(color: kBlackColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 24),
            _buildPaymentMethodsGrid(),
            const SizedBox(height: 32),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pcolor.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: pcolor,
          ),
          const SizedBox(height: 12),
          Text(
            getTranslated(context, "Choisissez votre moyen de paiement")!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            getTranslated(context, "Sélectionnez un moyen de paiement pour recharger votre compte")!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "Montant à recharger")!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: getTranslated(context, "Entrez le montant")!,
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsGrid() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "Moyens de paiement disponibles")!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: paymentMethods.length,
          itemBuilder: (context, index) {
            final method = paymentMethods[index];
            final isSelected = selectedPaymentMethod == method['id'];
            
            return _buildPaymentMethodCard(method, isSelected, isArabic);
          },
        ),
      ],
    );
  }

Widget _buildPaymentMethodCard(Map<String, dynamic> method, bool isSelected, bool isArabic) {
  final isEnabled = method['enabled'] ?? true;
  final methodColor = isEnabled ? method['color'] : Colors.grey;
  
  return GestureDetector(
    onTap: isEnabled ? () {
      setState(() {
        selectedPaymentMethod = method['id'];
      });
    } : null,
    child: Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? methodColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? methodColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: methodColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        method['image'],
                        width: 35,
                        height: 35,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.payment,
                            size: 35,
                            color: methodColor,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isArabic ? method['nameAr'] : method['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? methodColor : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isEnabled) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              getTranslated(context, "soon") ?? "Bientôt",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      isArabic ? method['descriptionAr'] : method['description'],
                      style: TextStyle(
                        fontSize: 11,
                        color: isEnabled ? Colors.grey[600] : Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected && isEnabled)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: methodColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              
            if (!isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: selectedPaymentMethod != null && amountController.text.isNotEmpty && !isLoading
            ? () => _processPayment()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: pcolor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    getTranslated(context, "Traitement en cours...")!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                getTranslated(context, "Confirmer le paiement")!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _processPayment() {
    if (selectedPaymentMethod == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Veuillez sélectionner un moyen de paiement et entrer un montant")!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == 'bankili') {
      _showBankiliPaymentDialog();
    } else if (selectedPaymentMethod == 'seddad') {
      _showSeddadPaymentForm();
    }
  }

  void _showBankiliPaymentDialog() {
    final String merchantCode = "023977";
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BankiliPaymentDialog(
          merchantCode: merchantCode,
          amount: amountController.text,
          onConfirm: (phone, passcode, amount, password) async {
            await _processBankiliPayment(phone, passcode, amount, password);
          },
        );
      },
    );
  }

  Future<void> _processBankiliPayment(String phone, String passcode, String amount, String password) async {
    try {
      final String? token = await storage.read(key: "access");
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Session expirée")!),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://akarina.shop/akareena/account/deposit/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'clientPhone': phone,
          'passcode': passcode,
          'amount': amount,
          'language': Localizations.localeOf(context).languageCode == 'ar' ? 'AR' : 'FR',
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          _showSuccessDialog(responseData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? getTranslated(context, "Erreur lors du paiement")!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? getTranslated(context, "Erreur lors du paiement")!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur (${e.runtimeType}): $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSeddadPaymentForm() {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController prenomController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController remarqueController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Paiement via Seddad")!),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${getTranslated(context, "Montant à payer")!}: ${amountController.text} MRU",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(
                    labelText: getTranslated(context, "Nom payeur")!,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prenomController,
                  decoration: InputDecoration(
                    labelText: getTranslated(context, "Prénom du payeur")!,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: getTranslated(context, "Téléphone du payeur")!,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarqueController,
                  decoration: InputDecoration(
                    labelText: getTranslated(context, "Remarque (optionnel)")!,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getTranslated(context, "Annuler")!),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomController.text.isEmpty || 
                    prenomController.text.isEmpty || 
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getTranslated(context, "Veuillez remplir tous les champs obligatoires")!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _processSeddadPayment(
                  nomController.text,
                  prenomController.text,
                  phoneController.text,
                  remarqueController.text,
                );
              },
              child: Text(getTranslated(context, "Confirmer")!),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processSeddadPayment(
    String nomPayeur, 
    String prenomPayeur, 
    String telephonePayeur, 
    String remarque,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      final String? token = await storage.read(key: "access");
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Session expirée")!),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://akarina.shop/user/seddad/demande-peiment/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "montant": amountController.text,
          "nom_payeur": nomPayeur,
          "prenom_payeur": prenomPayeur,
          "telephone_payeur": telephonePayeur,
          "remarque": remarque,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _showSeddadSuccessDialog(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        print(errorData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 
              getTranslated(context, "Erreur lors de la création de la demande de paiement")!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${getTranslated(context, "Erreur")!}: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSeddadSuccessDialog(Map<String, dynamic> responseData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(getTranslated(context, "Demande créée")!),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, "Votre demande de paiement Seddad a été créée avec succès")!,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildSeddadDetailRow(
                  getTranslated(context, "Code de paiement")!, 
                  responseData['code_paiement'] ?? '-'
                ),
                _buildSeddadDetailRow(
                  getTranslated(context, "montant")!,
                  "${responseData['montant'] ?? '-'} MRU",
                  isAmount: true,
                ),
                _buildSeddadDetailRow(
                  getTranslated(context, "Nom payeur")!, 
                  responseData['nom_payeur'] ?? '-'
                ),
                _buildSeddadDetailRow(
                  getTranslated(context, "Téléphone")!, 
                  responseData['telephone_payeur'] ?? '-'
                ),
                const SizedBox(height: 20),
                Text(
                  getTranslated(context, "Donnez ce code au payeur pour effectuer le paiement via l'application Seddad")!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialogue
                Navigator.pop(context, true); // Retour à la page profile avec rafraîchissement
              },
              child: Text(getTranslated(context, "Fermer")!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeddadDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(": "),
          Expanded(child: isAmount ? PriceText(value) : Text(value)),
        ],
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> responseData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BankiliSuccessDialog(
          responseData: responseData,
          onConfirm: () {
            Navigator.pop(context); // Fermer le popup de succès
            Navigator.pop(context); // Fermer le popup Bankili
            Navigator.pop(context, true); // Retourner à la page profile avec flag
          },
        );
      },
    );
  }
}




class BankiliPaymentDialog extends StatefulWidget {
  final String merchantCode;
  final String amount;
  final Future<void> Function(String phone, String passcode, String amount, String password) onConfirm;

  const BankiliPaymentDialog({
    super.key,
    required this.merchantCode,
    required this.amount,
    required this.onConfirm,
  });

  @override
  State<BankiliPaymentDialog> createState() => _BankiliPaymentDialogState();
}

class _BankiliPaymentDialogState extends State<BankiliPaymentDialog> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passcodeController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    amountController.text = widget.amount;
  }

  String _getPaymentInstructions() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    if (isArabic) {
      return "1. انسخ رمز التاجر أعلاه\n2. افتح تطبيق بانكيلي\n3. انقر على B-Pay\n4. أدخل رمز التاجر المنسوخ\n5. أدخل المبلغ: ${widget.amount}\n6. سيعطيك بانكيلي رمز مرور\n7. أدخل رمز المرور أدناه";
    } else if (isEnglish) {
      return "1. Copy the merchant code above\n2. Open the Bankili application\n3. Click on B-Pay\n4. Enter the copied merchant code\n5. Enter the amount: ${widget.amount}\n6. Bankili will give you a passcode\n7. Enter the passcode below";
    } else {
      return "1. Copiez le code marchand ci-dessus\n2. Ouvrez l'application Bankili\n3. Cliquez sur B-Pay\n4. Saisissez le code marchand copié\n5. Saisissez le montant: ${widget.amount}\n6. Bankili vous donnera un passcode\n7. Saisissez le passcode ci-dessous";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.85,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          children: [
            // En-tête fixe
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Logo Bankili
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/bankily.png',
                        width: 35,
                        height: 35,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.payment,
                            size: 35,
                            color: Colors.blue,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Titre
                  Text(
                    getTranslated(context, "Paiement Bankili")!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Code marchand
                    _buildMerchantCodeSection(),
                    const SizedBox(height: 16),
                    
                    // Instructions
                    _buildInstructionsSection(),
                    const SizedBox(height: 20),
                    
                    // Champs de saisie
                    _buildInputFields(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Boutons fixes en bas
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            getTranslated(context, "Code Marchand")!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.merchantCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.merchantCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getTranslated(context, "Code copié")!),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getTranslated(context, "Instructions de paiement")!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPaymentInstructions(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Numéro de téléphone")!,
            prefixIcon: const Icon(Icons.phone, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: passcodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Passcode Bankili")!,
            prefixIcon: const Icon(Icons.lock, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Montant")!,
            prefixIcon: const Icon(Icons.attach_money, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                getTranslated(context, "Annuler")!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (isProcessing)
                  ? null
                  : () async {
                      if (phoneController.text.isEmpty ||
                          passcodeController.text.isEmpty ||
                          amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(getTranslated(context, "Veuillez remplir tous les champs")!),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final TextEditingController passwordController = TextEditingController();
                      double fieldWidth = 50;
                      String? password = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Center(child: Text(getTranslated(context, "password")!)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(getTranslated(context, "enter_password_to_confirm")!),
                                    const SizedBox(height: 24),
                                    PinCodeTextField(
                                      appContext: context,
                                      length: 4,
                                      obscureText: true,
                                      animationType: AnimationType.none,
                                      keyboardType: TextInputType.number,
                                      pinTheme: PinTheme(
                                        shape: PinCodeFieldShape.box,
                                        borderRadius: BorderRadius.circular(8),
                                        fieldHeight: fieldWidth,
                                        fieldWidth: fieldWidth,
                                        activeFillColor: Colors.white,
                                        activeColor: Theme.of(context).primaryColor,
                                        selectedColor: Theme.of(context).primaryColor,
                                        inactiveColor: Colors.grey.shade300,
                                      ),
                                      onCompleted: (pin) {
                                        Navigator.pop(context, pin);
                                      },
                                      onChanged: (value) {
                                        passwordController.text = value;
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              isProcessing = false;
                                            });
                                          },
                                          child: Text(getTranslated(context, "cancel")!),
                                        ),
                                      ),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (passwordController.text.length != 4) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(getTranslated(context, "pin_4_digits_required")!),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                            Navigator.pop(context, passwordController.text);
                                          },
                                          child: Text(getTranslated(context, "confirm")!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      if (password == null || password.isEmpty) {
                        return;
                      }

                      setState(() {
                        isProcessing = true;
                      });

                      try {
                        await widget.onConfirm(
                          phoneController.text,
                          passcodeController.text,
                          amountController.text,
                          password,
                        );
                      } finally {
                        setState(() {
                          isProcessing = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          getTranslated(context, "Traitement en cours...")!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      getTranslated(context, "Confirmer")!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class BankiliSuccessDialog extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final VoidCallback onConfirm;

  const BankiliSuccessDialog({
    super.key,
    required this.responseData,
    required this.onConfirm,
  });

  @override
  State<BankiliSuccessDialog> createState() => _BankiliSuccessDialogState();
}

class _BankiliSuccessDialogState extends State<BankiliSuccessDialog> {
  bool hasTakenScreenshot = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.8,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          children: [
            // En-tête avec icône de succès
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getTranslated(context, "Paiement réussi")!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Message de succès
                    _buildSuccessMessage(),
                    const SizedBox(height: 20),
                    
                    // Détails de la transaction
                    _buildTransactionDetails(),
                    const SizedBox(height: 20),
                    
                    // Instructions pour la capture d'écran
                    _buildScreenshotInstructions(),
                    const SizedBox(height: 20),
                    
                    // Checkbox pour confirmer la capture d'écran
                    _buildScreenshotConfirmation(),
                  ],
                ),
              ),
            ),
            
            // Bouton de confirmation
            _buildConfirmationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            widget.responseData['message'] ?? getTranslated(context, "Dépôt effectué avec succès")!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, "Détails de la transaction")!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            getTranslated(context, "ID Opération")!,
            widget.responseData['operation_id'] ?? '-',
            Icons.receipt,
          ),
          _buildDetailRow(
            getTranslated(context, "Nouveau solde")!,
            '${widget.responseData['new_balance'] ?? '-'} MRU',
            Icons.account_balance_wallet,
            isAmount: true,
          ),
          if (widget.responseData['ebankily_response'] != null) ...[
            _buildDetailRow(
              getTranslated(context, "ID Transaction")!,
              widget.responseData['ebankily_response']['transactionId'] ?? '-',
              Icons.payment,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isAmount = false}) {
    const valueStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: isAmount
                ? PriceText(value, style: valueStyle, textAlign: TextAlign.end)
                : Text(value, style: valueStyle, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.screenshot, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                getTranslated(context, "Capture d'écran requise")!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            getTranslated(context, "Veuillez faire une capture d'écran de cette transaction pour vos archives avant de confirmer.")!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotConfirmation() {
    return Row(
      children: [
        Checkbox(
          value: hasTakenScreenshot,
          onChanged: (value) {
            setState(() {
              hasTakenScreenshot = value ?? false;
            });
          },
          activeColor: Colors.green,
        ),
        Expanded(
          child: Text(
            getTranslated(context, "J'ai fait une capture d'écran de cette transaction")!,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: hasTakenScreenshot ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            getTranslated(context, "Confirmer")!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}