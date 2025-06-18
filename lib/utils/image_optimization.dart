import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_cache_service.dart';
import '../services/performance_monitor.dart';

class ImageOptimization {
  // Cache configuration
  static const int maxMemCacheWidth = 1920;
  static const int maxMemCacheHeight = 1080;
  static const int maxDiskCacheWidth = 1920;
  static const int maxDiskCacheHeight = 1080;
  
  // Progressive loading configuration
  static const Duration fadeInDuration = Duration(milliseconds: 300);
  static const Duration placeholderDuration = Duration(milliseconds: 500);
  
  // Image quality settings
  static const double heroImageQuality = 0.85;
  static const double coverImageQuality = 0.8;
  static const double thumbnailQuality = 0.7;
  
  /// Safely calculates cache dimensions with bounds checking
  /// This prevents "Infinity or NaN toInt" errors when width/height are infinite
  static int _safeCalculateCacheDimension(double dimension, double multiplier, int fallback) {
    if (!dimension.isFinite || dimension <= 0) {
      return fallback;
    }
    final calculated = dimension * multiplier;
    if (!calculated.isFinite || calculated <= 0) {
      return fallback;
    }
    return calculated.round();
  }
  
  /// Creates an optimized CachedNetworkImage widget for hero/landscape images
  static Widget heroImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: ImageCacheService.cacheManager,
      memCacheWidth: _safeCalculateCacheDimension(width, 2.0, 1920), // 2x for high DPI screens
      memCacheHeight: _safeCalculateCacheDimension(height, 2.0, 1080),
      maxWidthDiskCache: maxDiskCacheWidth,
      maxHeightDiskCache: maxDiskCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeInDuration,
      placeholder: placeholder ?? _heroPlaceholder(),
      errorWidget: errorWidget ?? _heroErrorWidget(),
      cacheKey: _generateCacheKey(imageUrl, 'hero'),
    );
  }
  
  /// Creates an optimized CachedNetworkImage widget for cover images
  static Widget coverImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: ImageCacheService.cacheManager,
      memCacheWidth: _safeCalculateCacheDimension(width, 1.5, 180), // 1.5x for medium quality
      memCacheHeight: _safeCalculateCacheDimension(height, 1.5, 240),
      maxWidthDiskCache: maxDiskCacheWidth,
      maxHeightDiskCache: maxDiskCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeInDuration,
      placeholder: placeholder ?? _coverPlaceholder(),
      errorWidget: errorWidget ?? _coverErrorWidget(),
      cacheKey: _generateCacheKey(imageUrl, 'cover'),
    );
  }
  
  /// Creates an optimized CachedNetworkImage widget for thumbnails
  static Widget thumbnailImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: ImageCacheService.cacheManager,
      memCacheWidth: _safeCalculateCacheDimension(width, 1.0, 80),
      memCacheHeight: _safeCalculateCacheDimension(height, 1.0, 80),
      maxWidthDiskCache: 800, // Smaller disk cache for thumbnails
      maxHeightDiskCache: 800,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeInDuration,
      placeholder: placeholder ?? _thumbnailPlaceholder(),
      errorWidget: errorWidget ?? _thumbnailErrorWidget(),
      cacheKey: _generateCacheKey(imageUrl, 'thumbnail'),
    );
  }
  
  /// Creates a high-quality CachedNetworkImage widget for episode viewing
  /// This maintains full resolution for zooming and text reading
  static Widget episodeViewerImage({
    required String imageUrl,
    required double width,
    double? height,
    BoxFit fit = BoxFit.fitWidth,
    double quality = 1.0,
    bool highQuality = true,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    // Determine cache manager based on quality preference
    final cacheManager = highQuality 
        ? ImageCacheService.episodeViewerCacheManager
        : ImageCacheService.cacheManager;
    
    // Adjust cache settings based on quality
    final memCacheWidth = highQuality ? null : _safeCalculateCacheDimension(width, 1.5, 1920);
    final memCacheHeight = highQuality ? null : _safeCalculateCacheDimension(height ?? 600, 1.5, 1080);
    final maxWidthDiskCache = highQuality ? null : maxDiskCacheWidth;
    final maxHeightDiskCache = highQuality ? null : maxDiskCacheHeight;
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: cacheManager,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeInDuration,
      placeholder: placeholder ?? _episodeViewerPlaceholder(),
      errorWidget: errorWidget ?? _episodeViewerErrorWidget(),
      cacheKey: _generateCacheKey(imageUrl, 'episode_viewer'),
    );
  }
  
  /// Creates a network-aware episode viewer image with adaptive quality
  static Widget adaptiveEpisodeViewerImage({
    required String imageUrl,
    required double width,
    double? height,
    BoxFit fit = BoxFit.fitWidth,
    bool isSlowNetwork = false,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    // Adjust quality based on network conditions
    final highQuality = !isSlowNetwork;
    
    return episodeViewerImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      highQuality: highQuality,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
  
  /// Creates an optimized CachedNetworkImage widget for episode images
  static Widget episodeImage({
    required String imageUrl,
    required double width,
    double? height,
    BoxFit fit = BoxFit.fitWidth,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: ImageCacheService.cacheManager,
      memCacheWidth: _safeCalculateCacheDimension(width, 1.2, 800), // Slightly higher for episode images
      memCacheHeight: height != null ? _safeCalculateCacheDimension(height, 1.2, 600) : null,
      maxWidthDiskCache: maxDiskCacheWidth,
      maxHeightDiskCache: maxDiskCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeInDuration,
      placeholder: placeholder ?? _defaultPlaceholder(),
      errorWidget: errorWidget ?? _defaultErrorWidget(),
      cacheKey: _generateCacheKey(imageUrl, 'episode'),
    );
  }
  
  /// Default placeholder widget with appropriate sizing
  static Widget Function(BuildContext, String) _defaultPlaceholder() {
    return (context, url) => Container(
      width: double.infinity,
      height: 400, // Standard page height
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.lightGreenAccent,
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  /// Default error widget with appropriate sizing
  static Widget Function(BuildContext, String, Object) _defaultErrorWidget() {
    return (context, url, error) => Container(
      width: double.infinity,
      height: 400, // Standard page height
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Placeholder for hero images (landscape)
  static Widget Function(BuildContext, String) _heroPlaceholder() {
    return (context, url) => Container(
      width: double.infinity,
      height: 200, // Hero image height
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.lightGreenAccent,
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  /// Placeholder for cover images (portrait)
  static Widget Function(BuildContext, String) _coverPlaceholder() {
    return (context, url) => Container(
      width: 120,
      height: 160, // Cover image aspect ratio
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.lightGreenAccent,
          strokeWidth: 1.5,
        ),
      ),
    );
  }
  
  /// Placeholder for thumbnails (square)
  static Widget Function(BuildContext, String) _thumbnailPlaceholder() {
    return (context, url) => Container(
      width: 80,
      height: 80, // Square thumbnail
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.lightGreenAccent,
          strokeWidth: 1,
        ),
      ),
    );
  }
  
  /// Placeholder for episode viewer images (full page)
  static Widget Function(BuildContext, String) _episodeViewerPlaceholder() {
    return (context, url) => Container(
      width: double.infinity,
      height: 600, // Full page height for episode viewing
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.lightGreenAccent,
          strokeWidth: 3,
        ),
      ),
    );
  }
  
  /// Error widget for hero images (landscape)
  static Widget Function(BuildContext, String, Object) _heroErrorWidget() {
    return (context, url, error) => Container(
      width: double.infinity,
      height: 200, // Hero image height
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Error widget for cover images (portrait)
  static Widget Function(BuildContext, String, Object) _coverErrorWidget() {
    return (context, url, error) => Container(
      width: 120,
      height: 160, // Cover image aspect ratio
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              'Failed to load',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Error widget for thumbnails (square)
  static Widget Function(BuildContext, String, Object) _thumbnailErrorWidget() {
    return (context, url, error) => Container(
      width: 80,
      height: 80, // Square thumbnail
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 16,
            ),
            SizedBox(height: 4),
            Text(
              'Error',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Error widget for episode viewer images (full page)
  static Widget Function(BuildContext, String, Object) _episodeViewerErrorWidget() {
    return (context, url, error) => Container(
      width: double.infinity,
      height: 600, // Full page height for episode viewing
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            SizedBox(height: 20),
            Text(
              'Failed to load high-quality image',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Generates a cache key for better cache management
  static String _generateCacheKey(String url, String type) {
    return '${type}_${url.hashCode}';
  }
  
  /// Preloads images with optimization using the custom cache service
  static Future<void> preloadImage(String imageUrl, BuildContext context, {String type = 'cover'}) async {
    return PerformanceMonitor().monitorOperation(
      'preload_image_$type',
      () async {
        try {
          await ImageCacheService().preloadImage(
            imageUrl, 
            cacheKey: _generateCacheKey(imageUrl, type),
          );
        } catch (e) {
          print('Error preloading image $imageUrl: $e');
          rethrow;
        }
      },
    );
  }
  
  /// Preloads multiple images with priority using the custom cache service
  static Future<void> preloadImagesWithPriority(
    List<String> imageUrls, 
    BuildContext context, {
    String type = 'cover',
    int maxConcurrent = 3,
  }) async {
    return PerformanceMonitor().monitorOperation(
      'preload_images_batch_$type',
      () async {
        await ImageCacheService().preloadImages(
          imageUrls,
          maxConcurrent: maxConcurrent,
          cacheKeyPrefix: type,
        );
      },
    );
  }
  
  /// Gets cache statistics for monitoring
  static Map<String, dynamic> getCacheStats() {
    return ImageCacheService().getCacheStats();
  }
  
  /// Gets performance statistics
  static Map<String, Map<String, dynamic>> getPerformanceStats() {
    return PerformanceMonitor().getAllStats();
  }
  
  /// Gets performance issues
  static List<String> getPerformanceIssues() {
    return PerformanceMonitor().getPerformanceIssues();
  }
  
  /// Clears old cache entries
  static Future<void> clearOldCache({Duration maxAge = const Duration(days: 7)}) async {
    await ImageCacheService().clearOldCache(maxAge: maxAge);
  }
  
  /// Clears all cache
  static Future<void> clearAllCache() async {
    await ImageCacheService().clearAllCache();
  }
  
  /// Clears performance statistics
  static void clearPerformanceStats() {
    PerformanceMonitor().clearStats();
  }
} 