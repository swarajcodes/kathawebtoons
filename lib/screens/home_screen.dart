import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../models/webnovel_episode.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/comic_tile.dart';
import '../models/comic_model.dart';
import 'comic_detail_screen.dart';
import 'webnovel_episode_screen.dart';

/// A singleton repository class that handles fetching and caching of comic data from Firestore.
/// Implements caching strategies for both data and images to optimize performance.
class ComicRepository {
  // Singleton instance
  static final ComicRepository _instance = ComicRepository._internal();
  factory ComicRepository() => _instance;

  ComicRepository._internal();

  // Cache storage for different comic categories
  List<Comic> _comics = [];          // All comics
  List<Comic> _heroComics = [];      // Featured comics for hero carousel
  List<Comic> _recommendedComics = []; // Recommended comics for "For You" section
  List<Comic> _webnovels = [];       // Webnovels category
  
  // Cache control flags and timing
  bool _isFetched = false;           // Track if initial fetch is complete
  DateTime? _lastFetchTime;          // Last successful fetch timestamp
  static const Duration _cacheExpiration = Duration(minutes: 30);  // Cache validity period

  /// Checks if the current cache has expired
  bool get _isCacheExpired {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheExpiration;
  }

  /// Ensures data is prefetched if needed
  Future<void> prefetchData() async {
    if (!_isFetched || _isCacheExpired) {
      await fetchComics();
    }
  }

  /// Fetches comics from Firestore with a two-tier caching strategy:
  /// 1. First attempts to load from Firestore cache
  /// 2. Then fetches fresh data from server
  /// 
  /// @param forceRefresh Forces a server fetch, bypassing cache
  /// @returns List<Comic> List of all comics
  Future<List<Comic>> fetchComics({bool forceRefresh = false}) async {
    // Return cached data if valid
    if (!forceRefresh && _isFetched && !_isCacheExpired) {
      return _comics;
    }

    try {
      // First try to get from Firestore cache
      if (!forceRefresh) {
        try {
          final cacheSnapshot = await FirebaseFirestore.instance
              .collection('comics')
              .get(const GetOptions(source: Source.cache));
          
          if (cacheSnapshot.docs.isNotEmpty) {
            _comics = cacheSnapshot.docs.map((doc) => Comic.fromFirestore(doc)).toList();
            _categorizeComics();
            _isFetched = true;
            _lastFetchTime = DateTime.now();
          }
        } catch (e) {
          print("No cache available, proceeding with server fetch");
        }
      }

      // Then fetch fresh data from server
      final snapshot = await FirebaseFirestore.instance
          .collection('comics')
          .get(const GetOptions(source: Source.server));
      
      _comics = snapshot.docs.map((doc) => Comic.fromFirestore(doc)).toList();
      _categorizeComics();
      _isFetched = true;
      _lastFetchTime = DateTime.now();

    } catch (e) {
      print("Error fetching comics: $e");
      // Return cached data if available, otherwise throw
      if (_comics.isEmpty) {
        throw Exception("Failed to fetch comics and no cache available");
      }
    }
    return _comics;
  }

  /// Categorizes comics into different sections based on their properties
  void _categorizeComics() {
    _heroComics = _comics.where((comic) => comic.isHero).toList();
    _recommendedComics = _comics.where((comic) => comic.isRecommended).toList();
    _webnovels = _comics.where((comic) => comic.type == 'webnovel').toList();
  }

  // Getters for categorized comics
  List<Comic> getHeroComics() => _heroComics;
  List<Comic> getRecommendedComics() => _recommendedComics;
  List<Comic> getWebnovels() => _webnovels;
  List<Comic> getAllComics() => _comics;

  // Cache for webnovel episodes with LRU-like behavior
  final Map<String, List<WebnovelEpisode>> _webnovelEpisodesCache = {};
  final Map<String, DateTime> _webnovelEpisodesFetchTime = {};
  static const int _maxCacheSize = 10;
  static const Duration _episodeCacheExpiration = Duration(minutes: 15);

  Future<List<WebnovelEpisode>> fetchWebnovelEpisodes(String comicId) async {
    // Check cache first
    if (_webnovelEpisodesCache.containsKey(comicId)) {
      final fetchTime = _webnovelEpisodesFetchTime[comicId];
      if (fetchTime != null && 
          DateTime.now().difference(fetchTime) < _episodeCacheExpiration) {
        print("Using cached webnovel episodes for comic: $comicId");
        return _webnovelEpisodesCache[comicId]!;
      }
    }

    try {
      print("Fetching webnovel episodes for comic: $comicId");
      final snapshot = await FirebaseFirestore.instance
          .collection('comics')
          .doc(comicId)
          .collection('webnovelEpisodes')
          .orderBy('number', descending: false)
          .get(const GetOptions(source: Source.server));

      print("Found ${snapshot.docs.length} webnovel episodes");
      
      final episodes = snapshot.docs.map((doc) {
        final data = doc.data();
        print("Processing webnovel episode: ${data['title']}");
        return WebnovelEpisode.fromFirestore(doc);
      }).toList();
      
      // Update cache
      _webnovelEpisodesCache[comicId] = episodes;
      _webnovelEpisodesFetchTime[comicId] = DateTime.now();
      
      // Implement LRU cache eviction
      if (_webnovelEpisodesCache.length > _maxCacheSize) {
        final oldestKey = _webnovelEpisodesFetchTime.entries
            .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
            .key;
        _webnovelEpisodesCache.remove(oldestKey);
        _webnovelEpisodesFetchTime.remove(oldestKey);
      }
      
      return episodes;
    } catch (e) {
      print("Error fetching webnovel episodes: $e");
      if (_webnovelEpisodesCache.containsKey(comicId)) {
        print("Using cached webnovel episodes");
        return _webnovelEpisodesCache[comicId]!;
      }
      return [];
    }
  }

  void clearCache() {
    _comics = [];
    _heroComics = [];
    _recommendedComics = [];
    _webnovels = [];
    _isFetched = false;
    _lastFetchTime = null;
    _webnovelEpisodesCache.clear();
    _webnovelEpisodesFetchTime.clear();
  }

  // Add static cache for images
  static final Map<String, ImageProvider> _imageCache = {};
  static final Map<String, DateTime> _imageCacheTime = {};
  static const Duration _imageCacheExpiration = Duration(hours: 1);

  /// Caches an image provider
  static void cacheImage(String url, ImageProvider provider) {
    _imageCache[url] = provider;
    _imageCacheTime[url] = DateTime.now();
  }

  /// Gets a cached image provider if available and not expired
  static ImageProvider? getCachedImage(String url) {
    final cacheTime = _imageCacheTime[url];
    if (cacheTime != null && 
        DateTime.now().difference(cacheTime) < _imageCacheExpiration) {
      return _imageCache[url];
    }
    return null;
  }

  /// Clears expired image cache
  static void clearExpiredImageCache() {
    final now = DateTime.now();
    _imageCacheTime.removeWhere((url, time) {
      if (now.difference(time) > _imageCacheExpiration) {
        _imageCache.remove(url);
        return true;
      }
      return false;
    });
  }
}

/// Main home screen widget that displays the comic catalog
/// Implements AutomaticKeepAliveClientMixin to preserve state when navigating
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

/// State class for HomeScreen that handles data loading and UI rendering
class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  // Data management
  late Future<List<Comic>> _comicFuture;
  final _repository = ComicRepository();
  bool _contentReady = false;
  List<Comic>? _cachedComics;
  final List<Future<void>> _imagePreloadFutures = [];
  bool _isInitialized = false;
  bool _isDataFetched = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    }
  }

  /// Initializes the screen data and handles image prefetching
  Future<void> _initializeData() async {
    if (_isDataFetched && _cachedComics != null) {
      setState(() {
        _contentReady = true;
      });
      return;
    }

    try {
      // Only fetch if we don't have cached data or cache is expired
      if (_cachedComics == null || _repository._isCacheExpired) {
        _comicFuture = _repository.fetchComics();
        final comics = await _comicFuture;
        _cachedComics = comics;
        _isDataFetched = true;

        if (!mounted) return;

        // Prepare all image preloading futures
        await _prefetchImagesInOrder(comics);
      }

      if (mounted) {
        setState(() {
          _contentReady = true;
        });
      }
    } catch (e) {
      print("Error initializing data: $e");
      if (mounted) {
        setState(() {
          _contentReady = true; // Show whatever content we have
        });
      }
    }
  }

  /// Prefetches images in priority order to optimize loading experience
  Future<void> _prefetchImagesInOrder(List<Comic> comics) async {
    final List<Future<void>> futures = [];

    // 1. Hero comics (highest priority - visible first)
    final heroComics = comics.where((c) => c.isHero).toList();
    for (final comic in heroComics) {
      if (comic.heroLandscapeImage.isNotEmpty) {
        futures.add(_precacheImage(comic.heroLandscapeImage));
      }
      if (comic.coverImage.isNotEmpty) {
        futures.add(_precacheImage(comic.coverImage));
      }
    }

    // 2. Recommended comics (second priority)
    final recommendedComics = comics.where((c) => c.isRecommended).toList();
    for (final comic in recommendedComics) {
      if (comic.coverImage.isNotEmpty) {
        futures.add(_precacheImage(comic.coverImage));
      }
    }

    // 3. Webnovels (lower priority - may be below fold)
    final webnovels = comics.where((c) => c.type == 'webnovel').toList();
    for (final comic in webnovels) {
      if (comic.coverImage.isNotEmpty) {
        futures.add(_precacheImage(comic.coverImage));
      }
    }

    // Wait for all images to be preloaded
    await Future.wait(futures);
  }

  /// Helper method to precache a single image with error handling
  Future<void> _precacheImage(String imageUrl) async {
    try {
      // Check if image is already cached
      final cachedProvider = ComicRepository.getCachedImage(imageUrl);
      if (cachedProvider != null) {
        return; // Skip precaching if already cached
      }

      // If not cached, load and cache it
      final provider = NetworkImage(imageUrl);
      await precacheImage(provider, context);
      ComicRepository.cacheImage(imageUrl, provider);
    } catch (e) {
      print("Error precaching image $imageUrl: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _contentReady = false;
            _isDataFetched = false;
          });
          await _repository.fetchComics(forceRefresh: true);
          await _initializeData();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  if (!_contentReady) 
                    AnimatedOpacity(
                      opacity: !_contentReady ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildShimmerLoading(),
                    ),
                  if (_cachedComics != null)
                    AnimatedOpacity(
                      opacity: _contentReady ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Carousel Section
                          HeroCarousel(
                            heroComics: _cachedComics?.where((c) => c.isHero).toList() ?? [],
                            onComicTap: (comic) => _navigateToDetail(context, comic),
                          ),
                          SizedBox(height: 20),

                          // For You Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'For You ✨',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Recommended Comics List
                          Container(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _cachedComics?.where((c) => c.isRecommended && c.type != 'webnovel').toList().length ?? 0,
                              itemBuilder: (context, index) {
                                final recommendedComics = _cachedComics?.where((c) => c.isRecommended && c.type != 'webnovel').toList() ?? [];
                                return Container(
                                  margin: EdgeInsets.only(right: 16),
                                  child: ComicTile(
                                    comic: recommendedComics.isNotEmpty ? recommendedComics[index] : Comic(
                                      id: 'default',
                                      title: 'No Recommended Comic',
                                      author: 'Unknown',
                                      description: 'No description available',
                                      coverImage: 'https://via.placeholder.com/150',
                                      heroLandscapeImage: 'https://via.placeholder.com/150',
                                      isHero: false,
                                      isWebnovel: false,
                                      episodes: [],
                                      genre: [],
                                      isRecommended: true,
                                      isNew: false,
                                      type: 'webtoon',
                                    ),
                                    onTap: () => _navigateToDetail(context, recommendedComics[index]),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Webnovels Section
                          if (_cachedComics?.where((c) => c.type == 'webnovel').toList().isNotEmpty == true) ...[
                            SizedBox(height: 20),
                            // Webnovels header with same style as For You
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Explore Webnovels 📚',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            // Webnovels list with same container style
                            Container(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _cachedComics?.where((c) => c.type == 'webnovel').toList().length ?? 0,
                                itemBuilder: (context, index) {
                                  final webnovels = _cachedComics?.where((c) => c.type == 'webnovel').toList() ?? [];
                                  return Container(
                                    margin: EdgeInsets.only(right: 16),
                                    child: ComicTile(
                                      comic: webnovels.isNotEmpty ? webnovels[index] : Comic(
                                        id: 'default',
                                        title: 'No Webnovel',
                                        author: 'Unknown',
                                        description: 'No description available',
                                        coverImage: 'https://via.placeholder.com/150',
                                        heroLandscapeImage: 'https://via.placeholder.com/150',
                                        isHero: false,
                                        isWebnovel: true,
                                        episodes: [],
                                        genre: [],
                                        isRecommended: false,
                                        isNew: false,
                                        type: 'webnovel',
                                      ),
                                      onTap: () => _navigateToDetail(context, webnovels[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the shimmer loading placeholder for the entire screen
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero carousel shimmer effect
          _buildHeroShimmer(),
          SizedBox(height: 20),

          // For You section shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'For You ✨',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildHorizontalListShimmer(),

          SizedBox(height: 20),

          // Webnovels section shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Explore Webnovels 📚',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildHorizontalListShimmer(),
        ],
      ),
    );
  }

  /// Builds a shimmer effect for the hero carousel section
  Widget _buildHeroShimmer() {
    return Shimmer.fromColors(
      baseColor: Color(0xFF333333),
      highlightColor: Color(0xFF444444),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Builds a shimmer effect for horizontal scrolling lists
  /// Used for both "For You" and "Webnovels" sections
  Widget _buildHorizontalListShimmer() {
    return Container(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5, // Show 5 placeholder items
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Color(0xFF333333),
              highlightColor: Color(0xFF444444),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comic cover placeholder
                  Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Title placeholder
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 4),
                  // Author placeholder
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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

  /// Navigates to the appropriate detail screen based on comic type
  /// @param comic The comic to display
  void _navigateToDetail(BuildContext context, Comic comic) {
    // Pre-cache the comic's images before navigating
    if (comic.coverImage.isNotEmpty) {
      _precacheImage(comic.coverImage);
    }
    if (comic.heroLandscapeImage.isNotEmpty) {
      _precacheImage(comic.heroLandscapeImage);
    }
    
    if (comic.isWebnovel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebnovelEpisodeScreen(
            comic: comic,
            episode: WebnovelEpisode(
              id: comic.episodes.first.id,
              title: comic.episodes.first.title,
              content: comic.episodes.first.images.first,
              docxUrl: comic.episodes.first.images.first,
              isLocked: comic.episodes.first.isLocked,
              releaseDate: comic.episodes.first.releaseDate ?? DateTime.now(),
            ),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComicDetailScreen(comic: comic),
        ),
      );
    }
  }
}