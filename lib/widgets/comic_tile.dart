import 'package:flutter/material.dart';
import '../models/comic_model.dart';

class ComicTile extends StatelessWidget {
  final Comic comic;
  final VoidCallback onTap;

  const ComicTile({required this.comic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 0), // Reduced margin
        width: 120, // Fixed width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum size
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                comic.coverImage,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 5),
            Container(
              width: 120, // Match image width
              child: Text(
                comic.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14, // Slightly smaller font
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2), // Smaller space
            Text(
              comic.author,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12, // Smaller font
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}