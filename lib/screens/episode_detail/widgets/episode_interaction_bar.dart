import 'package:flutter/material.dart';
import '../../../models/episode_stats_model.dart';
import '../../../services/comments_service.dart';
import '../../../widgets/comments_bottom_sheet.dart';
import 'episode_interaction_button.dart';

class EpisodeInteractionBar extends StatefulWidget {
  final String comicId;
  final String episodeId;
  final bool isVisible;
  final VoidCallback onToggle;
  final Animation<Offset> animation;
  final bool isLiked;
  final Future<void> Function() onToggleLike;
  final VoidCallback showComments;

  const EpisodeInteractionBar({
    Key? key,
    required this.comicId,
    required this.episodeId,
    required this.isVisible,
    required this.onToggle,
    required this.animation,
    required this.isLiked,
    required this.onToggleLike,
    required this.showComments,
  }) : super(key: key);

  @override
  State<EpisodeInteractionBar> createState() => _EpisodeInteractionBarState();
}

class _EpisodeInteractionBarState extends State<EpisodeInteractionBar> {
  late bool _localIsLiked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the current value from the service
    _localIsLiked = widget.isLiked;
  }

  @override
  void didUpdateWidget(EpisodeInteractionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when the service state changes
    if (oldWidget.isLiked != widget.isLiked && !_isLoading) {
      setState(() {
        _localIsLiked = widget.isLiked;
      });
    }
  }

  void _handleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _localIsLiked = !_localIsLiked; // Optimistic update
    });

    try {
      await widget.onToggleLike();
    } catch (e) {
      // Revert on error
      setState(() {
        _localIsLiked = !_localIsLiked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).size.height * 0.3,
      bottom: MediaQuery.of(context).size.height * 0.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Interaction Panel
          SlideTransition(
            position: widget.animation,
            child: Container(
              width: 65,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    StreamBuilder<EpisodeStats?>(
                      stream: CommentsService().getEpisodeStats(
                        comicId: widget.comicId,
                        episodeId: widget.episodeId,
                      ),
                      builder: (context, snapshot) {
                        final likes = snapshot.data?.totalLikes ?? 0;
                        return EpisodeInteractionButton(
                          icon: _localIsLiked ? Icons.favorite : Icons.favorite_border,
                          color: _localIsLiked ? Colors.red : Colors.white,
                          countText: likes.toString(),
                          onTap: _handleLike,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<EpisodeStats?>(
                      stream: CommentsService().getEpisodeStats(
                        comicId: widget.comicId,
                        episodeId: widget.episodeId,
                      ),
                      builder: (context, snapshot) {
                        final comments = snapshot.data?.totalComments ?? 0;
                        return EpisodeInteractionButton(
                          icon: Icons.chat_bubble_outline,
                          color: Colors.white,
                          countText: comments.toString(),
                          onTap: widget.showComments,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    EpisodeInteractionButton(
                      icon: Icons.share,
                      color: Colors.white,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share functionality coming soon!'),
                            backgroundColor: Color(0xFFA3D749),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          // Toggle Button
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: 35,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                border: Border.all(
                  color: Color(0xFFA3D749),
                  width: 1,
                ),
              ),
              child: Center(
                child: AnimatedRotation(
                  turns: widget.isVisible ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
