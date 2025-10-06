import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasError = false;
      });

      // Ensure URL is absolute
      String videoUrl = widget.videoUrl;
      if (videoUrl.startsWith('/')) {
        videoUrl = 'https://akarina.online$videoUrl';
      }

      
      // Add retry logic and timeout
      _videoPlayerController = VideoPlayerController.network(
        videoUrl,
      );

      // Set up error listener
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          _handleError(_videoPlayerController.value.errorDescription ?? 'Unknown error');
        }
      });

      // Initialize with timeout
      await _videoPlayerController.initialize().timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );

      // Check if controller is still valid after initialization
      if (!_videoPlayerController.value.isInitialized) {
        throw Exception('Video controller not initialized');
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        // Improved error builder
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
        // Additional configuration for better compatibility
        allowedScreenSleep: false,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() {
      _isLoading = false;
      _errorMessage = error;
      _hasError = true;
    });
    
    // Dispose controllers on error to prevent memory leaks
    _chewieController?.dispose();
    _videoPlayerController.dispose();
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.white, size: 50),
            SizedBox(height: 16),
            Text(
              'Impossible de lire la vidéo',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            if (errorMessage.contains('byte range') || 
                errorMessage.contains('12939'))
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Problème de configuration du serveur',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryVideo,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryVideo() {
    _initializeVideo();
  }

  // Alternative method: Try with different approach
  void _tryAlternativePlayback() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Try a different approach - preload entire video
      final response = await HttpClient().getUrl(Uri.parse(widget.videoUrl));
      final httpResponse = await response.close();
      
      // If we can get the response, the issue is with byte-range requests
      if (httpResponse.statusCode == 200) {
        setState(() {
          _errorMessage = 'Server configuration issue: Byte-range requests not supported';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(height: 16),
              Text(
                'Chargement de la vidéo...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            _buildErrorWidget(_errorMessage),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }
}