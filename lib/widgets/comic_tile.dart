import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comic_model.dart';
import '../services/reading_progress_service.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Comic cover with opacity based on reading progress
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120, // Fixed width for the comic tile
                  child: CachedNetworkImage(
                    imageUrl: widget.comic.coverImage,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: Icon(Icons.error, color: Colors.white),
                    ),
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
                      color: Colors.black.withOpacity(0.7),
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
                      color: Colors.black.withOpacity(0.55), // Dimmed background for contrast
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
          SizedBox(height: 8),
          Text(
            widget.comic.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            widget.comic.author,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
