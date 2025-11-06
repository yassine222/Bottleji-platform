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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎥 Initializing video: ${widget.videoUrl}');
      
      // Validate URL
      if (widget.videoUrl.isEmpty || widget.videoUrl.startsWith('data:')) {
        setState(() {
          _errorMessage = 'Invalid video URL';
        });
        return;
      }

      final uri = Uri.parse(widget.videoUrl);
      
      // Create controller
      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      
      // Initialize with timeout
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video loading timeout - please check your internet connection');
        },
      );

      if (!mounted) return;

      // Create Chewie controller after successful initialization
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00695C),
          handleColor: const Color(0xFF00695C),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
        placeholder: widget.thumbnailUrl != null && !widget.thumbnailUrl!.startsWith('data:')
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black,
                  child: const Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
                ),
              )
            : Container(
                color: Colors.black,
                child: const Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
              ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text('Unable to play video', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ Video player ready');
    } catch (e) {
      debugPrint('❌ Video error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text('Unable to load video', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : !_isInitialized
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildVideoContainer(
                        context,
                        const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00695C)),
                        ),
                      ),
                    )
                  : _chewieController != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: _buildVideoContainer(
                            context,
                            AspectRatio(
                              aspectRatio: _videoPlayerController?.value.isInitialized == true
                                  ? _videoPlayerController!.value.aspectRatio
                                  : 16 / 9,
                              child: Chewie(controller: _chewieController!),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildVideoContainer(BuildContext context, Widget child) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF101010),
            Color(0xFF050505),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.black,
            child: child,
          ),
        ),
      ),
    );
  }
}

