import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/comic_model.dart';
import '../models/episode_model.dart';
import 'dart:async';

// Theme colors to match WebnovelEpisodeScreen
final Color _darkBackground = Color(0xFF1A1A1A);
final Color _darkText = Color(0xFFE0E0E0);
final Color _accentColor = Color(0xFF7CBA8B); // Light green accent
final Color _secondaryColor = Color(0xFF505050); // Gray for secondary elements

class EpisodeDetailScreen extends StatefulWidget {
  final Comic comic;
  final Episode episode;

  const EpisodeDetailScreen({
    Key? key,
    required this.comic,
    required this.episode,
  }) : super(key: key);

  @override
  _EpisodeDetailScreenState createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> {
  bool isHorizontalMode = false;
  bool isFullscreenMode = false;
  late PageController _horizontalPageController;
  late ScrollController _verticalScrollController;
  int _currentPage = 0;
  double _scrollProgress = 0.0;

  // Global zoom control for vertical mode
  final TransformationController _transformationController = TransformationController();
  double _previousScale = 1.0;

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
    _verticalScrollController = ScrollController();
    _updateTime();

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
        }
      }

    });

    _verticalScrollController.addListener(() {
      if (_verticalScrollController.hasClients && !isHorizontalMode) {
        double offset = _verticalScrollController.offset;
        double totalHeight = _verticalScrollController.position.maxScrollExtent;

        print("Scroll Offset: $offset, Max Scroll Extent: $totalHeight");

        if (totalHeight > 0) {
          double progress = (offset / totalHeight).clamp(0.0, 1.0);

          setState(() {
            _scrollProgress = progress;
            _currentPage = (progress * (widget.episode.images.length - 1)).round();
          });

          print("Scroll Progress: $_scrollProgress, Current Page: $_currentPage");
        }
      }
    });


  }

  Future<void> _initBattery() async {
    // Get initial battery level
    final batteryLevel = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = batteryLevel;
    });

    // Listen for battery state changes (charging/discharging)
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() {
        _isCharging = state == BatteryState.charging;
      });
      // Also update battery level when state changes
      _updateBatteryLevel();
    });

    // Set up periodic battery level updates
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
    _timer.cancel();
    _batteryStateSubscription.cancel();

    // Ensure we restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Handle double tap to reset zoom or zoom to a specific level
  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.1) {
      // Reset zoom if already zoomed in
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom to 2.0x if not zoomed in
      final newMatrix = Matrix4.identity()..scale(2.0);
      _transformationController.value = newMatrix;
    }
  }

  void _toggleFullscreenMode() {
    setState(() {
      isFullscreenMode = !isFullscreenMode;
    });

    if (isFullscreenMode) {
      // Hide status bar and navigation in fullscreen mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Show status bar and navigation when exiting fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: isFullscreenMode
          ? null
          : AppBar(
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
          // Fullscreen button
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: _toggleFullscreenMode,
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleFullscreenMode,
          child: Stack(
            children: [
              isHorizontalMode
                  ? _buildHorizontalView()
                  : _buildSynchronizedVerticalView(),
              if (!isFullscreenMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20, // Raised above the bottom edge
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                            _resetZoom(); // Reset zoom when switching modes
                            setState(() {
                              isHorizontalMode = !isHorizontalMode;
                            });

                            // Handle mode switch with proper position
                            if (isHorizontalMode) {
                              // Switching to horizontal: set page based on scroll progress
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
              // Fullscreen top overlay (episode title, time, and battery)
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
                          // Episode title - with dark gray color
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
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Time display
                          Text(
                            _currentTime,
                            style: TextStyle(
                              color: _secondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Battery percentage - with dark gray color and charging indicator
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
              // Exit fullscreen button when in fullscreen mode
              if (isFullscreenMode)
                Positioned(
                  left: 20,
                  bottom: 20,
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
      )
    );
  }

  // Helper method to get appropriate battery icon based on level and charging state
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

  // New synchronized vertical view with InteractiveViewer
  Widget _buildSynchronizedVerticalView() {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: widget.episode.images.length,
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.episode.images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: "page_${widget.episode.id}_$index"),
        );
      },
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
          _scrollProgress = index / (widget.episode.images.length - 1);
        });
      },
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          value: event == null ? 0 : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          color: Colors.lightGreenAccent,
        ),
      ),
      backgroundDecoration: BoxDecoration(color: _darkBackground),
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
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
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
          ),
        );
      },
    );
  }
}