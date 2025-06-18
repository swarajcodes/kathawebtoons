import 'package:flutter/material.dart';
import '../models/episode_model.dart';
import '../services/reading_progress_service.dart';
import '../utils/image_optimization.dart';

class EpisodeListTile extends StatefulWidget {
  final Episode episode;
  final String comicId;
  final Function onTap;

  const EpisodeListTile({
    Key? key,
    required this.episode,
    required this.comicId,
    required this.onTap,
  }) : super(key: key);

  @override
  _EpisodeListTileState createState() => _EpisodeListTileState();
}

class _EpisodeListTileState extends State<EpisodeListTile> {
  final ReadingProgressService _progressService = ReadingProgressService();
  bool _isRead = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReadStatus();
  }

  Future<void> _checkReadStatus() async {
    final isRead = await _progressService.isEpisodeRead(
      widget.comicId,
      widget.episode.id,
    );

    if (mounted) {
      setState(() {
        _isRead = isRead;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color _accentColor = Color(0xFFA3D749);
    final Color _darkText = Color(0xFFE0E0E0);
    final String _fontFamily = 'Plus Jakarta Sans';

    return InkWell(
      onTap: () => widget.onTap(),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: _isRead ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
          child: Row(
            children: [
              // Episode thumbnail
              Stack(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: AspectRatio(
                        aspectRatio: 1.0, // Square aspect ratio
                        child: ImageOptimization.thumbnailImage(
                          imageUrl: widget.episode.previewImage.isNotEmpty
                              ? widget.episode.previewImage
                              : (widget.episode.images.isNotEmpty ? widget.episode.images.first : ''),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Read indicator
                  if (_isRead && !_isLoading)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),

              // Episode details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.episode.title,
                      style: TextStyle(
                        color: _darkText,
                        fontSize: 16,
                        fontWeight: _isRead ? FontWeight.normal : FontWeight.bold,
                        fontFamily: _fontFamily,
                      ),
                    ),
                    if (_isRead)
                      Text(
                        'Read',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 12,
                          fontFamily: _fontFamily,
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: _accentColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
