import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingProgress {
  final String userId;
  final String comicId;
  final String episodeId;
  final DateTime completedAt;
  final double readPercentage; // 0.0 to 1.0

  ReadingProgress({
    required this.userId,
    required this.comicId,
    required this.episodeId,
    required this.completedAt,
    this.readPercentage = 0.0, // Default to 0.0 instead of 1.0
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'comicId': comicId,
      'episodeId': episodeId,
      'completedAt': completedAt,
      'readPercentage': readPercentage.clamp(0.0, 1.0), // Ensure value is between 0 and 1
    };
  }

  factory ReadingProgress.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ReadingProgress(
      userId: data['userId'] ?? '',
      comicId: data['comicId'] ?? '',
      episodeId: data['episodeId'] ?? '',
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      readPercentage: (data['readPercentage'] ?? 0.0).clamp(0.0, 1.0), // Ensure value is between 0 and 1
    );
  }

  // Helper method to check if episode is considered read
  bool get isRead => readPercentage >= 0.8;

  // Helper method to get progress as percentage
  double get progressPercentage => readPercentage * 100;
}
