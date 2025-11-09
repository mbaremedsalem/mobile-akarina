import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasError = false;
  bool _isDisposed = false;
  bool _useFallback = false; // Nouveau: utiliser le fallback WebView

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasError = false;
        _useFallback = false;
      });

      await _disposeControllers();

      String videoUrl = widget.videoUrl;
      
      print('🔄 Initialisation vidéo avec URL: $videoUrl');

      if (videoUrl.isEmpty) {
        throw Exception('URL vidéo vide');
      }

      if (videoUrl.startsWith('/')) {
        videoUrl = 'https://akarina.shop$videoUrl';
        print('🔧 URL corrigée: $videoUrl');
      }

      // SOLUTION: Essayer plusieurs méthodes pour contourner l'erreur serveur
      _videoPlayerController = VideoPlayerController.network(
        videoUrl,
        httpHeaders: _getVideoHeaders(),
      );
      
      _videoPlayerController!.addListener(_videoListener);

      await _videoPlayerController!.initialize().timeout(
        Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Timeout d\'initialisation (20s)');
        },
      );

      if (!mounted || _isDisposed) return;

      if (!_videoPlayerController!.value.isInitialized) {
        throw Exception('Contrôleur vidéo non initialisé');
      }

      _setupChewieController();

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }

      print('🎬 Lecteur vidéo prêt');

    } catch (e) {
      print('💥 Erreur d\'initialisation: $e');
      if (mounted && !_isDisposed) {
        // Automatiquement basculer vers le fallback WebView
        _switchToWebViewFallback();
      }
    }
  }

  Map<String, String> _getVideoHeaders() {
    return {
      'Accept': '*/*',
      'Range': 'bytes=0-',
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    };
  }

  void _videoListener() {
    if (!mounted || _isDisposed) return;
    
    final value = _videoPlayerController!.value;
    
    if (value.isInitialized && _isLoading) {
      print('✅ Vidéo initialisée - Durée: ${value.duration}');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    if (value.hasError) {
      print('❌ Erreur vidéo détectée: ${value.errorDescription}');
      if (mounted && !_isDisposed) {
        _switchToWebViewFallback();
      }
    }
  }

  void _setupChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey[300]!,
      ),
      errorBuilder: (context, errorMessage) {
        return _buildErrorWidget(errorMessage);
      },
      allowedScreenSleep: false,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      cupertinoProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey[300]!,
      ),
      placeholder: Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  // NOUVELLE MÉTHODE: Fallback WebView pour contourner l'erreur serveur
  void _switchToWebViewFallback() {
    print('🔄 Basculement vers WebView fallback');
    
    if (!mounted || _isDisposed) return;

    // Nettoyer les contrôleurs vidéo
    _disposeControllers().then((_) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _useFallback = true;
          _errorMessage = 'Utilisation du lecteur de secours';
        });
      }
    });
  }

  Future<void> _disposeControllers() async {
    try {
       _chewieController?.dispose();
      _chewieController = null;
      
      await _videoPlayerController?.dispose();
      _videoPlayerController = null;
    } catch (e) {
      print('⚠️ Erreur lors du nettoyage: $e');
    }
  }

  void _handleError(String error) {
    if (!mounted || _isDisposed) return;
    
    setState(() {
      _isLoading = false;
      _errorMessage = _parseErrorMessage(error);
      _hasError = true;
    });
  }

  String _parseErrorMessage(String error) {
    if (error.contains('byte range') || error.contains('12939')) {
      return 'Problème de configuration du serveur vidéo\n(Erreur iOS -12939)';
    } else if (error.contains('timeout')) {
      return 'Temps de chargement trop long';
    } else if (error.contains('404') || error.contains('not found')) {
      return 'Vidéo non trouvée sur le serveur';
    } else if (error.contains('network') || error.contains('socket')) {
      return 'Problème de connexion réseau';
    } else if (error.contains('format') || error.contains('codec')) {
      return 'Format vidéo MP4 non supporté par iOS';
    } else {
      return 'Impossible de lire la vidéo';
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 50),
            SizedBox(height: 16),
            Text(
              'Erreur de lecture vidéo',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _parseErrorMessage(errorMessage),
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryVideo,
                  icon: Icon(Icons.refresh),
                  label: Text('Réessayer la lecture native'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _switchToWebViewFallback,
                  icon: Icon(Icons.web),
                  label: Text('Utiliser le lecteur de secours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                  label: Text('Fermer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Conseil: Contactez votre administrateur pour configurer correctement le serveur vidéo (support byte-range requests)',
                style: TextStyle(color: Colors.orange, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryVideo() {
    print('🔄 Nouvelle tentative de lecture native...');
    _initializeVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu principal
            if (_isLoading)
              _buildLoadingWidget()
            else if (_hasError)
              _buildErrorWidget(_errorMessage)
            else if (_useFallback)
              _buildWebViewFallback()
            else
              _buildVideoPlayer(),
            
            // Bouton fermer
            if (!_isLoading)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Chargement de la vidéo...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 10),
          if (_useFallback)
            Text(
              'Lecture via navigateur de secours',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            )
          else
            Text(
              'Lecture native',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return _buildErrorWidget('Contrôleur vidéo non disponible');
    }
    
    return Center(
      child: Chewie(controller: _chewieController!),
    );
  }

  // NOUVEAU: Widget WebView fallback
  Widget _buildWebViewFallback() {
    String videoUrl = widget.videoUrl;
    if (videoUrl.startsWith('/')) {
      videoUrl = 'https://akarina.shop$videoUrl';
    }

    // Créer une page HTML simple pour lire la vidéo
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            background: black;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
          }
          video { 
            width: 100%; 
            height: auto;
            max-height: 100vh;
          }
        </style>
      </head>
      <body>
        <video controls autoplay>
          <source src="$videoUrl" type="video/mp4">
          Votre navigateur ne supporte pas la lecture vidéo.
        </video>
      </body>
      </html>
    ''';

    return WebViewWidget(
      controller: _webViewController ??= WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(htmlContent)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (String url) {
            print('✅ WebView fallback chargé');
          },
        )),
    );
  }

  @override
  void dispose() {
    print('🧹 Nettoyage du lecteur vidéo');
    _isDisposed = true;
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }
}