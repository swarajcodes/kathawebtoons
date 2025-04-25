import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a webnovel episode
class WebnovelEpisode {
  /// Unique identifier for the episode
  final String id;
  
  /// Title of the episode
  final String title;
  
  /// Content of the episode
  final String content;
  
  /// URL of the .docx file containing the episode content
  final String docxUrl;
  
  /// Whether the episode is locked (requires membership)
  final bool isLocked;
  
  /// Release date of the episode
  final DateTime releaseDate;

  WebnovelEpisode({
    required this.id,
    required this.title,
    required this.content,
    required this.docxUrl,
    required this.isLocked,
    required this.releaseDate,
  });

  /// Create a WebnovelEpisode instance from Firestore data
  factory WebnovelEpisode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Handle null releaseDate safely
    DateTime releaseDate;
    try {
      releaseDate = data['releaseDate'] != null 
          ? (data['releaseDate'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      print('Error parsing releaseDate for episode ${doc.id}: $e');
      releaseDate = DateTime.now();
    }
    
    return WebnovelEpisode(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      docxUrl: data['docxUrl'] ?? '',
      isLocked: data['isLocked'] ?? false,
      releaseDate: releaseDate,
    );
  }

  /// Convert WebnovelEpisode instance to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'docxUrl': docxUrl,
      'isLocked': isLocked,
      'releaseDate': Timestamp.fromDate(releaseDate),
    };
  }
}