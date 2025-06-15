import 'package:flutter/material.dart';
import '../../../models/episode_model.dart';
import '../episode_view_manager.dart';
import 'zoomable_image.dart';

class VerticalEpisodeView extends StatefulWidget {
  final ScrollController controller;
  final Episode episode;
  final Episode? nextEpisode;
  final bool isLastEpisode;
  final int currentPage;
  final VoidCallback onNextEpisodePressed;
  final EpisodeViewManager viewManager;

  const VerticalEpisodeView({
    Key? key,
    required this.controller,
    required this.episode,
    required this.nextEpisode,
    required this.isLastEpisode,
    required this.currentPage,
    required this.onNextEpisodePressed,
    required this.viewManager,
  }) : super(key: key);

  @override
  State<VerticalEpisodeView> createState() => _VerticalEpisodeViewState();
}

class _VerticalEpisodeViewState extends State<VerticalEpisodeView> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        ListView.builder(
          controller: widget.controller,
          itemCount: widget.episode.images.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.episode.images.length) {
              return SizedBox(
                height: screenHeight * 0.3,
                width: screenWidth,
              );
            }

            return Container(
              // Remove fixed height to let image determine its size
              width: screenWidth,
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: AspectRatio(
                aspectRatio: 3/4, // Typical comic page ratio, adjust as needed
                child: ZoomableImage(
                  imageUrl: widget.episode.images[index],
                  transformationController: widget.viewManager.getTransformationController(index),
                  heroTag: "page_${widget.episode.id}_$index",
                ),
              ),
            );
          },
        ),
        if (widget.nextEpisode != null && !widget.isLastEpisode && widget.currentPage == widget.episode.images.length - 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: widget.onNextEpisodePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA3D749),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next Chapter',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
