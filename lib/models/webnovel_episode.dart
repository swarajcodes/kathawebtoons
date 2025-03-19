import 'package:cloud_firestore/cloud_firestore.dart';

class WebnovelEpisode {
  final String id;
  final String title;
  final int number;
  final String docxUrl; // URL to the .docx file

  WebnovelEpisode({
    required this.id,
    required this.title,
    required this.number,
    required this.docxUrl,
  });

  factory WebnovelEpisode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WebnovelEpisode(
      id: doc.id,
      title: data['title'] ?? '',
      number: data['number'] ?? 0,
      docxUrl: data['docxUrl'] ?? '', // URL to the .docx file
    );
  }
}