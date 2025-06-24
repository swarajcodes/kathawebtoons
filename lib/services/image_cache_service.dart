import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Custom cache manager with optimized settings
  static final CustomCacheManager _customCacheManager = CustomCacheManager();
  static final EpisodeViewerCacheManager _episodeViewerCacheManager = EpisodeViewerCacheManager();

  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _accessCounts = {};

  /// Gets the custom cache manager
  static CustomCacheManager get cacheManager => _customCacheManager;

  /// Gets the episode viewer cache manager for high-quality images
  static EpisodeViewerCacheManager get episodeViewerCacheManager => _episodeViewerCacheManager;

  /// Preloads an image with optimized settings
  Future<void> preloadImage(String imageUrl, {String? cacheKey}) async {
    try {
      _totalRequests++;
      final key = cacheKey ?? _generateCacheKey(imageUrl);

      // Check if already in cache
      final fileInfo = await _customCacheManager.getFileFromCache(key);
      if (fileInfo != null) {
        _cacheHits++;
        _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
        return;
      }

      _cacheMisses++;
      await _customCacheManager.downloadFile(imageUrl, key: key);
      _cacheTimestamps[key] = DateTime.now();
      _accessCounts[key] = 1;
    } catch (e) {
      print('Error preloading image $imageUrl: $e');
    }
  }

  /// Preloads multiple images with controlled concurrency
  Future<void> preloadImages(List<String> imageUrls, {
    int maxConcurrent = 3,
    String? cacheKeyPrefix,
  }) async {
    final futures = <Future<void>>[];

    for (int i = 0; i < imageUrls.length; i += maxConcurrent) {
      final batch = imageUrls.skip(i).take(maxConcurrent);
      final batchFutures = batch.map((url) => preloadImage(
        url,
        cacheKey: cacheKeyPrefix != null ? '${cacheKeyPrefix}_${url.hashCode}' : null,
      ));

      await Future.wait(batchFutures);
    }
  }

  /// Clears old cache entries to free up memory
  Future<void> clearOldCache({Duration maxAge = const Duration(days: 7)}) async {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > maxAge) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      await _customCacheManager.removeFile(key);
      _cacheTimestamps.remove(key);
      _accessCounts.remove(key);
    }

    print('Cleared ${keysToRemove.length} old cache entries');
  }

  /// Clears least accessed cache entries
  Future<void> clearLeastAccessed({int keepTop = 100}) async {
    if (_accessCounts.length <= keepTop) return;

    final sortedEntries = _accessCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final keysToRemove = sortedEntries
        .take(_accessCounts.length - keepTop)
        .map((e) => e.key)
        .toList();

    for (final key in keysToRemove) {
      await _customCacheManager.removeFile(key);
      _cacheTimestamps.remove(key);
      _accessCounts.remove(key);
    }

    print('Cleared ${keysToRemove.length} least accessed cache entries');
  }

  /// Gets cache statistics
  Map<String, dynamic> getCacheStats() {
    final hitRate = _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0;
    return {
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': hitRate,
      'cachedItems': _cacheTimestamps.length,
      'totalAccesses': _accessCounts.values.fold(0, (sum, count) => sum + count),
    };
  }

  /// Generates a cache key for an image URL
  String _generateCacheKey(String imageUrl) {
    return 'img_${imageUrl.hashCode}';
  }

  /// Clears all cache
  Future<void> clearAllCache() async {
    await _customCacheManager.emptyCache();
    _cacheTimestamps.clear();
    _accessCounts.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalRequests = 0;
    print('All image cache cleared');
  }
}

/// Custom cache manager with optimized settings
class CustomCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'customCache';

  CustomCacheManager() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Keep images for 30 days
      maxNrOfCacheObjects: 500, // Increased from 200 to handle high-quality images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// High-quality cache manager for episode viewing
class EpisodeViewerCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'episodeViewerCache';

  EpisodeViewerCacheManager() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 60), // Keep episode images longer
      maxNrOfCacheObjects: 100, // Dedicated cache for episode images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}