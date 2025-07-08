import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logger_service.dart';
import 'performance_service.dart';

enum ErrorSeverity { low, medium, high, critical }

class AppError {
  final String code;
  final String message;
  final String userMessage;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;

  AppError({
    required this.code,
    required this.message,
    required this.userMessage,
    this.severity = ErrorSeverity.medium,
    required this.timestamp,
    this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'userMessage': userMessage,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'stackTrace': stackTrace,
    };
  }
}

class ErrorHandlerService extends GetxService {
  final LoggerService _logger = Get.find<LoggerService>();
  final PerformanceService _performance = Get.find<PerformanceService>();

  // Error codes
  static const String networkError = 'NETWORK_ERROR';
  static const String authError = 'AUTH_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String permissionError = 'PERMISSION_ERROR';
  static const String dataError = 'DATA_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';

  // Handle different types of errors
  void handleError(
    dynamic error, {
    String? operation,
    Map<String, dynamic>? metadata,
    bool showSnackbar = true,
  }) {
    final appError = _categorizeError(error, operation, metadata);

    // Log the error
    _logger.error(
      appError.message,
      metadata: appError.toMap(),
      stackTrace: appError.stackTrace,
    );

    // Track performance impact if operation provided
    if (operation != null) {
      _performance.logMemoryUsage('Error occurred during $operation');
    }

    // Show user-friendly message
    if (showSnackbar) {
      _showErrorSnackbar(appError);
    }

    // Handle critical errors differently
    if (appError.severity == ErrorSeverity.critical) {
      _handleCriticalError(appError);
    }
  }

  AppError _categorizeError(dynamic error, String? operation, Map<String, dynamic>? metadata) {
    final timestamp = DateTime.now();
    final stackTrace = StackTrace.current.toString();

    if (error is Exception) {
      return _categorizeException(error, operation, metadata, timestamp, stackTrace);
    } else if (error is String) {
      return AppError(
        code: unknownError,
        message: error,
        userMessage: 'An error occurred: $error',
        timestamp: timestamp,
        metadata: metadata,
        stackTrace: stackTrace,
      );
    } else {
      return AppError(
        code: unknownError,
        message: error.toString(),
        userMessage: 'An unexpected error occurred. Please try again.',
        timestamp: timestamp,
        metadata: metadata,
        stackTrace: stackTrace,
      );
    }
  }

  AppError _categorizeException(
      Exception exception, String? operation, Map<String, dynamic>? metadata, DateTime timestamp, String stackTrace) {
    final exceptionString = exception.toString().toLowerCase();

    // Network related errors
    if (exceptionString.contains('network') ||
        exceptionString.contains('connection') ||
        exceptionString.contains('timeout') ||
        exceptionString.contains('socket')) {
      return AppError(
        code: networkError,
        message: 'Network error: ${exception.toString()}',
        userMessage: 'Connection problem. Please check your internet connection and try again.',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
        metadata: {...?metadata, 'operation': operation},
        stackTrace: stackTrace,
      );
    }

    // Authentication errors
    if (exceptionString.contains('auth') ||
        exceptionString.contains('permission') ||
        exceptionString.contains('unauthorized')) {
      return AppError(
        code: authError,
        message: 'Authentication error: ${exception.toString()}',
        userMessage: 'Authentication failed. Please sign in again.',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
        metadata: {...?metadata, 'operation': operation},
        stackTrace: stackTrace,
      );
    }

    // Validation errors
    if (exceptionString.contains('validation') ||
        exceptionString.contains('invalid') ||
        exceptionString.contains('format')) {
      return AppError(
        code: validationError,
        message: 'Validation error: ${exception.toString()}',
        userMessage: 'Please check your input and try again.',
        severity: ErrorSeverity.medium,
        timestamp: timestamp,
        metadata: {...?metadata, 'operation': operation},
        stackTrace: stackTrace,
      );
    }

    // Firestore/Database errors
    if (exceptionString.contains('firestore') ||
        exceptionString.contains('database') ||
        exceptionString.contains('firebase')) {
      return AppError(
        code: dataError,
        message: 'Database error: ${exception.toString()}',
        userMessage: 'Unable to save data. Please try again.',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
        metadata: {...?metadata, 'operation': operation},
        stackTrace: stackTrace,
      );
    }

    // Default case
    return AppError(
      code: unknownError,
      message: 'Unknown error: ${exception.toString()}',
      userMessage: 'An unexpected error occurred. Please try again.',
      severity: ErrorSeverity.medium,
      timestamp: timestamp,
      metadata: {...?metadata, 'operation': operation},
      stackTrace: stackTrace,
    );
  }

  void _showErrorSnackbar(AppError error) {
    Color backgroundColor;
    switch (error.severity) {
      case ErrorSeverity.critical:
        backgroundColor = Get.theme.colorScheme.error;
        break;
      case ErrorSeverity.high:
        backgroundColor = Get.theme.colorScheme.error.withOpacity(0.8);
        break;
      case ErrorSeverity.medium:
        backgroundColor = Get.theme.colorScheme.onError;
        break;
      case ErrorSeverity.low:
        backgroundColor = Get.theme.colorScheme.outline;
        break;
    }

    Get.snackbar(
      _getSeverityTitle(error.severity),
      error.userMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Get.theme.colorScheme.onError,
      duration: Duration(seconds: error.severity == ErrorSeverity.critical ? 10 : 5),
      isDismissible: true,
      margin: const EdgeInsets.all(16),
    );
  }

  String _getSeverityTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return 'Critical Error';
      case ErrorSeverity.high:
        return 'Error';
      case ErrorSeverity.medium:
        return 'Warning';
      case ErrorSeverity.low:
        return 'Info';
    }
  }

  void _handleCriticalError(AppError error) {
    // For critical errors, we might want to:
    // 1. Force logout
    // 2. Clear sensitive data
    // 3. Show a dialog instead of just a snackbar

    Get.dialog(
      AlertDialog(
        title: const Text('Critical Error'),
        content: Text(error.userMessage),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Optionally restart the app or navigate to a safe screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Convenience methods for common error types
  void handleNetworkError(String operation, {Map<String, dynamic>? metadata}) {
    handleError(
      Exception('Network connection failed'),
      operation: operation,
      metadata: metadata,
    );
  }

  void handleAuthError(String operation, {Map<String, dynamic>? metadata}) {
    handleError(
      Exception('Authentication failed'),
      operation: operation,
      metadata: metadata,
    );
  }

  void handleValidationError(String message, String operation, {Map<String, dynamic>? metadata}) {
    handleError(
      Exception('Validation failed: $message'),
      operation: operation,
      metadata: metadata,
    );
  }

  void handlePermissionError(String operation, {Map<String, dynamic>? metadata}) {
    handleError(
      Exception('Permission denied'),
      operation: operation,
      metadata: metadata,
    );
  }

  // Async operation wrapper with error handling
  Future<T?> safeAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
    bool showSnackbar = true,
  }) async {
    try {
      return await _performance.timeAsyncOperation(operationName, operation, metadata: metadata);
    } catch (error) {
      handleError(
        error,
        operation: operationName,
        metadata: metadata,
        showSnackbar: showSnackbar,
      );
      return null;
    }
  }

  // Sync operation wrapper with error handling
  T? safeOperation<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
    bool showSnackbar = true,
  }) {
    try {
      return _performance.timeOperation(operationName, operation, metadata: metadata);
    } catch (error) {
      handleError(
        error,
        operation: operationName,
        metadata: metadata,
        showSnackbar: showSnackbar,
      );
      return null;
    }
  }
}
