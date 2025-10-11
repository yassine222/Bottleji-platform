import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? thumbnailUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.thumbnailUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎥 Initializing video player with URL: ${widget.videoUrl}');
      
      // Validate URL
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }
      
      // Check if URL is a data URI (base64) - not supported for video
      if (widget.videoUrl.startsWith('data:')) {
        throw Exception('Base64/Data URIs are not supported for video playback. Please upload a proper video file.');
      }
      
      Uri videoUri;
      try {
        videoUri = Uri.parse(widget.videoUrl);
        if (!videoUri.hasScheme || videoUri.host.isEmpty) {
          throw Exception('Invalid video URL format - missing scheme or host');
        }
        
        // Check for valid HTTP/HTTPS scheme
        if (videoUri.scheme != 'http' && videoUri.scheme != 'https') {
          throw Exception('Video URL must use HTTP or HTTPS protocol');
        }
      } catch (e) {
        throw Exception('Invalid video URL: $e');
      }
      
      debugPrint('✅ Parsed video URI: $videoUri');
      debugPrint('   Scheme: ${videoUri.scheme}');
      debugPrint('   Host: ${videoUri.host}');
      debugPrint('   Path: ${videoUri.path}');
      
      _videoPlayerController = VideoPlayerController.networkUrl(videoUri);

      await _videoPlayerController.initialize();
      
      debugPrint('✅ Video player initialized successfully');

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        autoInitialize: true,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: widget.thumbnailUrl != null
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to play video',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Video player error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to load video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}

