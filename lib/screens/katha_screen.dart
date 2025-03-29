import 'dart:async'; // Add this import for Completer
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class KathaScreen extends StatefulWidget {
  @override
  _KathaScreenState createState() => _KathaScreenState();
}

class _KathaScreenState extends State<KathaScreen> {
  final List<MediaItem> mediaItems = [
    MediaItem(type: MediaType.image, path: 'assets/Page1.png'),
    MediaItem(type: MediaType.video, path: 'assets/Page2.mp4'),
    MediaItem(type: MediaType.image, path: 'assets/Page3.png'),
    MediaItem(type: MediaType.video, path: 'assets/Page4.mp4'),
    MediaItem(type: MediaType.image, path: 'assets/Page5.png'),
  ];

  late PageController _pageController;
  late List<VideoPlayerController?> _videoControllers;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _videoControllers = List.filled(mediaItems.length, null);
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    for (int i = 0; i < mediaItems.length; i++) {
      if (mediaItems[i].type == MediaType.video) {
        _videoControllers[i] = VideoPlayerController.asset(mediaItems[i].path);
        try {
          await _videoControllers[i]!.initialize();
          if (i == 0) _videoControllers[i]!.play();
        } catch (e) {
          print('Error initializing video: $e');
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  Widget _buildImageContent(String path) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              width: constraints.maxWidth,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoContent(int index) {
    if (_videoControllers[index] == null ||
        !_videoControllers[index]!.value.isInitialized) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return AspectRatio(
      aspectRatio: _videoControllers[index]!.value.aspectRatio,
      child: VideoPlayer(_videoControllers[index]!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const ClampingScrollPhysics(),
        itemCount: mediaItems.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          for (int i = 0; i < _videoControllers.length; i++) {
            if (i != index && _videoControllers[i] != null) {
              _videoControllers[i]!.pause();
            }
          }
          if (mediaItems[index].type == MediaType.video) {
            _videoControllers[index]!.play();
          }
        },
        itemBuilder: (context, index) {
          return Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Main content
                mediaItems[index].type == MediaType.image
                    ? _buildImageContent(mediaItems[index].path)
                    : _buildVideoContent(index),

                // Page indicator
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(mediaItems.length, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String path;

  MediaItem({
    required this.type,
    required this.path,
  });
}