import 'package:flutter/material.dart';
import '../models/comic_model.dart';
import '../services/reading_progress_service.dart';
import '../utils/image_optimization.dart';

class ComicTile extends StatefulWidget {
  final Comic comic;
  final Function onTap;

  const ComicTile({
    Key? key,
    required this.comic,
    required this.onTap,
  }) : super(key: key);

  @override
  _ComicTileState createState() => _ComicTileState();
}

class _ComicTileState extends State<ComicTile> {
  final ReadingProgressService _progressService = ReadingProgressService();
  double _progress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.getComicProgress(
      widget.comic.id,
      0, // Let the service fetch the correct episode count
    );

    if (mounted) {
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(),
      child: Container(
        width: 120, // Fixed width for the comic tile
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Allow column to size to content
          children: [
            Stack(
              children: [
                // Comic cover with opacity based on reading progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 120, // Fixed width for the comic tile
                    height: 160, // Fixed height for consistency
                    child: ImageOptimization.coverImage(
                      imageUrl: widget.comic.coverImage,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Webnovel indicator
                if (widget.comic.isWebnovel || widget.comic.type == 'webnovel')
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: Color(0xFFA3D749),
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Webnovel',
                            style: TextStyle(
                              color: Color(0xFFA3D749),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Progress indicator (circular with percentage)
                if (_progress > 0 && !_isLoading)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55), // Dimmed background for contrast
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              value: _progress / 100,
                              strokeWidth: 3,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3D749)),
                            ),
                          ),
                          Text(
                            '${_progress.toInt()}%',
                            style: TextStyle(
                              color: Color(0xFFA3D749),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6), // Reduced spacing
            
            // Genre pills
            if (widget.comic.genre.isNotEmpty)
              Container(
                height: 20,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.comic.genre.length > 2 ? 2 : widget.comic.genre.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 4),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFA3D749).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Color(0xFFA3D749).withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        widget.comic.genre[index],
                        style: TextStyle(
                          color: Color(0xFFA3D749),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            
            SizedBox(height: 4),
            
            // Title with flexible space allocation
            Flexible(
              child: Text(
                widget.comic.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Ensure proper spacing between title and author
            SizedBox(height: 2),
            
            // Author text that starts after title
            Flexible(
              child: Text(
                widget.comic.author,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
