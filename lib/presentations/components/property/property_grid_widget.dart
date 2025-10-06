import 'package:flutter/material.dart';
import 'package:akarina/presentations/screens/immobillier/immob_details.dart';
import 'package:akarina/presentations/screens/home/video_player.dart';

class PropertyGridWidget extends StatelessWidget {
  final List<dynamic> properties;
  final bool isSearch;
  final bool isLoading;

  const PropertyGridWidget({
    super.key,
    required this.properties,
    required this.isSearch,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (properties.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildPropertyCard(property, context);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune propriété trouvée",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Essayez de modifier vos critères de recherche",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(dynamic property, BuildContext context) {
    final mediaUrl = _resolveImageUrl(property['images']);
    final isTerrain = property['terrain'] != null;
    final isResidentiel = property['residentiel'] != null;
    final operationType = property['operation']['type'];
    final ville = property['ville']['nom'];
    final ratings = property['ratings'] ?? '0.0';
    final adresse = property['adresse'] ?? '';
    final montant = isTerrain ? property['terrain']['montant']?.toString() : null;
    final loyerMensuel = isResidentiel ? property['residentiel']['loyer_mensuel']?.toString() : null;
    final periode = isResidentiel ? property['residentiel']['periode'] : null;
    final isVideo = _isVideo(mediaUrl);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Media section
          GestureDetector(
            onTap: () => _onMediaTap(context, property, mediaUrl, isVideo),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: !isVideo ? DecorationImage(
                  image: NetworkImage(mediaUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.home, color: Colors.grey),
                  ),
                ) : null,
                color: isVideo ? Colors.black54 : null,
              ),
              child: Stack(
                children: [
                  if (isVideo)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  
                  if (isVideo)
                    const Center(
                      child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
                    )
                  else if (mediaUrl.contains('encrypted-tbn0'))
                    const Center(
                      child: Icon(Icons.home, size: 40, color: Colors.grey),
                    ),
                  
                  // Badge d'opération
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: operationType == 'vendre' 
                            ? Colors.red.withOpacity(0.8)
                            : Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        operationType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (isVideo)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIDÉO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Info section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    adresse,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ville,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  Text(
                    loyerMensuel != null
                        ? '$loyerMensuel MRU/mois'
                        : '${montant ?? 'N/A'} MRU',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  Row(
                    children: [
                      ...List.generate(5, (starIndex) => Icon(
                        Icons.star,
                        size: 14,
                        color: starIndex < (double.tryParse(ratings) ?? 0).floor()
                            ? Colors.amber
                            : Colors.grey[300],
                      )),
                      const SizedBox(width: 4),
                      Text(
                        ratings,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMediaTap(BuildContext context, dynamic property, String mediaUrl, bool isVideo) {
    if (isVideo) {
      _openVideo(context, mediaUrl);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImmobDetails(id: property['id']),
        ),
      );
    }
  }

  void _openVideo(BuildContext context, String videoUrl) {
    String fullVideoUrl = videoUrl;
    if (videoUrl.startsWith('/')) {
      fullVideoUrl = 'https://akarina.online$videoUrl';
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          child: VideoPlayerWidget(videoUrl: fullVideoUrl),
        ),
      ),
    );
  }

  bool _isVideo(String url) {
    if (url.isEmpty) return false;
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.wmv', '.flv', '.mkv'];
    final videoPaths = ['/videos/', '/media/videos/', 'video', 'mp4'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext)) ||
           videoPaths.any((path) => lowerUrl.contains(path));
  }

  String _resolveImageUrl(dynamic images) {
    if (images != null && images.isNotEmpty) {
      if (images[0]['image'] != null && images[0]['image'].toString().isNotEmpty) {
        return images[0]['image'];
      } else if (images[0]['video'] != null && images[0]['video'].toString().isNotEmpty) {
        return images[0]['video'];
      }
    }
    return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpM79j6U5ty6oOTpYRbTu1Fli6maxXHWOnZw&s';
  }
}