import 'package:flutter/material.dart';
import '../models/comic_model.dart';

/// A widget that displays a comic/webtoon/webnovel item in a grid or list
/// Shows the cover image, title, and author name
class ComicTile extends StatelessWidget {
  /// The comic data to display
  final Comic comic;
  
  /// Callback function when the tile is tapped
  final VoidCallback onTap;

  const ComicTile({
    Key? key,
    required this.comic,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image container with rounded corners
            Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[900],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  comic.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            // Spacing between image and text
            SizedBox(height: 4),
            // Text container with title and author
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comic title with ellipsis for overflow
                  Flexible(
                    child: Text(
                      comic.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Small spacing between title and author
                  SizedBox(height: 2),
                  // Author name with ellipsis for overflow
                  Text(
                    comic.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}