import 'package:cloud_firestore/cloud_firestore.dart';

class EpisodeStats {
  final String episodeId;
  final int totalLikes;
  final int totalComments;
  final DateTime lastActivity;

  EpisodeStats({
    required this.episodeId,
    required this.totalLikes,
    required this.totalComments,
    required this.lastActivity,
  });

  factory EpisodeStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EpisodeStats(
      episodeId: doc.id,
      totalLikes: data['totalLikes'] ?? 0,
      totalComments: data['totalComments'] ?? 0,
      lastActivity: data['lastActivity'] != null
          ? (data['lastActivity'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'lastActivity': Timestamp.fromDate(lastActivity),
    };
  }
}
