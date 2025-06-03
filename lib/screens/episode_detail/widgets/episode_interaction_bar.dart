import 'package:flutter/material.dart';
import '../../../models/episode_stats_model.dart';
import '../../../services/comments_service.dart';
import '../../../widgets/comments_bottom_sheet.dart';
import 'episode_interaction_button.dart';

class EpisodeInteractionBar extends StatelessWidget {
  final String comicId;
  final String episodeId;
  final bool isVisible;
  final VoidCallback onToggle;
  final Animation<Offset> animation;
  final bool isLiked;
  final VoidCallback onToggleLike;
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
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).size.height * 0.3,
      bottom: MediaQuery.of(context).size.height * 0.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Only show the panel when it's visible
          if (isVisible)
            SlideTransition(
              position: animation,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Container(
                  width: 65,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        StreamBuilder<EpisodeStats?>(
                          stream: CommentsService().getEpisodeStats(
                            comicId: comicId,
                            episodeId: episodeId,
                          ),
                          builder: (context, snapshot) {
                            final likes = snapshot.data?.totalLikes ?? 0;
                            return EpisodeInteractionButton(
                              icon: isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              countText: likes.toString(),
                              onTap: onToggleLike,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<EpisodeStats?>(
                          stream: CommentsService().getEpisodeStats(
                            comicId: comicId,
                            episodeId: episodeId,
                          ),
                          builder: (context, snapshot) {
                            final comments = snapshot.data?.totalComments ?? 0;
                            return EpisodeInteractionButton(
                              icon: Icons.chat_bubble_outline,
                              color: Colors.white,
                              countText: comments.toString(),
                              onTap: showComments,
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
            ),
          // Always show the toggle button
          GestureDetector(
            onTap: onToggle,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Container(
                width: 35,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: isVisible ? 0.5 : 0.0,
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
          ),
        ],
      ),
    );
  }
}