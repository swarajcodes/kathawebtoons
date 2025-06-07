import 'package:flutter/material.dart';

class EpisodeFullscreenOverlay extends StatelessWidget {
  final String title;
  final String currentTime;
  final int batteryLevel;
  final bool isCharging;
  final IconData batteryIcon;

  const EpisodeFullscreenOverlay({
    Key? key,
    required this.title,
    required this.currentTime,
    required this.batteryLevel,
    required this.isCharging,
    required this.batteryIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title - Left side (restored original styling)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF94CB34).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF506C1B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Time - Center (improved styling)
          Expanded(
            flex: 1,
            child: Text(
              currentTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Plus Jakarta Sans',
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Battery - Right side (keep the improved version)
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  batteryIcon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  "$batteryLevel%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                if (isCharging)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.bolt,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
