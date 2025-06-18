import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment_model.dart';
import '../services/comments_service.dart';
import 'package:kathawebtoons/theme/app_theme.dart';


class InstagramCommentTile extends StatefulWidget {
  final Comment comment;
  final String comicId;
  final String episodeId;
  final Function(Comment) onReply;

  const InstagramCommentTile({
    Key? key,
    required this.comment,
    required this.comicId,
    required this.episodeId,
    required this.onReply,
  }) : super(key: key);

  @override
  _InstagramCommentTileState createState() => _InstagramCommentTileState();
}

class _InstagramCommentTileState extends State<InstagramCommentTile> {
  final CommentsService _commentsService = CommentsService();
  bool _isLiked = false;
  bool _showReplies = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final isLiked = await _commentsService.hasUserLikedComment(
        comicId: widget.comicId,
        episodeId: widget.episodeId,
        commentId: widget.comment.id,
      );
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _commentsService.toggleCommentLike(
        comicId: widget.comicId,
        episodeId: widget.episodeId,
        commentId: widget.comment.id,
      );
      setState(() {
        _isLiked = !_isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                backgroundImage: widget.comment.userProfileImage.isNotEmpty
                    ? CachedNetworkImageProvider(
                        widget.comment.userProfileImage,
                        cacheKey: 'profile_${widget.comment.userProfileImage.hashCode}',
                      )
                    : null,
                child: widget.comment.userProfileImage.isEmpty
                    ? Icon(Icons.person, color: Colors.white54, size: 16)
                    : null,
              ),
              SizedBox(width: 12),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and comment text in one line (Instagram style)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: widget.comment.username,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: ' ${widget.comment.content}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),

                    // Action row (Instagram style)
                    Row(
                      children: [
                        // Timestamp
                        Text(
                          _formatTimestamp(widget.comment.timestamp),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),

                        if (widget.comment.likes > 0) ...[
                          SizedBox(width: 12),
                          Text(
                            '${widget.comment.likes} ${widget.comment.likes == 1 ? 'like' : 'likes'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => widget.onReply(widget.comment),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        if (widget.comment.isEdited) ...[
                          SizedBox(width: 12),
                          Text(
                            'edited',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // View replies button (Instagram style)
                    if (widget.comment.replies > 0) ...[
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showReplies = !_showReplies;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Text(
                              _showReplies
                                  ? 'Hide replies'
                                  : 'View ${widget.comment.replies} ${widget.comment.replies == 1 ? 'reply' : 'replies'}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Like button (Instagram style - on the right)
              GestureDetector(
                onTap: _isLoading ? null : _toggleLike,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: _isLoading
                      ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[500]!),
                    ),
                  )
                      : Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey[500],
                    size: 12,
                  ),
                ),
              ),
            ],
          ),

          // Replies section (Instagram style - indented)
          if (_showReplies && widget.comment.replies > 0)
            Padding(
              padding: EdgeInsets.only(left: 40, top: 8),
              child: StreamBuilder<List<Comment>>(
                stream: _commentsService.getReplies(
                  comicId: widget.comicId,
                  episodeId: widget.episodeId,
                  parentCommentId: widget.comment.id,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: 16,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3D749)),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((reply) {
                      return InstagramCommentTile(
                        comment: reply,
                        comicId: widget.comicId,
                        episodeId: widget.episodeId,
                        onReply: widget.onReply,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
