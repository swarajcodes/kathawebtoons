import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../models/episode_stats_model.dart';

class CommentsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize episode stats if they don't exist
  Future<void> initializeEpisodeStats({
    required String comicId,
    required String episodeId,
  }) async {
    try {
      final statsRef = _firestore
          .collection('episodeStats')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId);

      final statsDoc = await statsRef.get();

      if (!statsDoc.exists) {
        final likesSnapshot = await _firestore
            .collection('likes')
            .doc(comicId)
            .collection('episodes')
            .doc(episodeId)
            .collection('likes')
            .get();

        final commentsSnapshot = await _firestore
            .collection('comments')
            .doc(comicId)
            .collection('episodes')
            .doc(episodeId)
            .collection('comments')
            .get();

        await statsRef.set({
          'totalLikes': likesSnapshot.docs.length,
          'totalComments': commentsSnapshot.docs.length,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        print('Initialized episode stats - Likes: ${likesSnapshot.docs.length}, Comments: ${commentsSnapshot.docs.length}');
      }
    } catch (e) {
      print('Error initializing episode stats: $e');
    }
  }

  // Post a new comment with proper stats update
  Future<void> postComment({
    required String comicId,
    required String episodeId,
    required String content,
    String? parentCommentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final comment = Comment(
      id: '',
      userId: user.uid,
      username: userData['username'] ?? 'Anonymous',
      userProfileImage: userData['profileImageUrl'] ?? '',
      content: content,
      timestamp: DateTime.now(),
      parentCommentId: parentCommentId,
    );

    final batch = _firestore.batch();

    final commentRef = _firestore
        .collection('comments')
        .doc(comicId)
        .collection('episodes')
        .doc(episodeId)
        .collection('comments')
        .doc();

    batch.set(commentRef, comment.toMap());

    final statsRef = _firestore
        .collection('episodeStats')
        .doc(comicId)
        .collection('episodes')
        .doc(episodeId);

    batch.set(statsRef, {
      'totalComments': FieldValue.increment(1),
      'lastActivity': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (parentCommentId != null) {
      final parentRef = _firestore
          .collection('comments')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('comments')
          .doc(parentCommentId);

      batch.update(parentRef, {
        'replies': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  // Fetch comments for an episode
  Stream<List<Comment>> getComments({
    required String comicId,
    required String episodeId,
  }) {
    return _firestore
        .collection('comments')
        .doc(comicId)
        .collection('episodes')
        .doc(episodeId)
        .collection('comments')
        .where('parentCommentId', isNull: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Comment.fromFirestore(doc))
        .toList());
  }

  // Fetch replies for a comment
  Stream<List<Comment>> getReplies({
    required String comicId,
    required String episodeId,
    required String parentCommentId,
  }) {
    return _firestore
        .collection('comments')
        .doc(comicId)
        .collection('episodes')
        .doc(episodeId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Comment.fromFirestore(doc))
        .toList());
  }

  // Like/unlike a comment
  Future<void> toggleCommentLike({
    required String comicId,
    required String episodeId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final likeDocId = 'comment_${commentId}_${user.uid}';
      final likeRef = _firestore
          .collection('likes')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('likes')
          .doc(likeDocId);

      final commentRef = _firestore
          .collection('comments')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('comments')
          .doc(commentId);

      final batch = _firestore.batch();
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        batch.delete(likeRef);
        batch.update(commentRef, {
          'likes': FieldValue.increment(-1),
        });
      } else {
        batch.set(likeRef, {
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'comment',
          'targetId': commentId,
        });
        batch.update(commentRef, {
          'likes': FieldValue.increment(1),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update comment like: $e');
    }
  }

  // Like/unlike an episode
  Future<void> toggleEpisodeLike({
    required String comicId,
    required String episodeId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final likeDocId = 'episode_${episodeId}_${user.uid}';
      final likeRef = _firestore
          .collection('likes')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('likes')
          .doc(likeDocId);

      final statsRef = _firestore
          .collection('episodeStats')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId);

      final batch = _firestore.batch();
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        batch.delete(likeRef);
        batch.set(statsRef, {
          'totalLikes': FieldValue.increment(-1),
          'lastActivity': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.set(likeRef, {
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'episode',
          'targetId': episodeId,
        });
        batch.set(statsRef, {
          'totalLikes': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update episode like: $e');
    }
  }

  // Check if user has liked comment
  Future<bool> hasUserLikedComment({
    required String comicId,
    required String episodeId,
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDocId = 'comment_${commentId}_${user.uid}';
      final likeDoc = await _firestore
          .collection('likes')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('likes')
          .doc(likeDocId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Check if user has liked episode
  Future<bool> hasUserLiked({
    required String comicId,
    required String episodeId,
    required String targetId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDocId = 'episode_${targetId}_${user.uid}';
      final likeDoc = await _firestore
          .collection('likes')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('likes')
          .doc(likeDocId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get episode stats
  Stream<EpisodeStats?> getEpisodeStats({
    required String comicId,
    required String episodeId,
  }) {
    return _firestore
        .collection('episodeStats')
        .doc(comicId)
        .collection('episodes')
        .doc(episodeId)
        .snapshots()
        .asyncMap((doc) async {
      try {
        if (doc.exists && doc.data() != null) {
          return EpisodeStats.fromFirestore(doc);
        } else {
          await initializeEpisodeStats(
            comicId: comicId,
            episodeId: episodeId,
          );

          final newDoc = await _firestore
              .collection('episodeStats')
              .doc(comicId)
              .collection('episodes')
              .doc(episodeId)
              .get();

          if (newDoc.exists) {
            return EpisodeStats.fromFirestore(newDoc);
          } else {
            return EpisodeStats(
              episodeId: episodeId,
              totalLikes: 0,
              totalComments: 0,
              lastActivity: DateTime.now(),
            );
          }
        }
      } catch (e) {
        return EpisodeStats(
          episodeId: episodeId,
          totalLikes: 0,
          totalComments: 0,
          lastActivity: DateTime.now(),
        );
      }
    });
  }

  // Recalculate episode stats
  Future<void> recalculateEpisodeStats({
    required String comicId,
    required String episodeId,
  }) async {
    try {
      final likesSnapshot = await _firestore
          .collection('likes')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('likes')
          .get();

      final commentsSnapshot = await _firestore
          .collection('comments')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId)
          .collection('comments')
          .get();

      final statsRef = _firestore
          .collection('episodeStats')
          .doc(comicId)
          .collection('episodes')
          .doc(episodeId);

      await statsRef.set({
        'totalLikes': likesSnapshot.docs.length,
        'totalComments': commentsSnapshot.docs.length,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error recalculating episode stats: $e');
    }
  }
}
