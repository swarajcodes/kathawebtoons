import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_progress_model.dart';

class ReadingProgressService {
  // Singleton pattern
  static final ReadingProgressService _instance = ReadingProgressService._internal();
  factory ReadingProgressService() => _instance;
  ReadingProgressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for faster UI updates
  final Map<String, Map<String, ReadingProgress>> _progressCache = {};

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuestMode') ?? false;
  }

  // Mark episode as read
  Future<void> markEpisodeAsRead(String comicId, String episodeId, {double percentage = 1.0}) async {
    try {
      print('Debug - Marking episode as read:');
      print('- Comic ID: $comicId');
      print('- Episode ID: $episodeId');
      print('- Percentage: $percentage');

      // For guest mode, only save locally
      if (await isGuestMode() || !isUserLoggedIn) {
        print('Debug - Saving progress locally');
        await _saveProgressLocally(comicId, episodeId, percentage);
        return;
      }

      final userId = currentUserId;
      if (userId == null) {
        print('Debug - No user ID found, cannot save to Firestore');
        return;
      }

      print('Debug - Saving progress to Firestore');
      final progress = ReadingProgress(
        userId: userId,
        comicId: comicId,
        episodeId: episodeId,
        completedAt: DateTime.now(),
        readPercentage: percentage,
      );

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc('${comicId}_${episodeId}')
          .set(progress.toJson());

      // Update local cache
      if (!_progressCache.containsKey(comicId)) {
        _progressCache[comicId] = {};
      }
      _progressCache[comicId]![episodeId] = progress;

      // Also save locally for offline access
      await _saveProgressLocally(comicId, episodeId, percentage);
      print('Debug - Progress saved successfully');
    } catch (e) {
      print('Error marking episode as read: $e');
    }
  }

  // Save progress locally using SharedPreferences
  Future<void> _saveProgressLocally(String comicId, String episodeId, double percentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'progress_${comicId}_${episodeId}';
      await prefs.setDouble(key, percentage);
    } catch (e) {
      print('Error saving progress locally: $e');
    }
  }

  // Get local progress
  Future<double> getLocalProgress(String comicId, String episodeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'progress_${comicId}_${episodeId}';
      return prefs.getDouble(key) ?? 0.0;
    } catch (e) {
      print('Error getting local progress: $e');
      return 0.0;
    }
  }

  // Check if episode is read
  Future<bool> isEpisodeRead(String comicId, String episodeId) async {
    try {
      // Check cache first
      if (_progressCache.containsKey(comicId) &&
          _progressCache[comicId]!.containsKey(episodeId)) {
        return _progressCache[comicId]![episodeId]!.readPercentage >= 0.8; // Consider read if >= 80%
      }

      // For guest mode or logged out users, check local storage
      if (await isGuestMode() || !isUserLoggedIn) {
        final progress = await getLocalProgress(comicId, episodeId);
        return progress >= 0.8; // Consider read if >= 80%
      }

      final userId = currentUserId;
      if (userId == null) return false;

      // Check Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc('${comicId}_${episodeId}')
          .get();

      if (doc.exists) {
        final progress = ReadingProgress.fromFirestore(doc);

        // Update cache
        if (!_progressCache.containsKey(comicId)) {
          _progressCache[comicId] = {};
        }
        _progressCache[comicId]![episodeId] = progress;

        return progress.readPercentage >= 0.8; // Consider read if >= 80%
      }

      return false;
    } catch (e) {
      print('Error checking if episode is read: $e');
      return false;
    }
  }

  // Get all read episodes for a comic
  Future<List<String>> getReadEpisodes(String comicId) async {
    try {
      final List<String> readEpisodes = [];
      print('Debug - Getting read episodes for comic $comicId');

      // For guest mode or logged out users, check local storage
      if (await isGuestMode() || !isUserLoggedIn) {
        print('Debug - Using local storage for progress');
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        print('Debug - All local keys: ${allKeys.join(", ")}');

        for (final key in allKeys) {
          if (key.startsWith('progress_${comicId}_')) {
            final progress = prefs.getDouble(key) ?? 0.0;
            print('Debug - Found progress for key $key: $progress');
            if (progress >= 0.8) { // Consider read if >= 80%
              final episodeId = key.split('_')[2];
              readEpisodes.add(episodeId);
              print('Debug - Added episode $episodeId to read episodes');
            }
          }
        }

        print('Debug - Local read episodes: ${readEpisodes.join(", ")}');
        return readEpisodes;
      }

      final userId = currentUserId;
      if (userId == null) {
        print('Debug - No user ID found');
        return [];
      }

      print('Debug - Using Firestore for progress');
      // Check Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .where('comicId', isEqualTo: comicId)
          .where('readPercentage', isGreaterThanOrEqualTo: 0.8) // Changed to >= 0.8
          .get();

      print('Debug - Firestore query returned ${snapshot.docs.length} documents');

      // Use a Set to ensure unique episode IDs
      final Set<String> uniqueReadEpisodes = {};

      for (final doc in snapshot.docs) {
        final progress = ReadingProgress.fromFirestore(doc);
        print('Debug - Found progress document: ${doc.id} with percentage ${progress.readPercentage}');
        uniqueReadEpisodes.add(progress.episodeId);

        // Update cache
        if (!_progressCache.containsKey(comicId)) {
          _progressCache[comicId] = {};
        }
        _progressCache[comicId]![progress.episodeId] = progress;
      }

      final result = uniqueReadEpisodes.toList();
      print('Debug - Firestore read episodes: ${result.join(", ")}');
      return result;
    } catch (e) {
      print('Error getting read episodes: $e');
      return [];
    }
  }

  // Get reading progress for a comic (percentage of episodes read)
  Future<double> getComicProgress(String comicId, int totalEpisodes) async {
    try {
      print('Debug - Starting getComicProgress for comic $comicId');
      
      // Fetch the comic document to determine its type
      final comicDoc = await _firestore.collection('comics').doc(comicId).get();
      final type = comicDoc.data()?['type'] ?? 'comic';
      final subcollection = type == 'webnovel' ? 'webnovelEpisodes' : 'episodes';
      print('Debug - type for $comicId: $type');
      print('Debug - Using subcollection: $subcollection');

      // Get actual episode count from the correct subcollection
      final episodesSnapshot = await _firestore
          .collection('comics')
          .doc(comicId)
          .collection(subcollection)
          .get();
      
      final actualTotalEpisodes = episodesSnapshot.docs.length;
      print('- Total episodes from subcollection "$subcollection": $actualTotalEpisodes');
      
      if (actualTotalEpisodes <= 0) {
        print('Warning: No episodes found in subcollection for comic $comicId');
        return 0.0;
      }

      final readEpisodes = await getReadEpisodes(comicId);
      print('Debug - Comic $comicId progress calculation:');
      print('- Total episodes: $actualTotalEpisodes');
      print('- Read episodes count: ${readEpisodes.length}');
      print('- Read episode IDs: ${readEpisodes.join(", ")}');
      
      // Calculate percentage based on number of episodes read
      if (readEpisodes.isEmpty) {
        print('- No episodes read, returning 0%');
        return 0.0;
      }
      
      final progress = (readEpisodes.length / actualTotalEpisodes) * 100;
      // Ensure progress doesn't exceed 100%
      final clampedProgress = progress.clamp(0.0, 100.0);
      print('- Progress calculation details:');
      print('  * Read episodes: ${readEpisodes.length}');
      print('  * Total episodes: $actualTotalEpisodes');
      print('  * Raw progress: $progress');
      print('  * Clamped progress: $clampedProgress');
      return clampedProgress;
    } catch (e) {
      print('Error calculating comic progress: $e');
      return 0.0;
    }
  }

  // Get episode progress (percentage of episode read)
  Future<double> getEpisodeProgress(String comicId, String episodeId) async {
    try {
      // Check cache first
      if (_progressCache.containsKey(comicId) &&
          _progressCache[comicId]!.containsKey(episodeId)) {
        return _progressCache[comicId]![episodeId]!.readPercentage * 100;
      }

      // For guest mode or logged out users, check local storage
      if (await isGuestMode() || !isUserLoggedIn) {
        final progress = await getLocalProgress(comicId, episodeId);
        return progress * 100;
      }

      final userId = currentUserId;
      if (userId == null) return 0.0;

      // Check Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc('${comicId}_${episodeId}')
          .get();

      if (doc.exists) {
        final progress = ReadingProgress.fromFirestore(doc);
        return progress.readPercentage * 100;
      }

      return 0.0;
    } catch (e) {
      print('Error getting episode progress: $e');
      return 0.0;
    }
  }

  // Clear cache
  void clearCache() {
    _progressCache.clear();
  }
}
