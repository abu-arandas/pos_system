import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'security_service.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? userId;
  final String? businessId;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.userId,
    this.businessId,
    this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'level': level.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'businessId': businessId,
      'metadata': metadata,
      'stackTrace': stackTrace,
    };
  }
}

class LoggerService extends GetxService {
  static const String _collectionName = 'app_logs';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory log buffer for offline scenarios
  final List<LogEntry> _logBuffer = [];
  final int _maxBufferSize = 100;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Flush any buffered logs when service initializes
    await _flushLogs();
  }

  // Public logging methods
  void debug(String message, {Map<String, dynamic>? metadata}) {
    _log(message, LogLevel.debug, metadata: metadata);
  }

  void info(String message, {Map<String, dynamic>? metadata}) {
    _log(message, LogLevel.info, metadata: metadata);
  }

  void warning(String message, {Map<String, dynamic>? metadata}) {
    _log(message, LogLevel.warning, metadata: metadata);
  }

  void error(String message, {Map<String, dynamic>? metadata, String? stackTrace}) {
    _log(message, LogLevel.error, metadata: metadata, stackTrace: stackTrace);
  }

  // Log exceptions with stack trace
  void logException(Exception exception, StackTrace stackTrace, {Map<String, dynamic>? metadata}) {
    error(
      'Exception: ${exception.toString()}',
      metadata: {
        'exceptionType': exception.runtimeType.toString(),
        ...?metadata,
      },
      stackTrace: stackTrace.toString(),
    );
  }

  // Core logging method
  void _log(String message, LogLevel level, {Map<String, dynamic>? metadata, String? stackTrace}) {
    final logEntry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      userId: _getCurrentUserId(),
      businessId: _getCurrentBusinessId(),
      metadata: metadata,
      stackTrace: stackTrace,
    );

    // Always add to buffer first
    _addToBuffer(logEntry);

    // Try to send to Firebase immediately for important logs
    if (level == LogLevel.error || level == LogLevel.warning) {
      _sendToFirebase(logEntry);
    }

    // Print to console in debug mode
    if (Get.isLogEnable) {
      _printToConsole(logEntry);
    }
  }

  void _addToBuffer(LogEntry logEntry) {
    _logBuffer.add(logEntry);

    // Maintain buffer size limit
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  Future<void> _sendToFirebase(LogEntry logEntry) async {
    try {
      await _firestore.collection(_collectionName).add(logEntry.toMap());
    } catch (e) {
      // If Firebase logging fails, just print to console
      if (Get.isLogEnable) {
        print('Failed to send log to Firebase: $e');
      }
    }
  }

  Future<void> _flushLogs() async {
    if (_logBuffer.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final logsToFlush = List<LogEntry>.from(_logBuffer);

      for (final logEntry in logsToFlush) {
        final docRef = _firestore.collection(_collectionName).doc();
        batch.set(docRef, logEntry.toMap());
      }

      await batch.commit();
      _logBuffer.clear();

      if (Get.isLogEnable) {
        print('Flushed ${logsToFlush.length} logs to Firebase');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        print('Failed to flush logs to Firebase: $e');
      }
    }
  }

  void _printToConsole(LogEntry logEntry) {
    final levelIcon = {
          LogLevel.debug: '🐛',
          LogLevel.info: 'ℹ️',
          LogLevel.warning: '⚠️',
          LogLevel.error: '❌',
        }[logEntry.level] ??
        '';

    final timestamp = logEntry.timestamp.toString().substring(11, 19);
    print('$levelIcon [$timestamp] ${logEntry.level.name.toUpperCase()}: ${logEntry.message}');

    if (logEntry.metadata != null) {
      print('   Metadata: ${logEntry.metadata}');
    }

    if (logEntry.stackTrace != null) {
      print('   Stack Trace: ${logEntry.stackTrace}');
    }
  }

  String? _getCurrentUserId() {
    try {
      return Get.find<SecurityService>().currentUserId;
    } catch (e) {
      return null;
    }
  }

  String? _getCurrentBusinessId() {
    try {
      return Get.find<SecurityService>().currentBusinessId;
    } catch (e) {
      return null;
    }
  }

  // Public method to manually flush logs
  Future<void> flushLogs() async {
    await _flushLogs();
  }

  // Get recent logs for debugging
  List<LogEntry> getRecentLogs({int limit = 50}) {
    final recentLogs = _logBuffer.reversed.take(limit).toList();
    return recentLogs.reversed.toList();
  }

  // Clear logs (for testing or maintenance)
  void clearLogs() {
    _logBuffer.clear();
  }
}
