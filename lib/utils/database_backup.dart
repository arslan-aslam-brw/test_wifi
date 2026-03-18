import 'dart:convert';
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
      await Share.shareFiles([
        backupFile.path,
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

      await Share.shareFiles([jsonFile.path], text: 'Router Manager Export');
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
    }
  }
}
