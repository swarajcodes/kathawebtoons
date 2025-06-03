import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../../models/episode_model.dart';

class HorizontalEpisodeView extends StatelessWidget {
  final PageController controller;
  final Episode episode;
  final Function(int)? onPageChanged;

  const HorizontalEpisodeView({
    Key? key,
    required this.controller,
    required this.episode,
    this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: episode.images.length,
      onPageChanged: onPageChanged,
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Hero(
          tag: "page_${episode.id}_$index",
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(episode.images[index]),
            minScale: PhotoViewComputedScale.covered * 0.8,
            maxScale: PhotoViewComputedScale.covered * 4,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.lightGreenAccent,
                ),
              ),
            ),
            tightMode: true,
            gaplessPlayback: true,
            enableRotation: false,
            filterQuality: FilterQuality.high,
            gestureDetectorBehavior: HitTestBehavior.opaque,
            basePosition: Alignment.center,
          ),
        );
      },
    );
  }
}