import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/localization/language_constants.dart';
import '../login/index_login.dart';
import 'maison_ceremonie_list_page.dart';
import 'package:akarina/size_config.dart';

class ForfaitPage extends StatefulWidget {
  const ForfaitPage({super.key});

  @override
  State<ForfaitPage> createState() => _ForfaitPageState();
}

class _ForfaitPageState extends State<ForfaitPage>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> forfaits = [];
  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;
  String? userToken;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadForfaits();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadForfaits() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      userToken = await storage.read(key: 'access');
      final url = Uri.parse('https://akarina.shop/akareena/forfaits/');
      http.Response response;
      if (userToken != null && userToken!.isNotEmpty) {
        response = await http.get(url, headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $userToken',
        });
      } else {
        response = await http.get(
          url, 
          headers: {'Content-Type': 'application/json; charset=utf-8'}
        );
      }
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          forfaits = data.map((item) => Map<String, dynamic>.from(item)).toList();
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          errorMessage = "${getTranslated(context, 'Erreur')} ${response.statusCode}: ${getTranslated(context, 'Impossible de charger les forfaits')}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "${getTranslated(context, 'Erreur de connexion')}: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _demanderOuvertureForfait(String forfaitNom,
      {File? preuvePaiement, String? notes}) async {
    setState(() => isProcessing = true);
    try {
      final token = await storage.read(key: 'access');
      if (token == null || token.isEmpty) {
        _showLoginDialog();
        setState(() => isProcessing = false);
        return;
      }
      final url = Uri.parse('https://akarina.shop/akareena/forfait/demander/');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['forfait_nom'] = forfaitNom;
      if (notes != null && notes.isNotEmpty) request.fields['notes'] = notes;
      if (preuvePaiement != null && await preuvePaiement.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
            'preuve_paiement', preuvePaiement.path));
      }
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = json.decode(responseBody);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog(responseData);
          await _loadForfaits();
        }
      } else {
        if (mounted) {
          _showErrorDialog(responseData['message'] ?? getTranslated(context, "Erreur lors de la demande")!);
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog("${getTranslated(context, 'Erreur de connexion')}: $e");
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadForfaits,
          child: CustomScrollView(
            slivers: [
              // _buildSliverHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBody() {
    if (isLoading) return _buildLoadingState();
    if (errorMessage != null) return _buildErrorState();
    if (forfaits.isEmpty) return _buildEmptyState();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            const SizedBox(height: 24),
            _buildSectionHeader(),
            const SizedBox(height: 20),
            ...List.generate(forfaits.length, (index) {
              final delay = index * 0.1;
              final animValue = Curves.easeOutCubic.transform(
                ((_animationController.value - delay).clamp(0.0, 1.0) /
                    (1.0 - delay).clamp(0.01, 1.0)),
              );
              return Transform.translate(
                offset: Offset(0, 20 * (1 - animValue)),
                child: Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: _buildForfaitCard(forfaits[index]),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: pcolor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          getTranslated(context, "Choisissez votre accès")!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pcolor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${forfaits.length} ${getTranslated(context, "forfaits")}',
            style: TextStyle(
              color: pcolor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForfaitCard(Map<String, dynamic> forfait) {
    final String nom = forfait['nom'] ?? '';
    final String nomAr = forfait['nom_ar'] ?? '';
    final String description = forfait['description'] ?? '';
    final String descriptionAr = forfait['description_ar'] ?? '';
    final double prixAcces = (forfait['prix_acces'] ?? 0).toDouble();
    final bool estOuvertParDefaut = forfait['est_ouvert_par_defaut'] ?? false;
    final int nbMaisons = forfait['nb_maisons'] ?? 0;
    final double ratingMin = (forfait['rating_min'] ?? 0).toDouble();
    final double ratingMax = (forfait['rating_max'] ?? 0).toDouble();

    final accesUtilisateur = forfait['acces_utilisateur'];
    final bool aAcces = accesUtilisateur != null && accesUtilisateur['est_valide'] == true;
    final bool estAccessible = estOuvertParDefaut || aAcces;
    final double heuresRestantes = aAcces ? (accesUtilisateur['heures_restantes'] ?? 0).toDouble() : 0;

    final bool isPremium = nom.toLowerCase() == 'or' || 
                           nom.toLowerCase() == 'premium' || 
                           nom.toLowerCase() == 'gold';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPremium ? pcolor.withOpacity(0.3) : Colors.grey[200]!,
            width: isPremium ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(nom, nomAr, prixAcces, estAccessible, aAcces, isPremium),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTranslatedDescription(description, descriptionAr),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  _buildStatsRow(nbMaisons, ratingMin, ratingMax),
                  if (aAcces && heuresRestantes > 0) ...[
                    const SizedBox(height: 12),
                    _buildAccessTimer(heuresRestantes),
                  ],
                  const SizedBox(height: 6),
                  _buildActionButton(forfait, estAccessible, aAcces, prixAcces, isPremium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildCardHeader(String nom, String nomAr, double prixAcces,
    bool estAccessible, bool aAcces, bool isPremium) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16), // Réduit le padding vertical
    decoration: BoxDecoration(
      color: isPremium ? pcolor.withOpacity(0.05) : Colors.grey[50],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: Row(
      children: [
        // Icône - réduite
        Container(
          width: 40, // Réduit de 48 à 40
          height: 40, // Réduit de 48 à 40
          decoration: BoxDecoration(
            color: isPremium ? pcolor.withOpacity(0.15) : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              _getForfaitIcon(nom),
              color: isPremium ? pcolor : Colors.grey[600],
              size: 20, // Réduit de 24 à 20
            ),
          ),
        ),
        const SizedBox(width: 12), // Réduit de 14 à 12
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom du forfait - version compacte
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _getTranslatedName(nom, nomAr).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5, // Réduit de 2 à 1.5
                    color: isPremium ? pcolor : Colors.grey[600],
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Prix
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  prixAcces > 0 
                      ? '${prixAcces.toStringAsFixed(0)} ${getTranslated(context, "MRU")!}' 
                      : getTranslated(context, "Gratuit")!,
                  style: const TextStyle(
                    fontSize: 18, // Réduit de 20 à 18
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8), // Ajouté pour l'espacement
        // Badge de statut
        _buildStatusBadge(estAccessible, aAcces),
      ],
    ),
  );
}

Widget _buildStatusBadge(bool estAccessible, bool aAcces) {
  if (estAccessible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Réduit
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16), // Réduit de 20 à 16
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, // Réduit de 6 à 5
            height: 5, // Réduit de 6 à 5
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4), // Réduit de 6 à 4
          Text(
            getTranslated(context, "Actif")!,
            style: const TextStyle(
              fontSize: 9, // Réduit de 11 à 9
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Réduit
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(16), // Réduit de 20 à 16
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 10, color: Colors.grey[600]), // Réduit de 12 à 10
        const SizedBox(width: 3), // Réduit de 4 à 3
        Text(
          getTranslated(context, "Verrouillé")!,
          style: TextStyle(
            fontSize: 9, // Réduit de 11 à 9
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatsRow(int nbMaisons, double ratingMin, double ratingMax) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.villa_outlined,
          value: '$nbMaisons',
          label: getTranslated(context, "Maisons")!,
        ),
        Container(width: 1, height: 28, color: Colors.grey[300]),
        _buildStatItem(
          icon: Icons.star_outline,
          value: '$ratingMin–$ratingMax',
          label: getTranslated(context, "Classement")!,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTimer(double heuresRestantes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            '${getTranslated(context, "Accès valide encore")} ${_formatHeures(heuresRestantes)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> forfait, bool estAccessible,
      bool aAcces, double prixAcces, bool isPremium) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isProcessing
            ? null
            : () => _handleForfaitAction(forfait, estAccessible, aAcces),
        style: ElevatedButton.styleFrom(
          backgroundColor: estAccessible ? pcolor : Colors.grey[800],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getButtonText(estAccessible, aAcces, prixAcces),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    estAccessible ? Icons.arrow_forward : Icons.lock_open,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(80)),
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(pcolor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            getTranslated(context, "Chargement des forfaits...")!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(60)),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.wifi_off_rounded, size: 32, color: Colors.red[400]),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _loadForfaits,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: pcolor),
            label: Text(
              getTranslated(context, "Réessayer")!,
              style: const TextStyle(
                color: pcolor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(60)),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            getTranslated(context, "Aucun forfait disponible")!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDemandeOuvertureDialog(Map<String, dynamic> forfait) {
    final notesController = TextEditingController();
    File? selectedFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: pcolor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getForfaitIcon(forfait['nom']),
                          color: pcolor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslated(context, "Demande d'ouverture")!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              forfait['nom'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pcolor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pcolor.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Montant à régler")!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${forfait['prix_acces']} ${getTranslated(context, "MRU")!}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: pcolor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    getTranslated(context, "Preuve de paiement")!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80
                        );
                        if (image != null) {
                          setStateDialog(() => selectedFile = File(image.path));
                        }
                      } catch (_) {}
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedFile != null ? pcolor : Colors.grey[300]!,
                          width: selectedFile != null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: selectedFile != null
                            ? pcolor.withOpacity(0.03)
                            : Colors.grey[50],
                      ),
                      child: selectedFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(selectedFile!, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setStateDialog(() => selectedFile = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: pcolor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getTranslated(context, "Appuyer pour ajouter une image")!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'JPG, PNG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getTranslated(context, "Notes (optionnel)")!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: getTranslated(context, "Ajouter un commentaire..."),
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: pcolor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            getTranslated(context, "Annuler")!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _demanderOuvertureForfait(
                              forfait['nom'],
                              preuvePaiement: selectedFile,
                              notes: notesController.text.isNotEmpty
                                  ? notesController.text
                                  : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pcolor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            getTranslated(context, "Envoyer la demande")!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        icon: Icons.person_outline_rounded,
        iconColor: pcolor,
        iconBg: pcolor.withOpacity(0.1),
        title: getTranslated(context, "Connexion requise")!,
        message: getTranslated(context, "Veuillez vous connecter pour accéder à ce forfait.")!,
        actions: [
          _dialogButton(
            label: getTranslated(context, "Annuler")!,
            onTap: () => Navigator.pop(context),
            outlined: true,
          ),
          _dialogButton(
            label: getTranslated(context, "Se connecter")!,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IndexLogin()));
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green,
        iconBg: Colors.green.withOpacity(0.1),
        title: getTranslated(context, "Demande envoyée")!,
        message: response['message'] ?? getTranslated(context, "Votre demande a été envoyée avec succès.")!,
        extra: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(getTranslated(context, "Référence")!, '${response['demande_id']}'),
                  _infoRow(getTranslated(context, "Forfait")!, '${response['forfait']}'),
                  _infoRow(getTranslated(context, "Montant")!, '${response['montant']} MRU'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getTranslated(context, "Votre demande est en attente de validation.")!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          _dialogButton(
            label: getTranslated(context, "Fermer")!,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red[400]!,
        iconBg: Colors.red.withOpacity(0.05),
        title: getTranslated(context, "Une erreur est survenue")!,
        message: message,
        actions: [
          _dialogButton(
            label: getTranslated(context, "Fermer")!,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDialog({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    Widget? extra,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            if (extra != null) extra,
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map((a) => Padding(
                      padding: const EdgeInsets.only(left: 8), 
                      child: a
                  ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogButton({
    required String label,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[600],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: pcolor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  void _handleForfaitAction(
      Map<String, dynamic> forfait, bool estAccessible, bool aAcces) async {
    if (estAccessible) {
      final String forfaitNom = forfait['nom'];
      final double ratingMin = (forfait['rating_min'] ?? 0).toDouble();
      final double ratingMax = (forfait['rating_max'] ?? 0).toDouble();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MaisonCeremonieListPage(
            forfaitNom: forfaitNom,
            ratingMin: ratingMin,
            ratingMax: ratingMax,
          ),
        ),
      );
      return;
    }
    final token = await storage.read(key: 'access');
    if (token == null || token.isEmpty) {
      _showLoginDialog();
      return;
    }
    _showDemandeOuvertureDialog(forfait);
  }

  String _getTranslatedName(String nom, String nomAr) {
    final language = Localizations.localeOf(context).languageCode;
    if (language == "ar" && nomAr.isNotEmpty) {
      return nomAr;
    }
    return nom;
  }

  String _getTranslatedDescription(String description, String descriptionAr) {
    final language = Localizations.localeOf(context).languageCode;
    if (language == "ar" && descriptionAr.isNotEmpty) {
      return descriptionAr;
    }
    return description;
  }

  String _formatHeures(double heures) {
    if (heures < 1) return '${(heures * 60).round()} ${getTranslated(context, "min")}';
    if (heures < 24) return '${heures.round()} ${getTranslated(context, "h")}';
    return '${(heures / 24).round()} ${getTranslated(context, "jours")}';
  }

  String _getButtonText(bool estAccessible, bool aAcces, double prix) {
    if (estAccessible && aAcces) return getTranslated(context, "Accéder aux maisons")!;
    if (estAccessible && !aAcces) return getTranslated(context, "Accès gratuit")!;
    if (prix > 0) return '${getTranslated(context, "Débloquer")} · ${prix.toStringAsFixed(0)} ${getTranslated(context, "MRU")!}';
    return getTranslated(context, "Verrouillé")!;
  }

  IconData _getForfaitIcon(String nom) {
    switch (nom.toLowerCase()) {
      case 'standard':
        return Icons.verified_outlined;
      case 'basique':
        return Icons.star_half_rounded;
      case 'or':
      case 'gold':
      case 'premium':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.celebration_outlined;
    }
  }
}