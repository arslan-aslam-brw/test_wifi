import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';

class DatabaseBackup {
  static Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'huawei_router.db');
  }

  static Future<File> createBackup() async {
    final dbPath = await getDatabasePath();
    final backupDir = await getApplicationDocumentsDirectory();
    final backupPath = join(
      backupDir.path,
      'router_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );

    // Copy database file
    final File original = File(dbPath);
    final File backup = File(backupPath);
    await backup.writeAsBytes(await original.readAsBytes());

    return backup;
  }

  static Future<void> shareBackup() async {
    try {
      final backupFile = await createBackup();
      await Share.shareXFiles([
        backupFile.path as XFile,
      ], text: 'Router Manager Backup - ${DateTime.now().toIso8601String()}');
    } catch (e) {
      debugPrint('Error sharing backup: $e');
    }
  }

  static Future<bool> restoreBackup(String filePath) async {
    try {
      final dbPath = await getDatabasePath();
      final File backup = File(filePath);

      // Close current database connection
      await DatabaseService().database.then((db) => db.close());

      // Replace database file
      final File original = File(dbPath);
      await original.writeAsBytes(await backup.readAsBytes());

      // Reopen database
      await DatabaseService().database;
      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }

  static Future<void> exportToJson() async {
    try {
      final db = await DatabaseService().database;
      final backupDir = await getApplicationDocumentsDirectory();
      final jsonPath = join(
        backupDir.path,
        'router_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      // Export all data
      final exportData = {
        'router_profiles': await db.query('router_profiles'),
        'bandwidth_controls': await db.query('bandwidth_controls'),
        'parental_rules': await db.query('parental_rules'),
        'schedules': await db.query('schedules'),
        'content_filters': await db.query('content_filters'),
        'app_settings': await db.query('app_settings'),
        'export_date': DateTime.now().toIso8601String(),
      };

      final File jsonFile = File(jsonPath);
      await jsonFile.writeAsString(jsonEncode(exportData));

      await Share.shareXFiles([
        jsonFile.path as XFile,
      ], text: 'Router Manager Export');
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
    }
  }

  // ADD THIS MISSING METHOD
  static Future<void> clearAllData() async {
    try {
      final db = await DatabaseService().database;

      // Get all tables (excluding sqlite_sequence)
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      // Delete all data from each table
      await db.transaction((txn) async {
        for (var table in tables) {
          final tableName = table['name'] as String;
          await txn.delete(tableName);
        }
      });

      // Vacuum to reclaim space
      await db.execute('VACUUM');

      debugPrint('All data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }
}
