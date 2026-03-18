import 'package:flutter/material.dart';
import 'dart:convert';

// Define FilterType enum first
enum FilterType {
  strict, // Block all inappropriate content
  moderate, // Block moderate content
  custom, // Custom user-defined filters
  none, // No filtering
  youtubeRestricted, // Special case for YouTube
}

class ParentalControlRule {
  final String id;
  final String deviceId;
  final String deviceName;
  final String childName;
  final List<ScheduleRule> schedules;
  final List<ContentFilter> contentFilters;
  final bool enabled;
  final DateTime? expiryDate;
  DateTime? createdAt;
  DateTime? updatedAt;

  ParentalControlRule({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.childName,
    this.schedules = const [],
    this.contentFilters = const [],
    this.enabled = true,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJsonForDb() {
    return {
      'id': id,
      'device_mac': deviceId,
      'device_name': deviceName,
      'child_name': childName,
      'enabled': enabled ? 1 : 0,
      'expiry_date': expiryDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ParentalControlRule.fromDb(
    Map<String, dynamic> ruleMap,
    List<Map<String, dynamic>> scheduleMaps,
    List<Map<String, dynamic>> filterMaps,
  ) {
    return ParentalControlRule(
      id: ruleMap['id'],
      deviceId: ruleMap['device_mac'],
      deviceName: ruleMap['device_name'] ?? 'Unknown Device',
      childName: ruleMap['child_name'],
      enabled: (ruleMap['enabled'] ?? 1) == 1,
      expiryDate: ruleMap['expiry_date'] != null
          ? DateTime.parse(ruleMap['expiry_date'])
          : null,
      schedules: scheduleMaps.map((s) => ScheduleRule.fromDb(s)).toList(),
      contentFilters: filterMaps.map((f) => ContentFilter.fromDb(f)).toList(),
      createdAt: ruleMap['created_at'] != null
          ? DateTime.parse(ruleMap['created_at'])
          : null,
      updatedAt: ruleMap['updated_at'] != null
          ? DateTime.parse(ruleMap['updated_at'])
          : null,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'child_name': childName,
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'content_filters': contentFilters.map((f) => f.toJson()).toList(),
      'enabled': enabled,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}

class ScheduleRule {
  final String id;
  final String name;
  final List<int> days; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;

  ScheduleRule({
    required this.id,
    required this.name,
    required this.days,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  Map<String, dynamic> toJsonForDb(String ruleId) {
    return {
      'id': id,
      'rule_id': ruleId,
      'name': name,
      'days': jsonEncode(days),
      'start_hour': startTime.hour,
      'start_minute': startTime.minute,
      'end_hour': endTime.hour,
      'end_minute': endTime.minute,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ScheduleRule.fromDb(Map<String, dynamic> map) {
    return ScheduleRule(
      id: map['id'],
      name: map['name'],
      days: List<int>.from(jsonDecode(map['days'])),
      startTime: TimeOfDay(
        hour: map['start_hour'],
        minute: map['start_minute'],
      ),
      endTime: TimeOfDay(hour: map['end_hour'], minute: map['end_minute']),
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'days': days,
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'is_active': isActive,
    };
  }

  // Helper method to check if current time is within schedule
  bool isActiveNow() {
    if (!isActive) return false;

    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Convert to 0-6 format (0 = Sunday)

    if (!days.contains(currentDay)) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}

class ContentFilter {
  final FilterType type;
  final List<String> blockedCategories;
  final List<String> allowedCategories;
  final bool safeSearch;
  final bool youtubeRestricted;

  ContentFilter({
    required this.type,
    this.blockedCategories = const [],
    this.allowedCategories = const [],
    this.safeSearch = true,
    this.youtubeRestricted = false,
  });

  Map<String, dynamic> toJsonForDb(String ruleId) {
    return {
      'rule_id': ruleId,
      'filter_type': type.toString().split('.').last,
      'blocked_categories': jsonEncode(blockedCategories),
      'allowed_categories': jsonEncode(allowedCategories),
      'safe_search': safeSearch ? 1 : 0,
      'youtube_restricted': youtubeRestricted ? 1 : 0,
    };
  }

  factory ContentFilter.fromDb(Map<String, dynamic> map) {
    return ContentFilter(
      type: _parseFilterType(map['filter_type']),
      blockedCategories: List<String>.from(
        jsonDecode(map['blocked_categories'] ?? '[]'),
      ),
      allowedCategories: List<String>.from(
        jsonDecode(map['allowed_categories'] ?? '[]'),
      ),
      safeSearch: (map['safe_search'] ?? 1) == 1,
      youtubeRestricted: (map['youtube_restricted'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'blocked_categories': blockedCategories,
      'allowed_categories': allowedCategories,
      'safe_search': safeSearch,
      'youtube_restricted': youtubeRestricted,
    };
  }

  static FilterType _parseFilterType(String? type) {
    switch (type?.toLowerCase()) {
      case 'strict':
        return FilterType.strict;
      case 'moderate':
        return FilterType.moderate;
      case 'custom':
        return FilterType.custom;
      case 'none':
        return FilterType.none;
      case 'youtuberestricted':
        return FilterType.youtubeRestricted;
      default:
        return FilterType.moderate;
    }
  }

  // Get display name for filter type
  String get displayName {
    switch (type) {
      case FilterType.strict:
        return 'Strict Filtering';
      case FilterType.moderate:
        return 'Moderate Filtering';
      case FilterType.custom:
        return 'Custom Filtering';
      case FilterType.none:
        return 'No Filtering';
      case FilterType.youtubeRestricted:
        return 'YouTube Restricted Mode';
    }
  }

  // Get description for filter type
  String get description {
    switch (type) {
      case FilterType.strict:
        return 'Blocks adult content, violence, and inappropriate material';
      case FilterType.moderate:
        return 'Blocks most inappropriate content, allows educational';
      case FilterType.custom:
        return 'User-defined filtering rules';
      case FilterType.none:
        return 'No content filtering applied';
      case FilterType.youtubeRestricted:
        return 'Enables YouTube Restricted Mode';
    }
  }

  // Get icon for filter type
  IconData get icon {
    switch (type) {
      case FilterType.strict:
        return Icons.shield;
      case FilterType.moderate:
        return Icons.security;
      case FilterType.custom:
        return Icons.tune;
      case FilterType.none:
        return Icons.public;
      case FilterType.youtubeRestricted:
        return Icons.video_library;
    }
  }

  // Get color for filter type
  Color get color {
    switch (type) {
      case FilterType.strict:
        return Colors.red;
      case FilterType.moderate:
        return Colors.orange;
      case FilterType.custom:
        return Colors.purple;
      case FilterType.none:
        return Colors.grey;
      case FilterType.youtubeRestricted:
        return Colors.red.shade400;
    }
  }
}

// Common content categories for filtering
class ContentCategories {
  static const List<String> allCategories = [
    'adult',
    'violence',
    'gambling',
    'social_media',
    'gaming',
    'streaming',
    'educational',
    'news',
    'shopping',
    'downloads',
  ];

  static const Map<String, String> categoryNames = {
    'adult': 'Adult Content',
    'violence': 'Violence',
    'gambling': 'Gambling',
    'social_media': 'Social Media',
    'gaming': 'Gaming',
    'streaming': 'Video Streaming',
    'educational': 'Educational',
    'news': 'News',
    'shopping': 'Shopping',
    'downloads': 'Downloads',
  };

  static String getCategoryName(String category) {
    return categoryNames[category] ?? category;
  }
}
