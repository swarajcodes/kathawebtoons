import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comic_model.dart' as comic_model;
import '../../models/episode_model.dart';
import '../../services/comments_service.dart';
import '../../services/reading_progress_service.dart';

class EpisodeProgressService {
  final String comicId;
  final String episodeId;
  final comic_model.Comic comic;

  final ReadingProgressService _progressService = ReadingProgressService();
  final CommentsService _commentsService = CommentsService();

  bool hasMarkedAsRead = false;
  bool isLiked = false;
  List<Episode> episodes = [];
  Episode? nextEpisode;
  bool isLastEpisode = false;

  EpisodeProgressService({
    required this.comicId,
    required this.episodeId,
    required this.comic,
  });

  Future<void> initialize() async {
    await _checkReadStatus();
    await _fetchEpisodes();
    await _loadEpisodeInteractionData();
  }

  Future<void> _checkReadStatus() async {
    hasMarkedAsRead = await _progressService.isEpisodeRead(
      comicId,
      episodeId,
    );
  }

  Future<void> markAsRead({double percentage = 1.0}) async {
    if (hasMarkedAsRead) return;

    await _progressService.markEpisodeAsRead(
      comicId,
      episodeId,
      percentage: percentage,
    );
    hasMarkedAsRead = true;
  }

  Future<void> _fetchEpisodes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comics')
          .doc(comicId)
          .collection('episodes')
          .orderBy('number', descending: false)
          .get();

      episodes = snapshot.docs.map((doc) => Episode.fromFirestore(doc)).toList();

      final currentIndex = episodes.indexWhere((e) => e.id == episodeId);
      if (currentIndex != -1) {
        final currentEpisodeNumber = episodes[currentIndex].number;
        final hasNextEpisode = episodes.any((e) => e.number > currentEpisodeNumber);

        isLastEpisode = !hasNextEpisode;
        if (hasNextEpisode) {
          nextEpisode = episodes.firstWhere(
                (e) => e.number > currentEpisodeNumber,
          );
        } else {
          nextEpisode = null;
        }
      }
    } catch (e) {
      print("Error fetching episodes: $e");
      isLastEpisode = true;
      nextEpisode = null;
    }
  }

  Future<void> _loadEpisodeInteractionData() async {
    try {
      await _commentsService.recalculateEpisodeStats(
        comicId: comicId,
        episodeId: episodeId,
      );

      await _commentsService.initializeEpisodeStats(
        comicId: comicId,
        episodeId: episodeId,
      );

      isLiked = await _commentsService.hasUserLiked(
        comicId: comicId,
        episodeId: episodeId,
        targetId: episodeId,
      );
    } catch (e) {
      print('Error loading episode interaction data: $e');
    }
  }

  Future<void> toggleEpisodeLike() async {
    try {
      await _commentsService.toggleEpisodeLike(
        comicId: comicId,
        episodeId: episodeId,
      );
      isLiked = !isLiked;
    } catch (e) {
      print('Error toggling episode like: $e');
      rethrow;
    }
  }

  void dispose() {
    // Clean up if needed
  }
}