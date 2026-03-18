import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DatabaseLocation {
  static const String dbFileName = 'huawei_router.db';

  /// Get the full path to the database file
  static Future<String> getDatabasePath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return path.join(documentsDir.path, dbFileName);
  }

  /// Get the database directory
  static Future<Directory> getDatabaseDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get database file size
  static Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasePath();
    final file = File(dbPath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Format database size for display
  static Future<String> getFormattedDatabaseSize() async {
    final size = await getDatabaseSize();
    return _formatBytes(size);
  }

  /// Check if database exists
  static Future<bool> databaseExists() async {
    final dbPath = await getDatabasePath();
    return await File(dbPath).exists();
  }

  /// Get database creation time
  static Future<DateTime?> getDatabaseCreationTime() async {
    final dbPath = await getDatabasePath();
    final file = File(dbPath);
    if (await file.exists()) {
      return await file.stat().then((stat) => stat.modified);
    }
    return null;
  }

  /// Get database info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    final dbPath = await getDatabasePath();
    final file = File(dbPath);
    final exists = await file.exists();

    if (!exists) {
      return {
        'exists': false,
        'path': dbPath,
        'size': 0,
        'formattedSize': '0 B',
        'created': null,
        'modified': null,
      };
    }

    final stat = await file.stat();
    final size = await file.length();

    return {
      'exists': true,
      'path': dbPath,
      'size': size,
      'formattedSize': _formatBytes(size),
      'created': stat.modified,
      'modified': stat.modified,
      'isDirectory': false,
    };
  }

  /// Format bytes to human readable
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Print database location for debugging
  static Future<void> printDatabaseLocation() async {
    final dbPath = await getDatabasePath();
    final exists = await databaseExists();
    final size = await getFormattedDatabaseSize();

    debugPrint('📁 Database Location: $dbPath');
    debugPrint('📊 Database Exists: $exists');
    debugPrint('📦 Database Size: $size');

    if (exists) {
      final created = await getDatabaseCreationTime();
      debugPrint('🕒 Created: $created');
    }
  }

  /// Export database info
  static Future<String> getDatabaseInfoString() async {
    final info = await getDatabaseInfo();
    final buffer = StringBuffer();
    buffer.writeln('=== Database Information ===');
    buffer.writeln('Path: ${info['path']}');
    buffer.writeln('Exists: ${info['exists']}');
    buffer.writeln('Size: ${info['formattedSize']}');
    buffer.writeln('Modified: ${info['modified']}');
    return buffer.toString();
  }
}
