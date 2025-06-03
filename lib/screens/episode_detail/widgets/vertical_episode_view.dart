import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../../models/episode_model.dart';

class VerticalEpisodeView extends StatefulWidget {
  final ScrollController controller;
  final Episode episode;
  final Episode? nextEpisode;
  final bool isLastEpisode;
  final int currentPage;
  final VoidCallback onNextEpisodePressed;

  const VerticalEpisodeView({
    Key? key,
    required this.controller,
    required this.episode,
    required this.nextEpisode,
    required this.isLastEpisode,
    required this.currentPage,
    required this.onNextEpisodePressed,
  }) : super(key: key);

  @override
  _VerticalEpisodeViewState createState() => _VerticalEpisodeViewState();
}

class _VerticalEpisodeViewState extends State<VerticalEpisodeView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: widget.controller,
          itemCount: widget.episode.images.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.episode.images.length) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
              );
            }
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width,
              child: Hero(
                tag: "page_${widget.episode.id}_$index",
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(widget.episode.images[index]),
                  minScale: PhotoViewComputedScale.contained,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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