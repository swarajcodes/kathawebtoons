import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/comic_model.dart';
import '../models/episode_model.dart';

class EpisodeDetailScreen extends StatefulWidget {
  final Comic comic;
  final Episode episode;

  const EpisodeDetailScreen({
    Key? key,
    required this.comic,
    required this.episode,
  }) : super(key: key);

  @override
  _EpisodeDetailScreenState createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> {
  bool isHorizontalMode = false;
  late PageController _horizontalPageController;
  late ScrollController _verticalScrollController;
  int _currentPage = 0;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _horizontalPageController = PageController();
    _verticalScrollController = ScrollController();

    // Add listeners for page changes
    _horizontalPageController.addListener(() {
      if (_horizontalPageController.hasClients && isHorizontalMode) {
        final page = _horizontalPageController.page?.round() ?? 0;
        if (page != _currentPage) {
          setState(() {
            _currentPage = page;
          });
        }
      }
    });

    _verticalScrollController.addListener(() {
      if (_verticalScrollController.hasClients && !isHorizontalMode) {
        if (_verticalScrollController.position.maxScrollExtent > 0) {
          setState(() {
            _scrollProgress = _verticalScrollController.offset / _verticalScrollController.position.maxScrollExtent;
            // Approximate current page based on scroll progress
            _currentPage = (_scrollProgress * (widget.episode.images.length - 1)).round();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _horizontalPageController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.episode.title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          isHorizontalMode
              ? _buildHorizontalView()
              : _buildVerticalView(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20, // Raised above the bottom edge
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Page counter
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      "${_currentPage + 1}/${widget.episode.images.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Scroll progress bar
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: Colors.lightGreenAccent,
                          inactiveTrackColor: Colors.grey.shade600,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: isHorizontalMode
                              ? _currentPage.toDouble()
                              : _scrollProgress * (widget.episode.images.length - 1),
                          min: 0,
                          max: (widget.episode.images.length - 1).toDouble(),
                          divisions: widget.episode.images.length > 1 ? widget.episode.images.length - 1 : 1,
                          onChanged: (value) {
                            if (isHorizontalMode) {
                              final page = value.toInt();
                              setState(() {
                                _currentPage = page;
                              });
                              _horizontalPageController.jumpToPage(page);
                            } else {
                              // For vertical mode, calculate position based on progress
                              if (_verticalScrollController.hasClients) {
                                final targetPosition = (value / (widget.episode.images.length - 1)) *
                                    _verticalScrollController.position.maxScrollExtent;
                                _verticalScrollController.jumpTo(targetPosition);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // View mode toggle
                  IconButton(
                    icon: Icon(
                      isHorizontalMode ? Icons.view_day : Icons.view_carousel,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isHorizontalMode = !isHorizontalMode;
                      });

                      // Handle mode switch with proper position
                      if (isHorizontalMode) {
                        // Switching to horizontal: set page based on scroll progress
                        Future.delayed(Duration.zero, () {
                          if (_horizontalPageController.hasClients) {
                            _horizontalPageController.jumpToPage(_currentPage);
                          }
                        });
                      }
                      // When switching to vertical, we let the controller handle it naturally
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalView() {
    return ListView.builder(
      controller: _verticalScrollController,
      itemCount: widget.episode.images.length,
      itemBuilder: (context, index) {
        return PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.episode.images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => Container(
            height: MediaQuery.of(context).size.height / 2,
            color: Colors.grey.shade900,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.lightGreenAccent,
              ),
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Container(
            height: MediaQuery.of(context).size.height / 2,
            color: Colors.grey.shade900,
            child: const Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
            ),
          ),
          tightMode: true, // Ensures the view doesn't zoom too far out
          customSize: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
          gaplessPlayback: true,
          enableRotation: false,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }

  Widget _buildHorizontalView() {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      itemCount: widget.episode.images.length,
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.episode.images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          tightMode: true, // Prevents excessive zooming out
          heroAttributes: PhotoViewHeroAttributes(tag: "horizontal_${widget.episode.images[index]}"),
        );
      },
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      pageController: _horizontalPageController,
      onPageChanged: (index) {
        if (isHorizontalMode) {
          setState(() {
            _currentPage = index;
          });
        }
      },
      loadingBuilder: (context, event) => Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.lightGreenAccent,
          ),
        ),
      ),
    );
  }
}