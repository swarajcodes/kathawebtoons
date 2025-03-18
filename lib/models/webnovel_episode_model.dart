import 'package:cloud_firestore/cloud_firestore.dart';

class WebnovelEpisode {
  final String id;
  final String title;
  final int number;
  final String content; // Text content of the episode

  WebnovelEpisode({
    required this.id,
    required this.title,
    required this.number,
    required this.content,
  });

  factory WebnovelEpisode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WebnovelEpisode(
      id: doc.id,
      title: data['title'] ?? '',
      number: data['number'] ?? 0,
      content: data['content'] ?? '',
    );
  }
}