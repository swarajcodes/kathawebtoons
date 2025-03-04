import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comic_model.dart';
import '../models/episode_model.dart';

class EpisodeDetailScreen extends StatelessWidget {
  final Comic comic;
  final Episode episode;

  const EpisodeDetailScreen({
    Key? key,
    required this.comic,
    required this.episode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          episode.title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: episode.images.length , // +1 for the ad
        itemBuilder: (context, index) {
          // Insert ad after a few images
          // if (index == 3) {
          //   return Container(
          //     margin: const EdgeInsets.symmetric(vertical: 16),
          //     padding: const EdgeInsets.all(16),
          //     width: double.infinity,
          //     height: 100,
          //     color: Colors.grey.shade900,
          //     child: const Center(
          //       child: Text(
          //         'Advertisement',
          //         style: TextStyle(color: Colors.white),
          //       ),
          //     ),
          //   );
          // }

          final imageIndex = index > 3 ? index - 1 : index;
          if (imageIndex >= episode.images.length) return const SizedBox.shrink();

          return CachedNetworkImage(
            imageUrl: episode.images[imageIndex],
            placeholder: (context, url) => Container(
              height: MediaQuery.of(context).size.height / 2,
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFA3D749),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
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
            fit: BoxFit.fitWidth,
            width: double.infinity,
          );
        },
      ),
    );
  }
}