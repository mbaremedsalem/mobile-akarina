import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'maison_ceremonie_detail_page.dart';
import 'package:akarina/size_config.dart';
import '../../../data/localization/language_constants.dart';

class MaisonCeremonieListPage extends StatefulWidget {
  final String forfaitNom;
  final double ratingMin;
  final double ratingMax;

  const MaisonCeremonieListPage({
    super.key,
    required this.forfaitNom,
    required this.ratingMin,
    required this.ratingMax,
  });

  @override
  State<MaisonCeremonieListPage> createState() => _MaisonCeremonieListPageState();
}

class _MaisonCeremonieListPageState extends State<MaisonCeremonieListPage> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> maisons = [];
  List<Map<String, dynamic>> filteredMaisons = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  String? nextUrl;
  Map<String, dynamic>? forfaitInfo;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMaisons();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      filteredMaisons = List.from(maisons);
      return;
    }
    filteredMaisons = maisons.where((maison) {
      final quartier = (maison['quartier_nom'] ?? maison['quartier'] ?? '')
          .toString()
          .toLowerCase();
      final ville = (maison['ville_nom'] ?? maison['ville'] ?? '')
          .toString()
          .toLowerCase();
      final adresse = (maison['adresse'] ?? '')
          .toString()
          .toLowerCase();
      return quartier.contains(_searchQuery) || 
             ville.contains(_searchQuery) ||
             adresse.contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadMaisons({bool loadMore = false}) async {
    if (loadMore && nextUrl == null) return;
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() => isLoading = true);
    }

    try {
      final token = await storage.read(key: 'access');
      final String url;

      if (loadMore && nextUrl != null) {
        url = nextUrl!;
      } else {
        url = 'https://akarina.shop/akareena/forfait/${widget.forfaitNom}/maisons/';
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: token != null && token.isNotEmpty
            ? {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];

        final List<Map<String, dynamic>> convertedResults = results.map((item) {
          final Map<String, dynamic> converted = Map<String, dynamic>.from(item);

          // Convertir les champs numériques
          if (converted['loyer_mensuel'] is String) {
            converted['loyer_mensuel'] = double.tryParse(converted['loyer_mensuel']) ?? 0.0;
          } else if (converted['loyer_mensuel'] is int) {
            converted['loyer_mensuel'] = (converted['loyer_mensuel'] as int).toDouble();
          } else if (converted['loyer_mensuel'] == null) {
            converted['loyer_mensuel'] = 0.0;
          }

          if (converted['surface'] is String) {
            converted['surface'] = double.tryParse(converted['surface']) ?? 0.0;
          } else if (converted['surface'] is int) {
            converted['surface'] = (converted['surface'] as int).toDouble();
          } else if (converted['surface'] == null) {
            converted['surface'] = 0.0;
          }

          if (converted['ratings'] is String) {
            converted['ratings'] = double.tryParse(converted['ratings']) ?? 0.0;
          } else if (converted['ratings'] is int) {
            converted['ratings'] = (converted['ratings'] as int).toDouble();
          } else if (converted['ratings'] == null) {
            converted['ratings'] = 0.0;
          }

          // S'assurer que les images sont bien formatées
          if (converted['images'] != null) {
            final images = converted['images'] as List;
            converted['images'] = images.map((img) {
              final Map<String, dynamic> imageMap = Map<String, dynamic>.from(img);
              
              // Si image est null mais video existe, on utilise une vignette de la vidéo
              if (imageMap['image'] == null && imageMap['video'] != null) {
                // On pourrait générer une vignette mais on garde null pour l'instant
                imageMap['image'] = null;
              }
              
              // S'assurer que image_url et video_url sont définis
              imageMap['image_url'] = imageMap['image'] != null 
                  ? (imageMap['image'].toString().startsWith('http')
                      ? imageMap['image'].toString()
                      : 'https://akarina.shop${imageMap['image'].toString()}')
                  : null;
                  
              imageMap['video_url'] = imageMap['video'] != null
                  ? (imageMap['video'].toString().startsWith('http')
                      ? imageMap['video'].toString()
                      : 'https://akarina.shop${imageMap['video'].toString()}')
                  : null;
                  
              return imageMap;
            }).toList();
          }

          return converted;
        }).toList();

        setState(() {
          if (loadMore) {
            maisons.addAll(convertedResults);
          } else {
            maisons = convertedResults;
          }
          _applyFilter();
          nextUrl = data['next'];
          forfaitInfo = data['forfait_info'];
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          errorMessage = "${getTranslated(context, 'Erreur')} ${response.statusCode}: ${getTranslated(context, 'Impossible de charger les maisons')}";
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "${getTranslated(context, 'Erreur de connexion')}: $e";
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (nextUrl != null && !isLoadingMore && !isLoading && _searchQuery.isEmpty) {
      _loadMaisons(loadMore: true);
    }
  }

  void _navigateToDetail(Map<String, dynamic> maison) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaisonCeremonieDetailPage(
          forfaitNom: widget.forfaitNom,
          maisonId: maison['id'],
        ),
      ),
    );
  }

  void _openVideo(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(videoUrl: videoUrl),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadMaisons(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                sliver: _buildSliverBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: getTranslated(context, "Rechercher par quartier...") ??
                "Rechercher par quartier...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: pcolor, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---------------- BODY ----------------
  Widget _buildSliverBody() {
    if (isLoading) {
      return SliverToBoxAdapter(child: _buildLoadingState());
    }
    if (errorMessage != null) {
      return SliverToBoxAdapter(child: _buildErrorState());
    }
    if (filteredMaisons.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _buildSectionHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.70, // Légèrement ajusté pour mieux contenir le contenu
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildMaisonCard(filteredMaisons[index]),
            childCount: filteredMaisons.length,
          ),
        ),
        if (isLoadingMore)
          SliverToBoxAdapter(child: _buildLoadingMore()),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: pcolor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${filteredMaisons.length} ${getTranslated(context, "maisons disponibles")}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (forfaitInfo != null && _searchQuery.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pcolor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${forfaitInfo!['total_maisons_dans_forfait']}',
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
            getTranslated(context, "Chargement des maisons...")!,
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

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
            style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _loadMaisons(),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: pcolor),
            label: Text(
              getTranslated(context, "Réessayer")!,
              style: const TextStyle(color: pcolor, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearch = _searchQuery.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(60)),
      child: Column(
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.villa_outlined,
            size: 56,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? (getTranslated(context, "Aucun résultat") ?? "Aucun résultat")
                : getTranslated(context, "Aucune maison disponible")!,
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? (getTranslated(context, "Essayez un autre quartier") ?? "Essayez un autre quartier")
                : getTranslated(context, "Aucune maison ne correspond à ce forfait")!,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------- CARD - CORRIGÉE ----------------
// ---------------- CARD - CORRIGÉE AVEC HAUTEUR FIXE ----------------
Widget _buildMaisonCard(Map<String, dynamic> maison) {
  final List<dynamic> images = maison['images'] ?? [];

  String? coverImage;
  String? videoUrl;

  // Parcourir les images pour trouver la première image ou vidéo disponible
  for (final img in images) {
    final Map<String, dynamic> imageMap = Map<String, dynamic>.from(img);
    
    // Récupérer l'image
    String? imagePath = imageMap['image']?.toString();
    if (imagePath != null && imagePath.isNotEmpty && coverImage == null) {
      coverImage = imagePath.startsWith('http')
          ? imagePath
          : 'https://akarina.shop$imagePath';
    }
    
    // Récupérer la vidéo
    String? videoPath = imageMap['video']?.toString();
    if (videoPath != null && videoPath.isNotEmpty && videoUrl == null) {
      videoUrl = videoPath.startsWith('http')
          ? videoPath
          : 'https://akarina.shop$videoPath';
    }
    
    // Si on a déjà les deux, on peut arrêter
    if (coverImage != null && videoUrl != null) break;
  }

  // Si aucune image n'a été trouvée, essayer de récupérer depuis les champs image_url ou video_url
  if (coverImage == null) {
    for (final img in images) {
      final Map<String, dynamic> imageMap = Map<String, dynamic>.from(img);
      if (imageMap['image_url'] != null && coverImage == null) {
        coverImage = imageMap['image_url'].toString();
      }
      if (imageMap['video_url'] != null && videoUrl == null) {
        videoUrl = imageMap['video_url'].toString();
      }
    }
  }

  final bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;
  
  // Nettoyer la description - prendre seulement les 2 premières lignes ou 60 caractères
  String description = maison['description'] ?? '';
  description = description.replaceAll('\r\n', ' ').replaceAll('\n', ' ');
  // Ne garder que les 40 premiers caractères pour éviter les descriptions trop longues
  if (description.length > 40) {
    description = description.substring(0, 40) + '...';
  }

  final double ratings = (maison['ratings'] ?? 0).toDouble();
  final double loyerMensuel = (maison['loyer_mensuel'] ?? 0).toDouble();
  final String periode = maison['periode'] ?? '';
  final bool avecServices = maison['avec_services'] ?? false;
  final bool meubler = maison['meubler'] ?? false;
  final String ville = maison['ville_nom'] ?? maison['ville'] ?? '';
  final String adresse = maison['adresse'] ?? '';
  final double surface = (maison['surface'] ?? 0).toDouble();

  // Déterminer le lieu à afficher
  String lieu = adresse.isNotEmpty ? adresse : ville;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _navigateToDetail(maison),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important pour éviter l'overflow
        children: [
          // ---- IMAGE ----
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverImage != null && coverImage.isNotEmpty)
                  Image.network(
                    coverImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),

                // Rating badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 11, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          ratings.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Play button for video
                if (hasVideo)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openVideo(videoUrl!),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.35),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.play_arrow_rounded, color: pcolor, size: 26),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---- INFOS AVEC HAUTEUR FIXE ----
          Container(
            height: 100, // Hauteur fixe pour le contenu des infos
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11, color: pcolor),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        lieu.isNotEmpty ? lieu : 'N/A',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Surface (si disponible)
                if (surface > 0) ...[
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(Icons.crop_square, size: 9, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        '${surface.toStringAsFixed(0)} m²',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Description - courte
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 2),
                
                // Price
                Row(
                  children: [
                    Text(
                      '${loyerMensuel.round()} MRU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pcolor,
                      ),
                    ),
                    if (periode.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Text(
                        '/ $periode',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
                
                // Chips
                if (avecServices || meubler) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      if (avecServices)
                        _buildInfoChip(
                          Icons.cleaning_services,
                          getTranslated(context, "Services")!,
                          Colors.blue[600]!,
                        ),
                      if (meubler)
                        _buildInfoChip(
                          Icons.weekend,
                          getTranslated(context, "Meublé")!,
                          Colors.orange[600]!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPlaceholder() {
  return Container(
    color: Colors.grey[200],
    child: Center(
      child: Icon(Icons.villa_outlined, size: 40, color: Colors.grey[400]),
    ),
  );
}

Widget _buildInfoChip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    constraints: const BoxConstraints(maxWidth: 55),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 1),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

}

// =========================================================
// Lecteur vidéo plein écran
// =========================================================
class _VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerPage({required this.videoUrl});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _hasError = true);
      });
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _hasError
            ? const Text(
                "Impossible de lire la vidéo",
                style: TextStyle(color: Colors.white),
              )
            : _initialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        _buildControlsOverlay(),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: pcolor,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: AnimatedOpacity(
        opacity: _controller.value.isPlaying ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.play_arrow, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}