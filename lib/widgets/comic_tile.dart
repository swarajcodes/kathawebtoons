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
      0,
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
        width: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover Image with Stack
            SizedBox(
              width: 120,
              height: 160,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImageOptimization.coverImage(
                      imageUrl: widget.comic.coverImage,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (widget.comic.isWebnovel || widget.comic.type == 'webnovel')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book,
                              color: Color(0xFFA3D749),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Webnovel',
                              style: TextStyle(
                                color: const Color(0xFFA3D749),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_progress > 0 && !_isLoading)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
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
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFA3D749)),
                              ),
                            ),
                            Text(
                              '${_progress.toInt()}%',
                              style: TextStyle(
                                color: const Color(0xFFA3D749),
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
            ),

            const SizedBox(height: 8),

            // Genre chips
            if (widget.comic.genre.isNotEmpty)
              SizedBox(
                height: 20,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.comic.genre.length > 2 ? 2 : widget.comic.genre.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA3D749).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFA3D749).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        widget.comic.genre[index],
                        style: TextStyle(
                          color: const Color(0xFFA3D749),
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 6),

            // Title and Author with Flexible to prevent overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.comic.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
            )
          ],
        ),
      ),
    );
  }
}
