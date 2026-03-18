import 'dart:convert';
import 'dart:ui';
import 'package:crypto/crypto.dart';

class Helpers {
  // Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // Format duration in seconds to readable string
  static String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '$days d $hours h';
    } else if (hours > 0) {
      return '$hours h $minutes m';
    } else {
      return '$minutes m';
    }
  }

  // Format date to relative time
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Encode password (Base64)
  static String encodePassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  // Calculate signal bars from RSSI
  static int calculateSignalBars(int rssi) {
    if (rssi >= -70) return 4;
    if (rssi >= -80) return 3;
    if (rssi >= -90) return 2;
    if (rssi >= -100) return 1;
    return 0;
  }

  // Validate IP address
  static bool isValidIp(String ip) {
    final RegExp ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  // Validate MAC address
  static bool isValidMac(String mac) {
    final RegExp macRegex = RegExp(
      r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
    );
    return macRegex.hasMatch(mac);
  }

  // Generate random color from string
  static Color colorFromString(String str) {
    int hash = str.codeUnits.fold(0, (prev, element) => prev + element);
    return Color((hash * 0xFFFFFF) % 0xFFFFFF).withOpacity(1.0);
  }
}
