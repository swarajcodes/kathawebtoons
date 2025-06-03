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

    isInteractionBarVisible = false;

    interactionBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
      value: 0.0,
    );
    interactionBarAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: interactionBarController,
      curve: Curves.easeInOut,
    ));
  }

  void toggleFullscreenMode() {
    isFullscreenMode = !isFullscreenMode;
    if (isFullscreenMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void toggleViewMode() {
    isHorizontalMode = !isHorizontalMode;
    if (isHorizontalMode && horizontalPageController.hasClients) {
      horizontalPageController.jumpToPage(currentPage);
    }
  }

  void toggleInteractionBar() {
    isInteractionBarVisible = !isInteractionBarVisible;
    if (isInteractionBarVisible) {
      interactionBarController.forward();
    } else {
      interactionBarController.reverse();
    }
  }

  void resetZoom() {
    transformationController.value = Matrix4.identity();
  }

  void dispose() {
    horizontalPageController.dispose();
    verticalScrollController.dispose();
    interactionBarController.dispose();
    transformationController.dispose();
  }
}