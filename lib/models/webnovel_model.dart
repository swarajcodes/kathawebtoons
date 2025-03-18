import 'package:cloud_firestore/cloud_firestore.dart';

class Webnovel {
  final String id;
  final String title;
  final String author;
  final String coverImage;
  final List<String> genre;
  final bool isNew;

  Webnovel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.genre,
    this.isNew = false,
  });

  factory Webnovel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Webnovel(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      coverImage: data['coverImage'] ?? '',
      genre: List<String>.from(data['genre'] ?? []),
      isNew: data['isNew'] ?? false,
    );
  }
}