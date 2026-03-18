import 'package:flutter/material.dart';
import 'dart:convert';

// Define ConnectionStatus enum first
enum ConnectionStatus { connected, connecting, disconnected, error }

class RouterProfile {
  final String id;
  String name;
  String ipAddress;
  String username;
  String? password; // Store encrypted
  String? model;
  String? macAddress;
  bool isDefault;
  DateTime lastConnected;
  Map<String, dynamic>? capabilities;
  ConnectionStatus status;
  DateTime? createdAt;
  DateTime? updatedAt;

  RouterProfile({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.username,
    this.password,
    this.model,
    this.macAddress,
    this.isDefault = false,
    required this.lastConnected,
    this.capabilities,
    this.status = ConnectionStatus.disconnected,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for database storage
  Map<String, dynamic> toJsonForDb() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'username': username,
      'password': password,
      'model': model,
      'mac_address': macAddress,
      'is_default': isDefault ? 1 : 0,
      'last_connected': lastConnected.toIso8601String(),
      'capabilities': capabilities != null ? jsonEncode(capabilities) : null,
      'status': status.toString().split('.').last,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create from database map
  factory RouterProfile.fromDb(Map<String, dynamic> map) {
    return RouterProfile(
      id: map['id'],
      name: map['name'],
      ipAddress: map['ip_address'],
      username: map['username'],
      password: map['password'],
      model: map['model'],
      macAddress: map['mac_address'],
      isDefault: (map['is_default'] ?? 0) == 1,
      lastConnected: DateTime.parse(
        map['last_connected'] ?? DateTime.now().toIso8601String(),
      ),
      capabilities: map['capabilities'] != null
          ? jsonDecode(map['capabilities'])
          : null,
      status: _parseConnectionStatus(map['status']),
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
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'username': username,
      'model': model,
      'mac_address': macAddress,
      'is_default': isDefault,
      'last_connected': lastConnected.toIso8601String(),
      'capabilities': capabilities,
      'status': status.toString(),
    };
  }

  // Parse connection status from string
  static ConnectionStatus _parseConnectionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'connected':
        return ConnectionStatus.connected;
      case 'connecting':
        return ConnectionStatus.connecting;
      case 'error':
        return ConnectionStatus.error;
      case 'disconnected':
      default:
        return ConnectionStatus.disconnected;
    }
  }

  // Helper method to get status color
  Color getStatusColor() {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData getStatusIcon() {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.error:
        return Icons.error;
      case ConnectionStatus.disconnected:
        return Icons.router;
    }
  }

  // Helper method to get status text
  String getStatusText() {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Connection Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  // Helper method to check if router supports a feature
  bool supportsFeature(String feature) {
    if (capabilities == null) return false;
    final features = capabilities!['features'] as List?;
    return features?.contains(feature) ?? false;
  }

  // Helper method to get firmware version
  String? get firmwareVersion => capabilities?['firmware_version'];

  // Helper method to get hardware version
  String? get hardwareVersion => capabilities?['hardware_version'];

  // Helper method to get signal strength
  int? get signalStrength => capabilities?['signal_strength'];

  // Helper method to get connection type (4G, 5G, WiFi, etc.)
  String? get connectionType => capabilities?['connection_type'];

  // Helper method to format last connected time
  String getFormattedLastConnected() {
    final now = DateTime.now();
    final difference = now.difference(lastConnected);

    if (difference.inDays > 7) {
      return '${lastConnected.day}/${lastConnected.month}/${lastConnected.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// Extension for List<int> to check if contains all values
extension ListContains on List<int> {
  bool containsAll(List<int> values) {
    for (var value in values) {
      if (!contains(value)) return false;
    }
    return true;
  }
}
