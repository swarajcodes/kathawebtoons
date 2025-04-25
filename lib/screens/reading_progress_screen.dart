import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comic_model.dart';
import '../services/reading_progress_service.dart';
import 'comic_detail_screen.dart';

class ReadingProgressScreen extends StatefulWidget {
  @override
  _ReadingProgressScreenState createState() => _ReadingProgressScreenState();
}

class _ReadingProgressScreenState extends State<ReadingProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReadingProgressService _progressService = ReadingProgressService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _inProgressComics = [];
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
  }

  Future<void> _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuestMode') ?? false;

    setState(() {
      _isGuestMode = isGuest;
    });

    _loadReadingProgress();
  }

  Future<void> _loadReadingProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isGuestMode) {
        await _loadLocalReadingProgress();
      } else {
        await _loadFirestoreReadingProgress();
      }
    } catch (e) {
      print('Error loading reading progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // Filter keys related to reading progress
      final progressKeys = allKeys.where((key) => key.startsWith('progress_')).toList();

      // Group by comic ID and count completed episodes
      final Map<String, Set<String>> readEpisodesByComic = {};

      for (final key in progressKeys) {
        // Extract comic ID and episode ID from key (format: progress_comicId_episodeId)
        final parts = key.split('_');
        if (parts.length >= 3) {
          final comicId = parts[1];
          final episodeId = parts[2];
          final progress = prefs.getDouble(key) ?? 0.0;

          // Initialize set if not exists
          if (!readEpisodesByComic.containsKey(comicId)) {
            readEpisodesByComic[comicId] = {};
          }

          // Add episode to set if progress >= 80%
          if (progress >= 0.8) {
            readEpisodesByComic[comicId]!.add(episodeId);
          }
        }
      }

      // Fetch comic details and calculate progress
      final List<Map<String, dynamic>> inProgressComics = [];

      for (final comicId in readEpisodesByComic.keys) {
        try {
          final comicDoc = await _firestore
              .collection('comics')
              .doc(comicId)
              .get();

          if (comicDoc.exists) {
            final comic = Comic.fromFirestore(comicDoc);
            final readEpisodesCount = readEpisodesByComic[comicId]!.length;
            
            // Calculate progress as percentage of episodes read
            final progress = (readEpisodesCount / comic.episodes.length) * 100;

            inProgressComics.add({
              'comic': comic,
              'progress': progress.clamp(0.0, 100.0),
              'lastReadAt': DateTime.now(), // No timestamp in local storage, use current time
            });
          }
        } catch (e) {
          print('Error fetching comic $comicId: $e');
        }
      }

      setState(() {
        _inProgressComics = inProgressComics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading local reading progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFirestoreReadingProgress() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get all reading progress documents for the user
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .get();

      // Group by comic ID
      final Map<String, List<DocumentSnapshot>> progressByComic = {};

      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        final comicId = data['comicId'] as String?;

        if (comicId != null) {
          if (!progressByComic.containsKey(comicId)) {
            progressByComic[comicId] = [];
          }
          progressByComic[comicId]!.add(doc);
        }
      }

      // Fetch comic details for each comic with progress
      final List<Map<String, dynamic>> inProgressComics = [];

      for (final comicId in progressByComic.keys) {
        try {
          final comicDoc = await _firestore
              .collection('comics')
              .doc(comicId)
              .get();

          if (comicDoc.exists) {
            final comic = Comic.fromFirestore(comicDoc);
            // Load episodes from subcollection
            await comic.loadEpisodes();
            
            print('Debug - Loaded comic ${comic.title}:');
            print('- Episodes count: ${comic.episodes.length}');
            
            // Use ReadingProgressService to calculate progress
            final progress = await _progressService.getComicProgress(
              comicId,
              comic.episodes.length,
            );

            // Find latest read timestamp
            DateTime latestTimestamp = DateTime(2000); // Default old date
            for (final doc in progressByComic[comicId]!) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('completedAt')) {
                final timestamp = (data['completedAt'] as Timestamp).toDate();
                if (timestamp.isAfter(latestTimestamp)) {
                  latestTimestamp = timestamp;
                }
              }
            }

            inProgressComics.add({
              'comic': comic,
              'progress': progress,
              'lastReadAt': latestTimestamp,
            });
          }
        } catch (e) {
          print('Error fetching comic $comicId: $e');
        }
      }

      // Sort by last read time (most recent first)
      inProgressComics.sort((a, b) =>
          (b['lastReadAt'] as DateTime).compareTo(a['lastReadAt'] as DateTime));

      setState(() {
        _inProgressComics = inProgressComics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading Firestore reading progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'My Reading Progress',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFA3D749)))
          : _inProgressComics.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No reading progress yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start reading to track your progress',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _inProgressComics.length,
        itemBuilder: (context, index) {
          final item = _inProgressComics[index];
          final comic = item['comic'] as Comic;
          final progress = item['progress'] as double;
          final lastReadAt = item['lastReadAt'] as DateTime;
          
          print('Debug - Progress for ${comic.title}:');
          print('- Raw progress value: $progress');
          print('- Total episodes: ${comic.episodes.length}');
          print('- Last read: $lastReadAt');

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComicDetailScreen(comic: comic),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Comic cover
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      comic.coverImage,
                      height: 120,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Comic details
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comic.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            comic.author,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress/100 ,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFA3D749),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Progress text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${progress.toInt()}% completed',
                                style: TextStyle(
                                  color: Color(0xFFA3D749),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Last read: ${_formatDate(lastReadAt)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
