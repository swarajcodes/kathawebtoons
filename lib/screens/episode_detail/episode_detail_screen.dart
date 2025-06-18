import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import '../../models/comic_model.dart' as comic_model;
import '../../models/episode_model.dart';
import '../../widgets/comments_bottom_sheet.dart';
import '../../utils/image_optimization.dart';
import '/screens/episode_detail/episode_progress_service.dart';
import '/screens/episode_detail/episode_view_manager.dart';
import '/screens/episode_detail/widgets/episode_control_bar.dart';
import '/screens/episode_detail/widgets/episode_fullscreen_overlay.dart';
import '/screens/episode_detail/widgets/episode_interaction_bar.dart';
import '/screens/episode_detail/widgets/horizontal_episode_view.dart';
import '/screens/episode_detail/widgets/vertical_episode_view.dart';

// Theme colors to match WebnovelEpisodeScreen
final Color _darkBackground = Color(0xFF1A1A1A);
final Color _darkText = Color(0xFFE0E0E0);
final Color _accentColor = Color(0xFFA3D749);
final Color _secondaryColor = Color(0xFF505050);
final String _fontFamily = 'Plus Jakarta Sans';

class SecureScreenHandler {
  static const MethodChannel _channel = MethodChannel('secure_screen_channel');

  static Future<void> enableSecureScreen() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } on PlatformException catch (e) {
      print("Failed to enable secure screen: ${e.message}");
    }
  }

  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } on PlatformException catch (e) {
      print("Failed to disable secure screen: ${e.message}");
    }
  }
}

class EpisodeDetailScreen extends StatefulWidget {
  final comic_model.Comic comic;
  final Episode episode;

  const EpisodeDetailScreen({
    Key? key,
    required this.comic,
    required this.episode,
  }) : super(key: key);

  @override
  _EpisodeDetailScreenState createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen>
    with TickerProviderStateMixin {
  late EpisodeViewManager viewManager;
  late EpisodeProgressService progressService;
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  bool _isCharging = false;
  String _currentTime = '';
  late Timer _timer;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  
  // Image preloading state
  Set<String> _preloadedImages = {};
  bool _isPreloading = false;
  Timer? _preloadTimer;

  @override
  void initState() {
    super.initState();
    viewManager = EpisodeViewManager(
      episode: widget.episode,
      vsync: this,
    );
    progressService = EpisodeProgressService(
      comicId: widget.comic.id,
      episodeId: widget.episode.id,
      comic: widget.comic,
    );
    _initBattery();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (t) => _updateTime());
    progressService.initialize();
    SecureScreenHandler.enableSecureScreen(); // Enable screenshot protection

    // Setup listeners
    viewManager.horizontalPageController.addListener(_handleHorizontalPageChange);
    viewManager.verticalScrollController.addListener(_handleVerticalScroll);
    
    // Initialize image preloading
    _initializeImagePreloading();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTime();
  }

  @override
  void dispose() {
    _timer.cancel();
    _preloadTimer?.cancel();
    _batteryStateSubscription?.cancel();
    viewManager.dispose();
    SecureScreenHandler.disableSecureScreen(); // Disable screenshot protection
    super.dispose();
  }

  void _handleHorizontalPageChange() {
    if (viewManager.horizontalPageController.hasClients && viewManager.isHorizontalMode) {
      final page = viewManager.horizontalPageController.page?.round() ?? 0;
      if (page != viewManager.currentPage) {
        setState(() {
          viewManager.currentPage = page;
        });

        double progress = (page + 1) / widget.episode.images.length;
        setState(() {
          viewManager.scrollProgress = progress;
        });

        if (progress > 0.8 && !progressService.hasMarkedAsRead) {
          progressService.markAsRead(percentage: progress);
        }
        
        // Trigger predictive preloading on page change
        _predictivePreload();
      }
    }
  }

  void _handleVerticalScroll() {
    if (viewManager.verticalScrollController.hasClients && !viewManager.isHorizontalMode) {
      double offset = viewManager.verticalScrollController.offset;
      double totalHeight = viewManager.verticalScrollController.position.maxScrollExtent;

      if (totalHeight > 0) {
        double progress = (offset / totalHeight).clamp(0.0, 1.0);
        final newPage = (progress * (widget.episode.images.length - 1)).round();

        setState(() {
          viewManager.scrollProgress = progress;
          viewManager.currentPage = newPage;
        });

        if (progress > 0.8 && !progressService.hasMarkedAsRead) {
          progressService.markAsRead(percentage: progress);
        }
        
        // Trigger predictive preloading on significant scroll
        if (newPage != viewManager.currentPage) {
          _predictivePreload();
        }
      }
    }
  }

  Future<void> _initBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
        setState(() {
          _isCharging = state == BatteryState.charging;
        });
      });
    } catch (e) {
      print('Error initializing battery: $e');
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${_formatTime(now.hour)}:${_formatTime(now.minute)}';
    });
  }

  String _formatTime(int time) {
    return time.toString().padLeft(2, '0');
  }

  IconData _getBatteryIcon() {
    if (_isCharging) {
      return Icons.battery_charging_full;
    }
    if (_batteryLevel >= 95) return Icons.battery_full;
    if (_batteryLevel >= 75) return Icons.battery_6_bar;
    if (_batteryLevel >= 50) return Icons.battery_4_bar;
    if (_batteryLevel >= 25) return Icons.battery_3_bar;
    if (_batteryLevel >= 10) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  /// Initialize image preloading for the episode
  Future<void> _initializeImagePreloading() async {
    if (_isPreloading) return;
    
    setState(() {
      _isPreloading = true;
    });
    
    try {
      // Preload first few images immediately
      await _preloadEpisodeImages(0);
      
      // Set up predictive preloading timer
      _preloadTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        _predictivePreload();
      });
    } catch (e) {
      print('Error initializing image preloading: $e');
    } finally {
      setState(() {
        _isPreloading = false;
      });
    }
  }

  /// Preload episode images starting from a specific index
  Future<void> _preloadEpisodeImages(int startIndex) async {
    final images = widget.episode.images;
    if (images.isEmpty) return;
    
    final preloadUrls = <String>[];
    final endIndex = (startIndex + 3).clamp(0, images.length - 1);
    
    for (int i = startIndex; i <= endIndex; i++) {
      final imageUrl = images[i];
      if (!_preloadedImages.contains(imageUrl)) {
        preloadUrls.add(imageUrl);
      }
    }
    
    if (preloadUrls.isNotEmpty) {
      try {
        await ImageOptimization.preloadImagesWithPriority(
          preloadUrls,
          context,
          type: 'episode_viewer',
          maxConcurrent: 2,
        );
        
        setState(() {
          _preloadedImages.addAll(preloadUrls);
        });
        
        print('Preloaded ${preloadUrls.length} episode images');
      } catch (e) {
        print('Error preloading episode images: $e');
      }
    }
  }

  /// Predictive preloading based on current page and user behavior
  void _predictivePreload() {
    if (widget.episode.images.isEmpty) return;
    
    final currentIndex = viewManager.currentPage;
    final totalImages = widget.episode.images.length;
    
    // Preload next 2 images if not already loaded
    final nextIndex = currentIndex + 1;
    if (nextIndex < totalImages) {
      _preloadEpisodeImages(nextIndex);
    }
    
    // Preload previous image for better back navigation
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) {
      final prevImageUrl = widget.episode.images[prevIndex];
      if (!_preloadedImages.contains(prevImageUrl)) {
        ImageOptimization.preloadImage(prevImageUrl, context, type: 'episode_viewer');
        setState(() {
          _preloadedImages.add(prevImageUrl);
        });
      }
    }
  }

  /// Preload a single image with error handling
  Future<void> _preloadImage(String imageUrl) async {
    if (_preloadedImages.contains(imageUrl)) return;
    
    try {
      await ImageOptimization.preloadImage(imageUrl, context, type: 'episode_viewer');
      setState(() {
        _preloadedImages.add(imageUrl);
      });
    } catch (e) {
      print('Error preloading image $imageUrl: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = AppBar().preferredSize.height;

    return Scaffold(
      backgroundColor: _darkBackground,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: viewManager.isFullscreenMode
          ? null
          : AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_sharp),
        ),
        backgroundColor: _darkBackground,
        title: Text(
          widget.episode.title,
          style: TextStyle(
            color: _darkText,
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: _accentColor),
        actions: [
          IconButton(
            icon: Icon(
              viewManager.isFullscreenMode ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                viewManager.toggleFullscreenMode();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  viewManager.toggleFullscreenMode();
                });
              },
              child: Stack(
                children: [
                  // Add padding for non-fullscreen mode to prevent title bar overlap
                  Padding(
                    padding: viewManager.isFullscreenMode 
                        ? EdgeInsets.zero 
                        : EdgeInsets.only(top: topPadding + appBarHeight),
                    child: viewManager.isHorizontalMode
                        ? HorizontalEpisodeView(
                      controller: viewManager.horizontalPageController,
                      episode: widget.episode,
                      onPageChanged: (page) {
                        setState(() {
                          viewManager.currentPage = page;
                        });
                      },
                      viewManager: viewManager,
                      preloadedImages: _preloadedImages,
                      useLazyLoading: true,
                    )
                        : VerticalEpisodeView(
                      controller: viewManager.verticalScrollController,
                      episode: widget.episode,
                      nextEpisode: progressService.nextEpisode,
                      isLastEpisode: progressService.isLastEpisode,
                      currentPage: viewManager.currentPage,
                      onNextEpisodePressed: () {
                        if (progressService.nextEpisode != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EpisodeDetailScreen(
                                comic: widget.comic,
                                episode: progressService.nextEpisode!,
                              ),
                            ),
                          );
                        }
                      },
                      viewManager: viewManager,
                    ),
                  ),

                  if (!viewManager.isFullscreenMode)
                    EpisodeInteractionBar(
                      comicId: widget.comic.id,
                      episodeId: widget.episode.id,
                      isVisible: viewManager.isInteractionBarVisible,
                      onToggle: () {
                        setState(() {
                          viewManager.toggleInteractionBar();
                        });
                      },
                      animation: viewManager.interactionBarAnimation,
                      isLiked: progressService.isLiked,
                      onToggleLike: progressService.toggleEpisodeLike,
                      showComments: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withOpacity(0.4),
                          builder: (context) => CommentsBottomSheet(
                            comicId: widget.comic.id,
                            episodeId: widget.episode.id,
                          ),
                        );
                      },
                    ),

                  if (!viewManager.isFullscreenMode)
                    EpisodeControlBar(
                      isHorizontalMode: viewManager.isHorizontalMode,
                      currentPage: viewManager.currentPage,
                      totalPages: widget.episode.images.length,
                      scrollProgress: viewManager.scrollProgress,
                      onViewModeToggle: () {
                        // Reset zoom to ensure a consistent state when switching view modes.
                        //viewManager.resetZoom();
                        setState(() {
                          viewManager.isHorizontalMode = !viewManager.isHorizontalMode;
                        });
                        if (viewManager.isHorizontalMode) {
                          Future.delayed(Duration.zero, () {
                            if (viewManager.horizontalPageController.hasClients) {
                              viewManager.horizontalPageController.jumpToPage(viewManager.currentPage);
                            }
                          });
                        }
                      },
                      onPageChanged: (value) {
                        if (viewManager.isHorizontalMode) {
                          final page = value.toInt();
                          setState(() {
                            viewManager.currentPage = page;
                          });
                          viewManager.horizontalPageController.jumpToPage(page);
                        } else {
                          final targetOffset = (value / (widget.episode.images.length - 1)) *
                              viewManager.verticalScrollController.position.maxScrollExtent;
                          viewManager.verticalScrollController.jumpTo(targetOffset);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),

          if (viewManager.isFullscreenMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(top: topPadding + 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: EpisodeFullscreenOverlay(
                  title: widget.episode.title,
                  currentTime: _currentTime,
                  batteryLevel: _batteryLevel,
                  isCharging: _isCharging,
                  batteryIcon: _getBatteryIcon(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}