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

  // Single transformation controller for the entire document
  late TransformationController documentTransformationController;

  EpisodeViewManager({
    required this.episode,
    required this.vsync,
  }) {
    horizontalPageController = PageController();
    verticalScrollController = ScrollController();

    // Initialize single document-level transformation controller
    documentTransformationController = TransformationController();

    isInteractionBarVisible = false;

    interactionBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    interactionBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: interactionBarController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    interactionBarController.value = 1.0;
  }

  void resetDocumentZoom() {
    documentTransformationController.value = Matrix4.identity();
  }

  void toggleFullscreenMode() {
    isFullscreenMode = !isFullscreenMode;
    if (isFullscreenMode) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
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
      interactionBarController.forward();
      isInteractionBarVisible = false;
    } else {
      interactionBarController.reverse();
      isInteractionBarVisible = true;
    }
  }

  void dispose() {
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
    documentTransformationController.dispose();
  }
}