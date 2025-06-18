import 'package:flutter/material.dart';
import '../../../models/episode_model.dart';
import '../episode_view_manager.dart';
import 'zoomable_image.dart';

class HorizontalEpisodeView extends StatelessWidget {
  final PageController controller;
  final Episode episode;
  final Function(int)? onPageChanged;
  final EpisodeViewManager viewManager;

  const HorizontalEpisodeView({
    Key? key,
    required this.controller,
    required this.episode,
    this.onPageChanged,
    required this.viewManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: episode.images.length,
      onPageChanged: (index) {
        // Don't reset zoom in horizontal mode - maintain document-level zoom
        onPageChanged?.call(index);
      },
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: ZoomableImage(
            imageUrl: episode.images[index],
            transformationController: viewManager.documentTransformationController,
            heroTag: "page_${episode.id}_$index",
          ),
        );
      },
    );
  }
}