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
    return Positioned(
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
              const Color(0xFF1A1A1A).withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA3D749).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFA3D749),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currentTime,
                style: const TextStyle(
                  color: Color(0xFF505050),
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(
                    batteryIcon,
                    color: const Color(0xFF505050),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$batteryLevel%",
                    style: const TextStyle(
                      color: Color(0xFF505050),
                      fontSize: 14,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  if (isCharging)
                    const Padding(
                      padding: EdgeInsets.only(left: 2.0),
                      child: Icon(
                        Icons.bolt,
                        color: Color(0xFF505050),
                        size: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}