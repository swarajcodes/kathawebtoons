// comic_cache_manager.dart
import 'package:flutter/material.dart';
import '../models/comic_model.dart';
import '../models/episode_model.dart' as episode_model;
import '../models/webnovel_episode.dart';

class ComicCacheManager {
  static final ComicCacheManager _instance = ComicCacheManager._internal();
  factory ComicCacheManager() => _instance;
  ComicCacheManager._internal();

  // Cache storage
  final Map<String, List<episode_model.Episode>> _comicEpisodesCache = {};
  final Map<String, List<WebnovelEpisode>> _webnovelEpisodesCache = {};
  final Map<String, String> _webnovelContentCache = {};

  // Cache comic episodes
  void cacheComicEpisodes(String comicId, List<episode_model.Episode> episodes) {
    _comicEpisodesCache[comicId] = episodes;
  }

  // Get cached comic episodes
  List<episode_model.Episode>? getCachedComicEpisodes(String comicId) {
    return _comicEpisodesCache[comicId];
  }

  // Cache webnovel episodes
  void cacheWebnovelEpisodes(String comicId, List<WebnovelEpisode> episodes) {
    _webnovelEpisodesCache[comicId] = episodes;
  }

  // Get cached webnovel episodes
  List<WebnovelEpisode>? getCachedWebnovelEpisodes(String comicId) {
    return _webnovelEpisodesCache[comicId];
  }

  // Cache webnovel content
  void cacheWebnovelContent(String docxUrl, String content) {
    _webnovelContentCache[docxUrl] = content;
  }

  // Get cached webnovel content
  String? getCachedWebnovelContent(String docxUrl) {
    return _webnovelContentCache[docxUrl];
  }

  // Clear all caches (optional, for memory management)
  void clearAllCaches() {
    _comicEpisodesCache.clear();
    _webnovelEpisodesCache.clear();
    _webnovelContentCache.clear();
  }

  // Clear specific comic cache
  void clearComicCache(String comicId) {
    _comicEpisodesCache.remove(comicId);
    _webnovelEpisodesCache.remove(comicId);
    // Find and remove all webnovel content for this comic
    if (_webnovelEpisodesCache[comicId] != null) {
      for (var episode in _webnovelEpisodesCache[comicId]!) {
        _webnovelContentCache.remove(episode.docxUrl);
      }
    }
  }
}