import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int replies;
  final bool isEdited;
  final String? parentCommentId;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.replies = 0,
    this.isEdited = false,
    this.parentCommentId,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImage: data['userProfileImage'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      replies: data['replies'] ?? 0,
      isEdited: data['isEdited'] ?? false,
      parentCommentId: data['parentCommentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'replies': replies,
      'isEdited': isEdited,
      'parentCommentId': parentCommentId,
    };
  }
}
