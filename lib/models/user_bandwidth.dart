import 'package:flutter/material.dart';
import 'dart:convert';

// Define PriorityLevel enum first
enum PriorityLevel { high, normal, low }

// Define TimeRestriction class
class TimeRestriction {
  bool enabled;
  List<int> allowedDays; // 0-6 (Sunday-Saturday)
  TimeOfDay startTime;
  TimeOfDay endTime;

  TimeRestriction({
    this.enabled = false,
    this.allowedDays = const [1, 2, 3, 4, 5], // Monday-Friday
    required this.startTime,
    required this.endTime,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'allowed_days': allowedDays,
      'start_hour': startTime.hour,
      'start_minute': startTime.minute,
      'end_hour': endTime.hour,
      'end_minute': endTime.minute,
    };
  }

  // Create from JSON
  factory TimeRestriction.fromJson(Map<String, dynamic> json) {
    return TimeRestriction(
      enabled: json['enabled'] ?? false,
      allowedDays: List<int>.from(json['allowed_days'] ?? [1, 2, 3, 4, 5]),
      startTime: TimeOfDay(
        hour: json['start_hour'] ?? 0,
        minute: json['start_minute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['end_hour'] ?? 23,
        minute: json['end_minute'] ?? 59,
      ),
    );
  }

  // Helper method to check if current time is within restriction
  bool isAllowedNow() {
    if (!enabled) return true;

    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Convert to 0-6 format (0 = Sunday)

    if (!allowedDays.contains(currentDay)) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // Get display string WITHOUT context (using 24-hour format)
  String getDisplayString() {
    if (!enabled) return 'No time restriction';

    final days = _formatDays(allowedDays);
    final start = _formatTimeOfDay(startTime);
    final end = _formatTimeOfDay(endTime);
    return '$days, $start - $end';
  }

  // Get display string WITH context (uses device locale)
  String getDisplayStringWithContext(BuildContext context) {
    if (!enabled) return 'No time restriction';

    final days = _formatDays(allowedDays);
    final start = startTime.format(context);
    final end = endTime.format(context);
    return '$days, $start - $end';
  }

  // Format TimeOfDay without context (24-hour format)
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(0)) {
      return 'Weekends';
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((d) => dayNames[d]).join(', ');
  }
}

// Main UserBandwidthControl class
class UserBandwidthControl {
  final String deviceId;
  final String deviceName;
  final String macAddress;
  int uploadLimit; // in Kbps
  int downloadLimit; // in Kbps
  bool isLimited;
  PriorityLevel priority;
  TimeRestriction? timeRestriction;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserBandwidthControl({
    required this.deviceId,
    required this.deviceName,
    required this.macAddress,
    this.uploadLimit = 0,
    this.downloadLimit = 0,
    this.isLimited = false,
    this.priority = PriorityLevel.normal,
    this.timeRestriction,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for database storage
  Map<String, dynamic> toJsonForDb() {
    return {
      'device_mac': macAddress,
      'device_name': deviceName,
      'upload_limit': uploadLimit,
      'download_limit': downloadLimit,
      'is_limited': isLimited ? 1 : 0,
      'priority': _priorityToString(priority),
      'time_restriction': timeRestriction != null
          ? jsonEncode(timeRestriction!.toJson())
          : null,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create from database map
  factory UserBandwidthControl.fromDb(Map<String, dynamic> map) {
    return UserBandwidthControl(
      deviceId: map['device_mac'] ?? '',
      deviceName: map['device_name'] ?? 'Unknown Device',
      macAddress: map['device_mac'] ?? '',
      uploadLimit: map['upload_limit'] ?? 0,
      downloadLimit: map['download_limit'] ?? 0,
      isLimited: (map['is_limited'] ?? 0) == 1,
      priority: _parsePriority(map['priority']),
      timeRestriction: map['time_restriction'] != null
          ? TimeRestriction.fromJson(jsonDecode(map['time_restriction']))
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'mac_address': macAddress,
      'upload_limit': uploadLimit,
      'download_limit': downloadLimit,
      'is_limited': isLimited,
      'priority': _priorityToString(priority),
      'time_restriction': timeRestriction?.toJson(),
    };
  }

  // Helper method to parse priority from string
  static PriorityLevel _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return PriorityLevel.high;
      case 'low':
        return PriorityLevel.low;
      case 'normal':
      default:
        return PriorityLevel.normal;
    }
  }

  // Helper method to convert priority to string
  static String _priorityToString(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.high:
        return 'high';
      case PriorityLevel.normal:
        return 'normal';
      case PriorityLevel.low:
        return 'low';
    }
  }

  // Get display name for priority
  String get priorityDisplayName {
    switch (priority) {
      case PriorityLevel.high:
        return 'High Priority';
      case PriorityLevel.normal:
        return 'Normal Priority';
      case PriorityLevel.low:
        return 'Low Priority';
    }
  }

  // Get color for priority
  Color get priorityColor {
    switch (priority) {
      case PriorityLevel.high:
        return Colors.green;
      case PriorityLevel.normal:
        return Colors.blue;
      case PriorityLevel.low:
        return Colors.orange;
    }
  }

  // Get icon for priority
  IconData get priorityIcon {
    switch (priority) {
      case PriorityLevel.high:
        return Icons.arrow_upward;
      case PriorityLevel.normal:
        return Icons.remove;
      case PriorityLevel.low:
        return Icons.arrow_downward;
    }
  }

  // Get formatted upload limit
  String get formattedUploadLimit {
    if (!isLimited || uploadLimit == 0) return 'Unlimited';
    return _formatSpeed(uploadLimit);
  }

  // Get formatted download limit
  String get formattedDownloadLimit {
    if (!isLimited || downloadLimit == 0) return 'Unlimited';
    return _formatSpeed(downloadLimit);
  }

  // Format speed in Kbps to human readable
  String _formatSpeed(int kbps) {
    if (kbps < 1024) return '$kbps Kbps';
    return '${(kbps / 1024).toStringAsFixed(1)} Mbps';
  }

  // Check if device has any restrictions
  bool get hasRestrictions => isLimited || (timeRestriction?.enabled ?? false);

  // Get summary string WITHOUT context
  String getSummary() {
    final List<String> parts = [];

    if (isLimited) {
      parts.add('DL: ${formattedDownloadLimit}');
      parts.add('UL: ${formattedUploadLimit}');
    }

    if (timeRestriction?.enabled ?? false) {
      parts.add('Time restricted');
    }

    if (parts.isEmpty) return 'No restrictions';
    return parts.join(' • ');
  }

  // Get detailed summary WITH context
  String getDetailedSummary(BuildContext context) {
    final List<String> parts = [];

    if (isLimited) {
      parts.add('Download: ${formattedDownloadLimit}');
      parts.add('Upload: ${formattedUploadLimit}');
    }

    if (timeRestriction?.enabled ?? false) {
      parts.add(timeRestriction!.getDisplayStringWithContext(context));
    }

    if (parts.isEmpty) return 'No bandwidth restrictions';
    return parts.join('\n');
  }
}

// Extension for better list operations
extension ListUtils on List<int> {
  bool containsAll(List<int> values) {
    for (var value in values) {
      if (!contains(value)) return false;
    }
    return true;
  }
}
