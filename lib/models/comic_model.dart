import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing an episode of a comic/webtoon/webnovel
class Episode {
  /// Unique identifier for the episode
  final String id;
  
  /// Title of the episode
  final String title;
  
  /// List of image URLs for the episode
  final List<String> images;
  
  /// Preview image URL for the episode
  final String previewImage;
  
  /// Whether the episode is locked (requires membership)
  final bool isLocked;
  
  /// Release date of the episode
  final DateTime? releaseDate;

  Episode({
    required this.id,
    required this.title,
    required this.images,
    required this.previewImage,
    required this.isLocked,
    required this.releaseDate,
  });

  /// Create an Episode instance from Firestore data
  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      previewImage: map['previewImage'] ?? '',
      isLocked: map['isLocked'] ?? false,
      releaseDate: map['releaseDate'] != null ? (map['releaseDate'] as Timestamp).toDate() : null,
    );
  }

  /// Convert Episode instance to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'images': images,
      'previewImage': previewImage,
      'isLocked': isLocked,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
    };
  }
}

/// Model class representing a comic/webtoon/webnovel
class Comic {
  /// Unique identifier for the comic
  final String id;
  
  /// Title of the comic
  final String title;
  
  /// Author of the comic
  final String author;
  
  /// Description of the comic
  final String description;
  
  /// URL of the cover image
  final String coverImage;
  
  /// URL of the hero landscape image (for featured display)
  final String heroLandscapeImage;
  
  /// Whether this comic is featured in the hero carousel
  final bool isHero;
  
  /// Whether this is a webnovel (text-based) or webtoon (image-based)
  final bool isWebnovel;
  
  /// List of episodes in this comic
  final List<Episode> episodes;
  
  /// List of genres for this comic
  final List<String> genre;
  
  /// Whether this comic is recommended
  final bool isRecommended;
  
  /// Whether this comic is new
  final bool isNew;
  
  /// Type of the comic (webnovel or webtoon)
  final String type;

  Comic({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImage,
    required this.heroLandscapeImage,
    required this.isHero,
    required this.isWebnovel,
    required this.episodes,
    required this.genre,
    required this.isRecommended,
    required this.isNew,
    required this.type,
  });

  /// Create a Comic instance from Firestore data
  factory Comic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comic(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      coverImage: data['coverImage'] ?? '',
      heroLandscapeImage: data['heroLandscapeImage'] ?? '',
      isHero: data['isHero'] ?? false,
      isWebnovel: data['isWebnovel'] ?? false,
      episodes: List<Episode>.from(
        (data['episodes'] ?? []).map((e) => Episode.fromMap(e)),
      ),
      genre: List<String>.from(data['genre'] ?? []),
      isRecommended: data['isRecommended'] ?? false,
      isNew: data['isNew'] ?? false,
      type: data['type'] ?? 'webtoon',
    );
  }

  /// Convert Comic instance to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverImage': coverImage,
      'heroLandscapeImage': heroLandscapeImage,
      'isHero': isHero,
      'isWebnovel': isWebnovel,
      'episodes': episodes.map((e) => e.toMap()).toList(),
      'genre': genre,
      'isRecommended': isRecommended,
      'isNew': isNew,
      'type': type,
    };
  }
}