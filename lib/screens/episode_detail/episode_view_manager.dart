import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/episode_model.dart';

class EpisodeViewManager {
  final Episode episode;
  final TickerProvider vsync;

  bool isHorizontalMode = false;
  bool isFullscreenMode = false;
  bool isInteractionBarVisible = false;
  int currentPage = 0;
  double scrollProgress = 0.0;

  late PageController horizontalPageController;
  late ScrollController verticalScrollController;
  late AnimationController interactionBarController;
  late Animation<Offset> interactionBarAnimation;
  final TransformationController transformationController = TransformationController();
  double previousScale = 1.0;

  EpisodeViewManager({
    required this.episode,
    required this.vsync,
  }) {
    horizontalPageController = PageController();
    verticalScrollController = ScrollController();

    // Initialize interaction bar in hidden state
    isInteractionBarVisible = false;

    interactionBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    // Fix: Swap the begin and end values
    interactionBarAnimation = Tween<Offset>(
      begin: Offset.zero, // Visible position
      end: const Offset(1.5, 0.0), // Hidden position
    ).animate(CurvedAnimation(
      parent: interactionBarController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Set to 1.0 to start hidden (at the end of the tween)
    interactionBarController.value = 1.0;
  }

  void toggleFullscreenMode() {
    isFullscreenMode = !isFullscreenMode;
    if (isFullscreenMode) {
      // Enter fullscreen mode with system UI hidden
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      // Lock to portrait mode
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      // Exit fullscreen mode
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      // Restore portrait orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void toggleViewMode() {
    isHorizontalMode = !isHorizontalMode;
    if (isHorizontalMode && horizontalPageController.hasClients) {
      horizontalPageController.jumpToPage(currentPage);
    }
  }

  void toggleInteractionBar() {
    if (isInteractionBarVisible) {
      // Hide the bar - animate to hidden position (forward)
      interactionBarController.forward();
      isInteractionBarVisible = false;
    } else {
      // Show the bar - animate to visible position (reverse)
      interactionBarController.reverse();
      isInteractionBarVisible = true;
    }
  }

  void resetZoom() {
    transformationController.value = Matrix4.identity();
  }

  void dispose() {
    // Ensure we exit fullscreen mode when disposing
    if (isFullscreenMode) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    horizontalPageController.dispose();
    verticalScrollController.dispose();
    interactionBarController.dispose();
    transformationController.dispose();
  }
}
