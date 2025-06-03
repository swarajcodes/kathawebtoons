import 'package:flutter/material.dart';

class EpisodeControlBar extends StatelessWidget {
  final bool isHorizontalMode;
  final int currentPage;
  final int totalPages;
  final double scrollProgress;
  final VoidCallback onViewModeToggle;
  final Function(double) onPageChanged;

  const EpisodeControlBar({
    Key? key,
    required this.isHorizontalMode,
    required this.currentPage,
    required this.totalPages,
    required this.scrollProgress,
    required this.onViewModeToggle,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 20,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF505050).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                "${currentPage + 1}/$totalPages",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.lightGreenAccent,
                    inactiveTrackColor: Colors.grey.shade600,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: isHorizontalMode
                        ? currentPage.toDouble()
                        : scrollProgress * (totalPages - 1),
                    min: 0,
                    max: (totalPages - 1).toDouble(),
                    divisions: totalPages > 1 ? totalPages - 1 : 1,
                    onChanged: onPageChanged,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isHorizontalMode ? Icons.view_day : Icons.view_carousel,
                color: Colors.white,
              ),
              onPressed: onViewModeToggle,
            ),
          ],
        ),
      ),
    );
  }
}