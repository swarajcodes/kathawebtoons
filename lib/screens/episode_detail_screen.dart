import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/episode_model.dart';
import '../models/comic_model.dart' as comic_model;
import 'dart:async';
import '../services/reading_progress_service.dart';
import '../services/comments_service.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../models/episode_stats_model.dart';

// Theme colors to match WebnovelEpisodeScreen
final Color _darkBackground = Color(0xFF1A1A1A);
final Color _darkText = Color(0xFFE0E0E0);
final Color _accentColor = Color(0xFFA3D749); // Light green accent
final Color _secondaryColor = Color(0xFF505050); // Gray for secondary elements
final String _fontFamily = 'Plus Jakarta Sans'; // Add font family variable

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
  bool isHorizontalMode = false;
  bool isFullscreenMode = false;
  late PageController _horizontalPageController;
  late PageController _verticalScrollController;
  int _currentPage = 0;
  double _scrollProgress = 0.0;
  List<Episode> _episodes = [];
  bool _isLoadingEpisodes = true;
  Episode? _nextEpisode;
  bool _isLastEpisode = false;
  final ReadingProgressService _progressService = ReadingProgressService();
  bool _hasMarkedAsRead = false;

  // Add these new variables for comments and likes
  final CommentsService _commentsService = CommentsService();
  bool _isLiked = false;
  EpisodeStats? _episodeStats;

  // Animation for vertical interaction bar
  late AnimationController _interactionBarController;
  late Animation<Offset> _interactionBarAnimation;
  bool _isInteractionBarVisible = false;

  // Global zoom control for vertical mode
  final TransformationController _transformationController = TransformationController();
  double _previousScale = 1.0;

  Future<void> _checkReadStatus() async {
    final isRead = await _progressService.isEpisodeRead(
      widget.comic.id,
      widget.episode.id,
    );

    if (mounted) {
      setState(() {
        _hasMarkedAsRead = isRead;
      });
    }
  }

  Future<void> _markAsRead({double percentage = 1.0}) async {
    if (_hasMarkedAsRead) return;

    await _progressService.markEpisodeAsRead(
      widget.comic.id,
      widget.episode.id,
      percentage: percentage,
    );

    setState(() {
      _hasMarkedAsRead = true;
    });
  }

  Future<void> _loadEpisodeInteractionData() async {
    try {
      // First, recalculate stats to ensure accuracy
      await _commentsService.recalculateEpisodeStats(
        comicId: widget.comic.id,
        episodeId: widget.episode.id,
      );

      // Then initialize episode stats if they don't exist
      await _commentsService.initializeEpisodeStats(
        comicId: widget.comic.id,
        episodeId: widget.episode.id,
      );

      // Check if episode is liked
      final isLiked = await _commentsService.hasUserLiked(
        comicId: widget.comic.id,
        episodeId: widget.episode.id,
        targetId: widget.episode.id,
      );

      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }

      print('Episode interaction data loaded successfully');
    } catch (e) {
      print('Error loading episode interaction data: $e');
    }
  }

  Future<void> _toggleEpisodeLike() async {
    try {
      print('Toggling like for episode: ${widget.episode.id}');
      await _commentsService.toggleEpisodeLike(
        comicId: widget.comic.id,
        episodeId: widget.episode.id,
      );

      setState(() {
        _isLiked = !_isLiked;
      });

      print('Episode like toggled successfully');
    } catch (e) {
      print('Error toggling episode like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => CommentsBottomSheet(
        comicId: widget.comic.id,
        episodeId: widget.episode.id,
      ),
    );
  }

  void _toggleInteractionBar() {
    setState(() {
      _isInteractionBarVisible = !_isInteractionBarVisible;
    });

    if (_isInteractionBarVisible) {
      _interactionBarController.forward();
    } else {
      _interactionBarController.reverse();
    }
  }

  // Battery implementation
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  bool _isCharging = false;

  // Time display
  String _currentTime = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _horizontalPageController = PageController();
    _verticalScrollController = PageController();
    _updateTime();
    _fetchEpisodes();
    _checkReadStatus();
    _loadEpisodeInteractionData();

    // Initialize animation controller for interaction bar
    _interactionBarController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _interactionBarAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0), // Start from right (hidden)
      end: Offset(0.0, 0.0),   // End at normal position (visible)
    ).animate(CurvedAnimation(
      parent: _interactionBarController,
      curve: Curves.easeInOut,
    ));

    // Initialize battery
    _initBattery();

    // Update time every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());

    // Add listeners for page changes
    _horizontalPageController.addListener(() {
      if (_horizontalPageController.hasClients && isHorizontalMode) {
        final page = _horizontalPageController.page?.round() ?? 0;
        if (page != _currentPage) {
          setState(() {
            _currentPage = page;
          });

          double progress = (page + 1) / widget.episode.images.length;
          setState(() {
            _scrollProgress = progress;
          });

          if (progress > 0.8 && !_hasMarkedAsRead) {
            _markAsRead(percentage: progress);
          }
        }
      }
    });

    _verticalScrollController.addListener(() {
      if (_verticalScrollController.hasClients && !isHorizontalMode) {
        double offset = _verticalScrollController.offset;
        double totalHeight = _verticalScrollController.position.maxScrollExtent;

        if (totalHeight > 0) {
          double progress = (offset / totalHeight).clamp(0.0, 1.0);

          setState(() {
            _scrollProgress = progress;
            _currentPage = (progress * (widget.episode.images.length - 1)).round();
          });

          if (progress > 0.8 && !_hasMarkedAsRead) {
            _markAsRead(percentage: progress);
          }
        }
      }
    });
  }

  Future<void> _fetchEpisodes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comics')
          .doc(widget.comic.id)
          .collection('episodes')
          .orderBy('number', descending: false)
          .get();

      final episodes = snapshot.docs.map((doc) {
        return Episode.fromFirestore(doc);
      }).toList();

      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
        final currentIndex = episodes.indexWhere((e) => e.id == widget.episode.id);
        if (currentIndex != -1) {
          final currentEpisodeNumber = widget.episode.number;
          final hasNextEpisode = episodes.any((e) => e.number > currentEpisodeNumber);

          _isLastEpisode = !hasNextEpisode;
          if (hasNextEpisode) {
            _nextEpisode = episodes.firstWhere(
                  (e) => e.number > currentEpisodeNumber,
              orElse: () => episodes[currentIndex + 1],
            );
          } else {
            _nextEpisode = null;
          }
        }
      });
    } catch (e) {
      print("Error fetching episodes: $e");
      setState(() {
        _isLoadingEpisodes = false;
        _isLastEpisode = true;
        _nextEpisode = null;
      });
    }
  }

  Future<void> _initBattery() async {
    final batteryLevel = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = batteryLevel;
    });

    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() {
        _isCharging = state == BatteryState.charging;
      });
      _updateBatteryLevel();
    });

    Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateBatteryLevel();
    });
  }

  Future<void> _updateBatteryLevel() async {
    final batteryLevel = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = batteryLevel;
    });
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

  @override
  void dispose() {
    _horizontalPageController.dispose();
    _verticalScrollController.dispose();
    _transformationController.dispose();
    _interactionBarController.dispose();
    _timer.cancel();
    _batteryStateSubscription.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullscreenMode() {
    setState(() {
      isFullscreenMode = !isFullscreenMode;
    });

    if (isFullscreenMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Widget _buildVerticalInteractionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? countText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            if (countText != null && countText.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                countText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: isFullscreenMode
          ? null
          : AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_sharp)),
        backgroundColor: Colors.transparent,
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
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: _toggleFullscreenMode,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            if (!isFullscreenMode) {
              _toggleFullscreenMode();
            }
          },
          child: Stack(
            children: [
              isHorizontalMode
                  ? _buildHorizontalView()
                  : _buildSynchronizedVerticalView(),

              // Vertical Interaction Bar (Right Side) - Matching Figma Design
              if (!isFullscreenMode)
                Positioned(
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.3,
                  bottom: MediaQuery.of(context).size.height * 0.3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Sliding Interaction Panel with FIXED overflow
                      SlideTransition(
                        position: _interactionBarAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: 65,
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.4, // Add max height constraint
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView( // Add scrollable container
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // FIXED: Use min instead of max
                                  mainAxisAlignment: MainAxisAlignment.center, // FIXED: Use center instead of spaceEvenly
                                  children: [
                                    SizedBox(height: 12), // Add fixed spacing

                                    // Like Button
                                    StreamBuilder<EpisodeStats?>(
                                      stream: _commentsService.getEpisodeStats(
                                        comicId: widget.comic.id,
                                        episodeId: widget.episode.id,
                                      ),
                                      builder: (context, snapshot) {
                                        final likes = snapshot.data?.totalLikes ?? 0;
                                        return _buildGlassmorphicInteractionButton(
                                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: _isLiked ? Colors.red : Colors.white,
                                          onTap: _toggleEpisodeLike,
                                          countText: likes.toString(),
                                        );
                                      },
                                    ),

                                    SizedBox(height: 16), // Fixed spacing between buttons

                                    // Comments Button
                                    StreamBuilder<EpisodeStats?>(
                                      stream: _commentsService.getEpisodeStats(
                                        comicId: widget.comic.id,
                                        episodeId: widget.episode.id,
                                      ),
                                      builder: (context, snapshot) {
                                        final comments = snapshot.data?.totalComments ?? 0;
                                        return _buildGlassmorphicInteractionButton(
                                          icon: Icons.chat_bubble_outline,
                                          color: Colors.white,
                                          onTap: _showComments,
                                          countText: comments.toString(),
                                        );
                                      },
                                    ),

                                    SizedBox(height: 16), // Fixed spacing between buttons

                                    // Share Button
                                    _buildGlassmorphicInteractionButton(
                                      icon: Icons.share,
                                      color: Colors.white,
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Share functionality coming soon!'),
                                            backgroundColor: Color(0xFFA3D749),
                                          ),
                                        );
                                      },
                                    ),

                                    SizedBox(height: 12), // Add bottom spacing
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Square Toggle Button - Always stays on the right
                      GestureDetector(
                        onTap: _toggleInteractionBar,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 35,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedRotation(
                                  turns: _isInteractionBarVisible ? 0.5 : 0.0,
                                  duration: Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Control Bar (Existing)
              if (!isFullscreenMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _secondaryColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Page counter
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            "${_currentPage + 1}/${widget.episode.images.length}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: _fontFamily,
                            ),
                          ),
                        ),
                        // Scroll progress bar
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: Colors.lightGreenAccent,
                                inactiveTrackColor: Colors.grey.shade600,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: isHorizontalMode
                                    ? _currentPage.toDouble()
                                    : _scrollProgress * (widget.episode.images.length - 1),
                                min: 0,
                                max: (widget.episode.images.length - 1).toDouble(),
                                divisions: widget.episode.images.length > 1 ? widget.episode.images.length - 1 : 1,
                                onChanged: (value) {
                                  if (isHorizontalMode) {
                                    final page = value.toInt();
                                    setState(() {
                                      _currentPage = page;
                                    });
                                    _horizontalPageController.jumpToPage(page);
                                  } else {
                                    final targetOffset = (value / (widget.episode.images.length - 1)) *
                                        _verticalScrollController.position.maxScrollExtent;
                                    _verticalScrollController.jumpTo(targetOffset);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        // View mode toggle
                        IconButton(
                          icon: Icon(
                            isHorizontalMode ? Icons.view_day : Icons.view_carousel,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _resetZoom();
                            setState(() {
                              isHorizontalMode = !isHorizontalMode;
                            });
                            if (isHorizontalMode) {
                              Future.delayed(Duration.zero, () {
                                if (_horizontalPageController.hasClients) {
                                  _horizontalPageController.jumpToPage(_currentPage);
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Fullscreen top overlay
              if (isFullscreenMode)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _darkBackground.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.episode.title,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: _fontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _currentTime,
                            style: TextStyle(
                              color: _secondaryColor,
                              fontSize: 14,
                              fontFamily: _fontFamily,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              Icon(
                                _getBatteryIcon(),
                                color: _secondaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$_batteryLevel%",
                                style: TextStyle(
                                  color: _secondaryColor,
                                  fontSize: 14,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                              if (_isCharging)
                                Padding(
                                  padding: const EdgeInsets.only(left: 2.0),
                                  child: Icon(
                                    Icons.bolt,
                                    color: _secondaryColor,
                                    size: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Exit fullscreen button
              if (isFullscreenMode)
                Positioned(
                  left: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  right: 40,
                  child: GestureDetector(
                    onTap: _toggleFullscreenMode,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fullscreen_exit,
                        color: _accentColor,
                        size: 40,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildSynchronizedVerticalView() {
    return Stack(
      children: [
        ListView.builder(
          controller: _verticalScrollController,
          itemCount: widget.episode.images.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.episode.images.length) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
              );
            }
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width,
              child: Hero(
                tag: "page_${widget.episode.id}_$index",
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(widget.episode.images[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  initialScale: PhotoViewComputedScale.contained,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  loadingBuilder: (context, event) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ),
                  tightMode: true,
                  gaplessPlayback: true,
                  enableRotation: false,
                  filterQuality: FilterQuality.high,
                  gestureDetectorBehavior: HitTestBehavior.opaque,
                ),
              ),
            );
          },
        ),
        if (_nextEpisode != null && !_isLastEpisode && _currentPage == widget.episode.images.length - 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EpisodeDetailScreen(
                        comic: widget.comic,
                        episode: _nextEpisode!,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next Chapter',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: _fontFamily,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassmorphicInteractionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? countText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          // Subtle glassmorphic effect for buttons
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            // FIXED: Always show count container, even if count is 0
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countText ?? '0', // Show '0' if countText is null
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHorizontalView() {
    return PageView.builder(
      controller: _horizontalPageController,
      itemCount: widget.episode.images.length,
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Hero(
          tag: "page_${widget.episode.id}_$index",
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(widget.episode.images[index]),
            minScale: PhotoViewComputedScale.covered * 0.8,
            maxScale: PhotoViewComputedScale.covered * 4,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.lightGreenAccent,
                ),
              ),
            ),
            tightMode: true,
            gaplessPlayback: true,
            enableRotation: false,
            filterQuality: FilterQuality.high,
            gestureDetectorBehavior: HitTestBehavior.opaque,
            basePosition: Alignment.center,
          ),
        );
      },
    );
  }
}
