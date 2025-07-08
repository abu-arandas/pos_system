import 'package:get/get.dart';
import 'logger_service.dart';

class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class PerformanceService extends GetxService {
  final LoggerService _logger = Get.find<LoggerService>();
  final Map<String, DateTime> _startTimes = {};
  final RxList<PerformanceMetrics> _metrics = <PerformanceMetrics>[].obs;

  // Performance thresholds (in milliseconds)
  static const int slowOperationThreshold = 1000;
  static const int criticalOperationThreshold = 3000;

  // Start timing an operation
  void startOperation(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }

  // End timing an operation and log performance
  void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      _logger.warning('Performance: No start time found for operation: $operationName');
      return;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    final metrics = PerformanceMetrics(
      operation: operationName,
      duration: duration,
      timestamp: endTime,
      metadata: metadata,
    );

    _metrics.add(metrics);
    _logPerformanceMetrics(metrics);

    // Clean up
    _startTimes.remove(operationName);

    // Keep only recent metrics (last 100)
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
  }

  // Time a synchronous operation
  T timeOperation<T>(String operationName, T Function() operation, {Map<String, dynamic>? metadata}) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName, metadata: metadata);
      return result;
    } catch (e) {
      endOperation(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  // Time an asynchronous operation
  Future<T> timeAsyncOperation<T>(String operationName, Future<T> Function() operation,
      {Map<String, dynamic>? metadata}) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName, metadata: metadata);
      return result;
    } catch (e) {
      endOperation(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  void _logPerformanceMetrics(PerformanceMetrics metrics) {
    final durationMs = metrics.duration.inMilliseconds;

    if (durationMs >= criticalOperationThreshold) {
      _logger.error(
        'CRITICAL PERFORMANCE: ${metrics.operation} took ${durationMs}ms',
        metadata: metrics.toMap(),
      );
    } else if (durationMs >= slowOperationThreshold) {
      _logger.warning(
        'SLOW OPERATION: ${metrics.operation} took ${durationMs}ms',
        metadata: metrics.toMap(),
      );
    } else {
      _logger.debug(
        'Performance: ${metrics.operation} completed in ${durationMs}ms',
        metadata: metrics.toMap(),
      );
    }
  }

  // Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_metrics.isEmpty) {
      return {
        'totalOperations': 0,
        'averageDuration': 0,
        'slowOperations': 0,
        'criticalOperations': 0,
      };
    }

    final durations = _metrics.map((m) => m.duration.inMilliseconds).toList();
    final totalOperations = durations.length;
    final averageDuration = durations.reduce((a, b) => a + b) / totalOperations;
    final slowOperations = durations.where((d) => d >= slowOperationThreshold).length;
    final criticalOperations = durations.where((d) => d >= criticalOperationThreshold).length;

    return {
      'totalOperations': totalOperations,
      'averageDuration': averageDuration.round(),
      'slowOperations': slowOperations,
      'criticalOperations': criticalOperations,
      'slowOperationRate': ((slowOperations / totalOperations) * 100).toStringAsFixed(1),
      'criticalOperationRate': ((criticalOperations / totalOperations) * 100).toStringAsFixed(1),
    };
  }

  // Get recent metrics
  List<PerformanceMetrics> getRecentMetrics({int limit = 50}) {
    return _metrics.reversed.take(limit).toList().reversed.toList();
  }

  // Get metrics for a specific operation
  List<PerformanceMetrics> getOperationMetrics(String operationName) {
    return _metrics.where((m) => m.operation == operationName).toList();
  }

  // Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final operationCounts = <String, int>{};
    final operationTotalTimes = <String, int>{};

    for (final metric in _metrics) {
      operationCounts[metric.operation] = (operationCounts[metric.operation] ?? 0) + 1;
      operationTotalTimes[metric.operation] =
          (operationTotalTimes[metric.operation] ?? 0) + metric.duration.inMilliseconds;
    }

    final operationStats = <String, Map<String, dynamic>>{};
    for (final operation in operationCounts.keys) {
      final count = operationCounts[operation]!;
      final totalTime = operationTotalTimes[operation]!;
      operationStats[operation] = {
        'count': count,
        'totalTime': totalTime,
        'avgTime': totalTime / count,
      };
    }

    return {
      'totalOperations': _metrics.length,
      'operations': operationStats,
      'metrics': _metrics.map((m) => m.toMap()).toList(),
    };
  }

  // Reset metrics
  void resetMetrics() {
    _metrics.clear();
    _logger.info('Performance metrics reset');
  }

  // Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _logger.info('Performance metrics cleared');
  }

  // Monitor memory usage (simplified)
  void logMemoryUsage(String context) {
    _logger.debug('Memory check: $context', metadata: {
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
