import 'package:flutter/material.dart';
import '../../../models/episode_model.dart';
import '../episode_view_manager.dart';
import 'zoomable_image.dart';

class LazyEpisodeView extends StatefulWidget {
  final PageController controller;
  final Episode episode;
  final Function(int)? onPageChanged;
  final EpisodeViewManager viewManager;
  final Set<String> preloadedImages;

  const LazyEpisodeView({
    Key? key,
    required this.controller,
    required this.episode,
    this.onPageChanged,
    required this.viewManager,
    required this.preloadedImages,
  }) : super(key: key);

  @override
  State<LazyEpisodeView> createState() => _LazyEpisodeViewState();
}

class _LazyEpisodeViewState extends State<LazyEpisodeView> {
  Set<int> _visiblePages = {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Initially mark first page as visible
    _visiblePages.add(0);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      itemCount: widget.episode.images.length,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
          // Mark current and adjacent pages as visible
          _visiblePages.add(index);
          if (index > 0) _visiblePages.add(index - 1);
          if (index < widget.episode.images.length - 1) _visiblePages.add(index + 1);
        });
        widget.onPageChanged?.call(index);
      },
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        final imageUrl = widget.episode.images[index];
        final isVisible = _visiblePages.contains(index);
        final isPreloaded = widget.preloadedImages.contains(imageUrl);
        
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: isVisible || isPreloaded
              ? ZoomableImage(
                  imageUrl: imageUrl,
                  transformationController: widget.viewManager.documentTransformationController,
                  heroTag: "page_${widget.episode.id}_$index",
                )
              : _buildPlaceholder(index),
        );
      },
    );
  }

  Widget _buildPlaceholder(int index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              color: Colors.grey[600],
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Page ${index + 1}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 