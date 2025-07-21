import 'dart:convert';
import 'dart:io';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool hasInternetConnection = true;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String appVersion = "";
  bool showBalance = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    getAppVersion();
  }

  Future<void> _initializeData() async {
    // Vérifier la connectivité internet d'abord
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });
    
    if (!hasConnection) {
      return; // Ne pas charger les données si pas de connexion
    }
    
    fetchUserData();
  }

  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "Version ${packageInfo.version}";
    });
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Session Expirée")!),
          content: Text(getTranslated(context, "Votre session a expiré. Veuillez vous reconnecter.")!),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const IndexLogin()),
                );
              },
              child: Text(getTranslated(context, "Se reconnecter")!),
            ),
          ],
        );
      },
    );
  }

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IndexLogin()),
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

  TextDirection _getTextDirection(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
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

  @override
  Widget build(BuildContext context) {
    // Afficher la page d'erreur de connexion si pas de connexion internet
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection = await ConnectivityService.hasInternetConnection();
          setState(() {
            hasInternetConnection = hasConnection;
          });
          
          if (hasConnection) {
            _initializeData();
          }
        },
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(child: Text(getTranslated(context, "Erreur lors du chargement des données")!))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return Stack(
      children: [
        // Header avec vague
        ClipPath(
          clipper: WaveClipperOne(flip: true, reverse: false),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.10),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Avatar positionné
        Positioned(
          top: 40,
          left: MediaQuery.of(context).size.width / 2 - 65,
          child: _buildProfileAvatar(),
        ),

        // Contenu principal
        Padding(
          padding: const EdgeInsets.only(top: 200),
          child: RefreshableWidget(
            onRefresh: fetchUserData,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (userData?['my_account'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: CreditCardWidget(
                        balance: userData!['my_account']['account_balance'].toString(),
                        showBalance: showBalance,
                        onToggleBalance: () {
                          setState(() {
                            showBalance = !showBalance;
                          });
                        },
                        accountNumber: userData!['my_account']['account_number'],
                        accountId: userData!['my_account']['account_id'].toString(),
                        status: userData!['my_account']['account_status'],
                        date: userData!['my_account']['date'].toString().split('T')[0],
                        context: context,
                      ),
                    ),

                  // Carte infos personnelles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, color: pcolor, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  userData?['nom_complet'] ?? getTranslated(context, "nom_inconnu")!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildUserInfoRow(Icons.email, userData?['email'] ?? '-'),
                            
                            if (userData?['activation_status'] == true)
                              _buildVerificationBadge(context),
                            
                            const SizedBox(height: 20),
                            const Divider(),
                            _buildInfoRow(Icons.phone, getTranslated(context, "telephone")!, userData?['numero_telephone'].substring(4) ?? '-'),
                            _buildInfoRow(Icons.credit_card, getTranslated(context, "nni")!, userData?['nni'] ?? '-'),
                            _buildInfoRow(Icons.location_on, getTranslated(context, "adresse")!, userData?['adrese'] ?? '-'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Boutons d'action
                  _buildActionButtons(context),

                  // Section à propos/version
                  _buildAppVersionSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo dégradé
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [pcolor.withOpacity(0.5), Colors.blueAccent.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        
        // Avatar avec bordure
        AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundImage: NetworkImage(
                userData?['image'] ?? 'https://via.placeholder.com/150',
              ),
            ),
          ),
        ),
        
        // Bouton édition
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              if (userData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userData: userData!),
                  ),
                ).then((value) {
                  if (value == true) fetchUserData();
                });
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: pcolor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoRow(IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 16),
          const SizedBox(width: 5),
          Text(
            getTranslated(context, "compte_verifie")!,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Bouton Chargement du compte (seulement pour les utilisateurs owner)
          if (userData?['client_type'] == 'owner')
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Defaultbutton(
                    text: getTranslated(context, "Chargement du compte")!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsPage(),
                        ),
                      ).then((value) {
                        if (value == true) {
                          fetchUserData();
                        }
                      });
                    },
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          
          // Boutons modifier, supprimer compte et déconnexion
          Row(
            children: [
              Expanded(
                child: Defaultbutton(
                  text: getTranslated(context, "modifier")!,
                  onTap: () {
                    if (userData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(userData: userData!),
                        ),
                      ).then((value) {
                        if (value == true) fetchUserData();
                      });
                    }
                  },
                  color: pcolor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Defaultbutton(
                  text: getTranslated(context, "Supprimer")!,
                  onTap: () => _showDeleteAccountDialog(),
                  color: Colors.red[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bouton déconnexion avec icône
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await storage.delete(key: "access");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const IndexLogin()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconBroken.Logout, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          getTranslated(context, "Déconnexion")!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(
                getTranslated(context, "delete_account")!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, "delete_account_confirm")!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                getTranslated(context, "action_irreversible")!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                getTranslated(context, "ncancel")!,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(getTranslated(context, "confirm_delete")!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppVersionSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        children: [
          Text(
            appVersion,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${getTranslated(context, "Développé par")!} agharinaa.mr",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
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
          ? Text(
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

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'bankili',
      'name': 'Bankili',
      'nameAr': 'بانكيلي',
      'image': 'assets/images/bankily.png',
      'description': 'Paiement via Bankili',
      'descriptionAr': 'الدفع عبر بانكيلي',
      'color': Colors.blue,
    },
    {
      'id': 'seddad',
      'name': 'Seddad',
      'nameAr': 'سداد',
      'image': 'assets/images/saddad.png',
      'description': 'Paiement via Seddad',
      'descriptionAr': 'الدفع عبر سداد',
      'color': Colors.green,
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
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method['id'];
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? method['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? method['color'] : Colors.grey[300]!,
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
                      color: method['color'].withOpacity(0.1),
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
                            color: method['color'],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      isArabic ? method['nameAr'] : method['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? method['color'] : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: method['color'],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
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
    } else {
      setState(() {
        isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Paiement en cours de traitement...")!),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      });
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
        Uri.parse('https://akarina.online/akareena/account/deposit/'),
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
                        // L'utilisateur a annulé ou n'a rien saisi
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
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
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
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