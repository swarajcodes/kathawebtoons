import 'package:flutter/material.dart';
import '../models/comic_model.dart';
import '../utils/image_optimization.dart';

class ComicHeader extends StatelessWidget {
  final Comic comic;

  const ComicHeader({Key? key, required this.comic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero landscape image
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ImageOptimization.heroImage(
            imageUrl: comic.heroLandscapeImage,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay - lighter to match the image
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.4, 1.0], // Start gradient lower down
            ),
          ),
        ),
      ],
    );
  }
}