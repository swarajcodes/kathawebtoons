import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/image_optimization.dart';

class CacheMonitor extends StatefulWidget {
  final bool showInDebug;

  const CacheMonitor({
    Key? key,
    this.showInDebug = true,
  }) : super(key: key);

  @override
  State<CacheMonitor> createState() => _CacheMonitorState();
}

class _CacheMonitorState extends State<CacheMonitor> {
  Map<String, dynamic> _cacheStats = {};
  Map<String, Map<String, dynamic>> _performanceStats = {};
  List<String> _performanceIssues = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateStats();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _updateStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateStats() {
    if (mounted) {
      setState(() {
        _cacheStats = ImageOptimization.getCacheStats();
        _performanceStats = ImageOptimization.getPerformanceStats();
        _performanceIssues = ImageOptimization.getPerformanceIssues();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode if specified
    if (widget.showInDebug && !kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Performance Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // Cache Stats
            Text(
              'Cache:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            _buildStatRow('Hit Rate', '${((_cacheStats['hitRate'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
            _buildStatRow('Requests', '${_cacheStats['totalRequests'] ?? 0}'),
            _buildStatRow('Cached', '${_cacheStats['cachedItems'] ?? 0}'),
            
            const SizedBox(height: 4),
            
            // Performance Stats
            if (_performanceStats.isNotEmpty) ...[
              Text(
                'Performance:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ..._performanceStats.entries.take(3).map((entry) {
                final stats = entry.value;
                return _buildStatRow(
                  entry.key.split('_').last,
                  '${stats['average'] ?? 0}ms (${stats['count'] ?? 0})',
                );
              }),
            ],
            
            // Performance Issues
            if (_performanceIssues.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Issues:',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ..._performanceIssues.take(2).map((issue) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  '• ${issue.length > 30 ? '${issue.substring(0, 30)}...' : issue}',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 8,
                  ),
                ),
              )),
            ],
            
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  'Clear Old',
                  () async {
                    await ImageOptimization.clearOldCache();
                    _updateStats();
                  },
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  'Clear All',
                  () async {
                    await ImageOptimization.clearAllCache();
                    ImageOptimization.clearPerformanceStats();
                    _updateStats();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 