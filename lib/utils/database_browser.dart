import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'database_location.dart';

class DatabaseBrowser {
  /// List all tables in the database
  static Future<List<String>> getTables() async {
    final dbPath = await DatabaseLocation.getDatabasePath();
    if (!await File(dbPath).exists()) {
      return [];
    }

    final db = await openDatabase(dbPath);
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    await db.close();

    return result.map((row) => row['name'] as String).toList();
  }

  /// Get table schema
  static Future<List<Map<String, dynamic>>> getTableSchema(
    String tableName,
  ) async {
    final dbPath = await DatabaseLocation.getDatabasePath();
    if (!await File(dbPath).exists()) {
      return [];
    }

    final db = await openDatabase(dbPath);
    final result = await db.rawQuery("PRAGMA table_info($tableName)");
    await db.close();

    return result;
  }

  /// Get table row count
  static Future<int> getTableRowCount(String tableName) async {
    final dbPath = await DatabaseLocation.getDatabasePath();
    if (!await File(dbPath).exists()) {
      return 0;
    }

    final db = await openDatabase(dbPath);
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM $tableName",
    );
    await db.close();

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Preview table data
  static Future<List<Map<String, dynamic>>> previewTable(
    String tableName, {
    int limit = 10,
    int offset = 0,
  }) async {
    final dbPath = await DatabaseLocation.getDatabasePath();
    if (!await File(dbPath).exists()) {
      return [];
    }

    final db = await openDatabase(dbPath);
    final result = await db.query(tableName, limit: limit, offset: offset);
    await db.close();

    return result;
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final tables = await getTables();
    final stats = <String, dynamic>{};

    for (var table in tables) {
      stats[table] = {
        'rowCount': await getTableRowCount(table),
        'schema': await getTableSchema(table),
      };
    }

    return stats;
  }

  /// Export database as JSON
  static Future<Map<String, dynamic>> exportDatabaseAsJson() async {
    final tables = await getTables();
    final export = <String, dynamic>{};

    final dbPath = await DatabaseLocation.getDatabasePath();
    if (!await File(dbPath).exists()) {
      return export;
    }

    final db = await openDatabase(dbPath);

    for (var table in tables) {
      final data = await db.query(table);
      export[table] = data;
    }

    await db.close();

    export['_metadata'] = {
      'exportDate': DateTime.now().toIso8601String(),
      'tableCount': tables.length,
      'databasePath': dbPath,
    };

    return export;
  }

  /// Get database summary for display
  static Future<String> getDatabaseSummary() async {
    final buffer = StringBuffer();
    final tables = await getTables();
    final dbInfo = await DatabaseLocation.getDatabaseInfo();

    buffer.writeln('📊 DATABASE SUMMARY');
    buffer.writeln('═' * 40);
    buffer.writeln('Location: ${dbInfo['path']}');
    buffer.writeln('Size: ${dbInfo['formattedSize']}');
    buffer.writeln('Total Tables: ${tables.length}');
    buffer.writeln('');

    for (var table in tables) {
      final count = await getTableRowCount(table);
      buffer.writeln('📋 $table: $count records');
    }

    return buffer.toString();
  }
}
