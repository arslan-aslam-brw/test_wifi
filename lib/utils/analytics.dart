import 'package:flutter/material.dart';
import 'package:test_wifi/utils/environment.dart';

class AnalyticsHelper {
  static void logEvent(String event, {Map<String, dynamic>? parameters}) {
    if (Environment.enableAnalytics) {
      // Implement your analytics integration here
      debugPrint('📊 Analytics: $event - $parameters');
    }
  }

  static void logError(String error, {StackTrace? stackTrace}) {
    if (Environment.enableAnalytics) {
      debugPrint('❌ Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}
