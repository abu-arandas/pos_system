import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class JsonExportService {
  /// Export demo data as properly formatted JSON string
  static String exportAsJson(Map<String, dynamic> data) {
    try {
      // Create a JSON encoder with indentation for readability
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      throw Exception('Failed to export data as JSON: $e');
    }
  }

  /// Copy JSON data to clipboard
  static Future<void> copyToClipboard(String jsonData) async {
    try {
      await Clipboard.setData(ClipboardData(text: jsonData));
      Get.snackbar(
        'Success',
        'JSON data copied to clipboard!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to copy to clipboard: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Convert Firebase Timestamp objects to ISO strings for JSON export
  static Map<String, dynamic> sanitizeForJson(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is DateTime) {
        sanitized[key] = value.toIso8601String();
      } else if (value is Map) {
        sanitized[key] = sanitizeForJson(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map) {
            return sanitizeForJson(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Get demo data statistics in a readable format
  static Map<String, dynamic> getStatisticsForExport(Map<String, dynamic> stats) {
    return {
      'summary': {
        'total_users': stats['users']['total'],
        'total_stores': stats['stores']['total'],
        'total_products': stats['products']['total'],
        'total_transactions': stats['transactions']['total'],
        'total_revenue': stats['transactions']['totalRevenue'],
      },
      'user_breakdown': {
        'admins': stats['users']['admins'],
        'managers': stats['users']['managers'],
        'cashiers': stats['users']['cashiers'],
      },
      'product_breakdown': {
        'simple_products': stats['products']['simple'],
        'variable_products': stats['products']['variable'],
        'service_products': stats['products']['service'],
        'total_inventory': stats['products']['totalStock'],
        'low_stock_items': stats['products']['lowStock'],
      },
      'transaction_breakdown': {
        'completed': stats['transactions']['completed'],
        'pending': stats['transactions']['pending'],
        'refunded': stats['transactions']['refunded'],
      },
      'store_breakdown': {
        'active_stores': stats['stores']['active'],
      },
    };
  }
}
