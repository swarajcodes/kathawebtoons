import 'dart:async';

import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../models/comic_model.dart' as comic_model;
import '../../models/episode_model.dart';
import '../../widgets/comments_bottom_sheet.dart';
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

    // Setup listeners
    viewManager.horizontalPageController.addListener(_handleHorizontalPageChange);
    viewManager.verticalScrollController.addListener(_handleVerticalScroll);
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
      }
    }
  }

  void _handleVerticalScroll() {
    if (viewManager.verticalScrollController.hasClients && !viewManager.isHorizontalMode) {
      double offset = viewManager.verticalScrollController.offset;
      double totalHeight = viewManager.verticalScrollController.position.maxScrollExtent;

      if (totalHeight > 0) {
        double progress = (offset / totalHeight).clamp(0.0, 1.0);

        setState(() {
          viewManager.scrollProgress = progress;
          viewManager.currentPage = (progress * (widget.episode.images.length - 1)).round();
        });

        if (progress > 0.8 && !progressService.hasMarkedAsRead) {
          progressService.markAsRead(percentage: progress);
        }
      }
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
    viewManager.dispose();
    progressService.dispose();
    _timer.cancel();
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: viewManager.isFullscreenMode
          ? null
          : AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_sharp),
        ),
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
            onPressed: viewManager.toggleFullscreenMode,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            if (!viewManager.isFullscreenMode) {
              viewManager.toggleFullscreenMode();
            }
          },
          child: Stack(
            children: [
              viewManager.isHorizontalMode
                  ? HorizontalEpisodeView(
                controller: viewManager.horizontalPageController,
                episode: widget.episode,
                onPageChanged: (page) {
                  setState(() {
                    viewManager.currentPage = page;
                  });
                },
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
              ),

              if (!viewManager.isFullscreenMode)
                EpisodeInteractionBar(
                  comicId: widget.comic.id,
                  episodeId: widget.episode.id,
                  isVisible: viewManager.isInteractionBarVisible,
                  onToggle: viewManager.toggleInteractionBar,
                  animation: viewManager.interactionBarAnimation,
                  isLiked: progressService.isLiked,
                  onToggleLike: progressService.toggleEpisodeLike,
                  showComments: () {
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
                  },
                ),

              if (!viewManager.isFullscreenMode)
                EpisodeControlBar(
                  isHorizontalMode: viewManager.isHorizontalMode,
                  currentPage: viewManager.currentPage,
                  totalPages: widget.episode.images.length,
                  scrollProgress: viewManager.scrollProgress,
                  onViewModeToggle: () {
                    viewManager.resetZoom();
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

              if (viewManager.isFullscreenMode)
                EpisodeFullscreenOverlay(
                  title: widget.episode.title,
                  currentTime: _currentTime,
                  batteryLevel: _batteryLevel,
                  isCharging: _isCharging,
                  batteryIcon: _getBatteryIcon(),
                ),

              if (viewManager.isFullscreenMode)
                Positioned(
                  left: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  right: 40,
                  child: GestureDetector(
                    onTap: viewManager.toggleFullscreenMode,
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
}