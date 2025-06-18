import 'dart:async';
import 'dart:developer' as developer;

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<Duration>> _measurements = {};
  final Map<String, int> _errorCounts = {};

  /// Starts timing an operation
  void startTimer(String operationName) {
    _activeTimers[operationName] = Stopwatch()..start();
  }

  /// Ends timing an operation and records the duration
  void endTimer(String operationName) {
    final stopwatch = _activeTimers[operationName];
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsed;
      
      if (!_measurements.containsKey(operationName)) {
        _measurements[operationName] = [];
      }
      _measurements[operationName]!.add(duration);
      
      _activeTimers.remove(operationName);
      
      // Log slow operations
      if (duration.inMilliseconds > 1000) {
        developer.log(
          'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
          name: 'PerformanceMonitor',
          level: 900, // Warning level
        );
      }
    }
  }

  /// Records an error for an operation
  void recordError(String operationName, String error) {
    _errorCounts[operationName] = (_errorCounts[operationName] ?? 0) + 1;
    developer.log(
      'Error in $operationName: $error',
      name: 'PerformanceMonitor',
      level: 1000, // Error level
    );
  }

  /// Gets performance statistics for an operation
  Map<String, dynamic> getOperationStats(String operationName) {
    final measurements = _measurements[operationName] ?? [];
    if (measurements.isEmpty) {
      return {
        'count': 0,
        'average': 0,
        'min': 0,
        'max': 0,
        'errors': _errorCounts[operationName] ?? 0,
      };
    }

    final total = measurements.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
    
    final average = total.inMilliseconds / measurements.length;
    final min = measurements.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final max = measurements.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    return {
      'count': measurements.length,
      'average': average.round(),
      'min': min,
      'max': max,
      'errors': _errorCounts[operationName] ?? 0,
    };
  }

  /// Gets all performance statistics
  Map<String, Map<String, dynamic>> getAllStats() {
    final allStats = <String, Map<String, dynamic>>{};
    final allOperations = <String>{};
    
    allOperations.addAll(_measurements.keys);
    allOperations.addAll(_errorCounts.keys);
    
    for (final operation in allOperations) {
      allStats[operation] = getOperationStats(operation);
    }
    
    return allStats;
  }

  /// Clears all performance data
  void clearStats() {
    _measurements.clear();
    _errorCounts.clear();
    _activeTimers.clear();
  }

  /// Gets a summary of performance issues
  List<String> getPerformanceIssues() {
    final issues = <String>[];
    
    for (final entry in _measurements.entries) {
      final operationName = entry.key;
      final measurements = entry.value;
      final errorCount = _errorCounts[operationName] ?? 0;
      
      if (measurements.isNotEmpty) {
        final average = measurements.fold<int>(0, (sum, d) => sum + d.inMilliseconds) / measurements.length;
        
        if (average > 2000) { // More than 2 seconds average
          issues.add('$operationName is slow (avg: ${average.round()}ms)');
        }
        
        if (errorCount > 0) {
          issues.add('$operationName has $errorCount errors');
        }
      }
    }
    
    return issues;
  }

  /// Wraps an async operation with performance monitoring
  Future<T> monitorOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      recordError(operationName, e.toString());
      endTimer(operationName);
      rethrow;
    }
  }

  /// Wraps a sync operation with performance monitoring
  T monitorSyncOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    startTimer(operationName);
    try {
      final result = operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      recordError(operationName, e.toString());
      endTimer(operationName);
      rethrow;
    }
  }
} 