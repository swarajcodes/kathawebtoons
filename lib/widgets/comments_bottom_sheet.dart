import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/comments_service.dart';
import '../models/comment_model.dart';
import 'comment_tile.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String comicId;
  final String episodeId;

  const CommentsBottomSheet({
    Key? key,
    required this.comicId,
    required this.episodeId,
  }) : super(key: key);

  @override
  _CommentsBottomSheetState createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final CommentsService _commentsService = CommentsService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;

  // Reply state management
  Comment? _replyingToComment;
  String _replyPlaceholder = 'Write a comment...';

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await _commentsService.postComment(
        comicId: widget.comicId,
        episodeId: widget.episodeId,
        content: _commentController.text.trim(),
        parentCommentId: _replyingToComment?.id, // Use reply parent if replying
      );

      _commentController.clear();
      _cancelReply(); // Clear reply state

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_replyingToComment != null ? 'Reply posted!' : 'Comment posted!'),
          backgroundColor: Color(0xFFA3D749),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToComment = comment;
      _replyPlaceholder = 'Reply to ${comment.username}...';
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
      _replyPlaceholder = 'Write a comment...';
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;
    final initialSize = keyboardOpen ? 0.8 : 0.5;

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag indicator
                  Container(
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Comments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.9)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Comments list with inline replies
                  Expanded(
                    child: StreamBuilder<List<Comment>>(
                      stream: _commentsService.getComments(
                        comicId: widget.comicId,
                        episodeId: widget.episodeId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3D749)),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                            left: 0,
                            right: 0,
                          ),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return InstagramCommentTile(
                              comment: snapshot.data![index],
                              comicId: widget.comicId,
                              episodeId: widget.episodeId,
                              onReply: _startReply,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Reply indicator (Instagram-style)
                  if (_replyingToComment != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.5),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            color: Color(0xFFA3D749),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingToComment!.username}',
                              style: TextStyle(
                                color: Color(0xFFA3D749),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelReply,
                            child: Icon(
                              Icons.close,
                              color: Colors.grey[500],
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Comment input (Instagram-style)
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 12 + (keyboardOpen ? 0 : MediaQuery.of(context).padding.bottom),
                    ),
                    margin: EdgeInsets.only(
                      bottom: keyboardOpen ? keyboardHeight : 0,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                            width: 1
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            constraints: BoxConstraints(maxHeight: 120),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _commentController,
                              focusNode: _focusNode,
                              style: TextStyle(color: Colors.white),
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: _replyPlaceholder,
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                border: InputBorder.none,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(
                                    color: Color(0xFFA3D749).withOpacity(0.8),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (text) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isPosting ? null : _postComment,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _commentController.text.trim().isNotEmpty
                                  ? Color(0xFFA3D749).withOpacity(0.9)
                                  : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: _isPosting
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                                : Icon(
                              Icons.send,
                              color: _commentController.text.trim().isNotEmpty
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.6),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
