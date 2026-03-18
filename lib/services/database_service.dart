import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:test_wifi/models/traffic_model.dart';
import '../models/router_profile.dart';
import '../models/user_bandwidth.dart';
import '../models/parental_control.dart';
import '../models/device_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'huawei_router.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create router profiles table
    await db.execute('''
      CREATE TABLE router_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ip_address TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT,
        model TEXT,
        mac_address TEXT,
        is_default INTEGER DEFAULT 0,
        last_connected TEXT,
        capabilities TEXT,
        status TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create bandwidth controls table
    await db.execute('''
      CREATE TABLE bandwidth_controls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_mac TEXT UNIQUE NOT NULL,
        device_name TEXT,
        upload_limit INTEGER DEFAULT 0,
        download_limit INTEGER DEFAULT 0,
        is_limited INTEGER DEFAULT 0,
        priority TEXT DEFAULT 'normal',
        time_restriction TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create parental control rules table
    await db.execute('''
      CREATE TABLE parental_rules (
        id TEXT PRIMARY KEY,
        device_mac TEXT NOT NULL,
        device_name TEXT,
        child_name TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        expiry_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        rule_id TEXT NOT NULL,
        name TEXT NOT NULL,
        days TEXT NOT NULL,
        start_hour INTEGER NOT NULL,
        start_minute INTEGER NOT NULL,
        end_hour INTEGER NOT NULL,
        end_minute INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (rule_id) REFERENCES parental_rules (id) ON DELETE CASCADE
      )
    ''');

    // Create content filters table
    await db.execute('''
      CREATE TABLE content_filters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rule_id TEXT NOT NULL,
        filter_type TEXT NOT NULL,
        blocked_categories TEXT,
        allowed_categories TEXT,
        safe_search INTEGER DEFAULT 1,
        youtube_restricted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (rule_id) REFERENCES parental_rules (id) ON DELETE CASCADE
      )
    ''');

    // Create app settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create traffic history table
    await db.execute('''
      CREATE TABLE traffic_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        router_id TEXT,
        timestamp TEXT NOT NULL,
        download_rate INTEGER,
        upload_rate INTEGER,
        total_download INTEGER,
        total_upload INTEGER,
        FOREIGN KEY (router_id) REFERENCES router_profiles (id) ON DELETE CASCADE
      )
    ''');

    // Insert default settings
    await db.insert('app_settings', {'key': 'dark_mode', 'value': 'false'});
    await db.insert('app_settings', {'key': 'auto_refresh', 'value': 'true'});
    await db.insert('app_settings', {'key': 'refresh_interval', 'value': '30'});
    await db.insert('app_settings', {'key': 'notifications', 'value': 'true'});
    await db.insert('app_settings', {
      'key': 'biometric_enabled',
      'value': 'false',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE router_profiles ADD COLUMN last_connected TEXT
      ''');
    }
  }

  // ==================== Router Profiles ====================

  Future<void> insertRouterProfile(RouterProfile profile) async {
    final db = await database;
    await db.insert(
      'router_profiles',
      profile.toJsonForDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RouterProfile>> getAllRouterProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'router_profiles',
      orderBy: 'is_default DESC, last_connected DESC',
    );

    return List.generate(maps.length, (i) {
      return RouterProfile.fromDb(maps[i]);
    });
  }

  Future<RouterProfile?> getRouterProfile(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'router_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return RouterProfile.fromDb(maps.first);
    }
    return null;
  }

  Future<RouterProfile?> getDefaultRouterProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'router_profiles',
      where: 'is_default = 1',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return RouterProfile.fromDb(maps.first);
    }
    return null;
  }

  Future<void> updateRouterProfile(RouterProfile profile) async {
    final db = await database;
    await db.update(
      'router_profiles',
      profile.toJsonForDb(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> deleteRouterProfile(String id) async {
    final db = await database;
    await db.delete('router_profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefaultRouterProfile(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear previous default
      await txn.rawUpdate('UPDATE router_profiles SET is_default = 0');
      // Set new default
      await txn.update(
        'router_profiles',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ==================== Bandwidth Controls ====================

  Future<void> insertOrUpdateBandwidthControl(
    UserBandwidthControl control,
  ) async {
    final db = await database;
    await db.insert(
      'bandwidth_controls',
      control.toJsonForDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserBandwidthControl?> getBandwidthControl(String deviceMac) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bandwidth_controls',
      where: 'device_mac = ?',
      whereArgs: [deviceMac],
    );

    if (maps.isNotEmpty) {
      return UserBandwidthControl.fromDb(maps.first);
    }
    return null;
  }

  Future<List<UserBandwidthControl>> getAllBandwidthControls() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bandwidth_controls',
    );

    return List.generate(maps.length, (i) {
      return UserBandwidthControl.fromDb(maps[i]);
    });
  }

  Future<void> deleteBandwidthControl(String deviceMac) async {
    final db = await database;
    await db.delete(
      'bandwidth_controls',
      where: 'device_mac = ?',
      whereArgs: [deviceMac],
    );
  }

  // ==================== Parental Controls ====================

  Future<void> insertParentalRule(ParentalControlRule rule) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert main rule
      await txn.insert(
        'parental_rules',
        rule.toJsonForDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert schedules
      for (var schedule in rule.schedules) {
        await txn.insert(
          'schedules',
          schedule.toJsonForDb(rule.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert content filters
      for (var filter in rule.contentFilters) {
        await txn.insert(
          'content_filters',
          filter.toJsonForDb(rule.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<ParentalControlRule>> getAllParentalRules() async {
    final db = await database;
    final List<ParentalControlRule> rules = [];

    // Get all rules
    final List<Map<String, dynamic>> ruleMaps = await db.query(
      'parental_rules',
    );

    for (var ruleMap in ruleMaps) {
      final ruleId = ruleMap['id'] as String;

      // Get schedules for this rule
      final List<Map<String, dynamic>> scheduleMaps = await db.query(
        'schedules',
        where: 'rule_id = ?',
        whereArgs: [ruleId],
      );

      // Get content filters for this rule
      final List<Map<String, dynamic>> filterMaps = await db.query(
        'content_filters',
        where: 'rule_id = ?',
        whereArgs: [ruleId],
      );

      rules.add(ParentalControlRule.fromDb(ruleMap, scheduleMaps, filterMaps));
    }

    return rules;
  }

  Future<ParentalControlRule?> getParentalRule(String ruleId) async {
    final db = await database;

    final List<Map<String, dynamic>> ruleMaps = await db.query(
      'parental_rules',
      where: 'id = ?',
      whereArgs: [ruleId],
    );

    if (ruleMaps.isEmpty) return null;

    final ruleMap = ruleMaps.first;

    // Get schedules
    final List<Map<String, dynamic>> scheduleMaps = await db.query(
      'schedules',
      where: 'rule_id = ?',
      whereArgs: [ruleId],
    );

    // Get content filters
    final List<Map<String, dynamic>> filterMaps = await db.query(
      'content_filters',
      where: 'rule_id = ?',
      whereArgs: [ruleId],
    );

    return ParentalControlRule.fromDb(ruleMap, scheduleMaps, filterMaps);
  }

  Future<void> updateParentalRule(ParentalControlRule rule) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update main rule
      await txn.update(
        'parental_rules',
        rule.toJsonForDb(),
        where: 'id = ?',
        whereArgs: [rule.id],
      );

      // Delete old schedules and filters
      await txn.delete('schedules', where: 'rule_id = ?', whereArgs: [rule.id]);
      await txn.delete(
        'content_filters',
        where: 'rule_id = ?',
        whereArgs: [rule.id],
      );

      // Insert new schedules
      for (var schedule in rule.schedules) {
        await txn.insert(
          'schedules',
          schedule.toJsonForDb(rule.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert new filters
      for (var filter in rule.contentFilters) {
        await txn.insert(
          'content_filters',
          filter.toJsonForDb(rule.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteParentalRule(String ruleId) async {
    final db = await database;
    await db.delete('parental_rules', where: 'id = ?', whereArgs: [ruleId]);
    // Schedules and filters will be deleted automatically due to CASCADE
  }

  // ==================== App Settings ====================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('app_settings');

    return Map.fromEntries(
      maps.map((map) => MapEntry(map['key'] as String, map['value'] as String)),
    );
  }

  // ==================== Traffic History ====================

  Future<void> insertTrafficData(String routerId, TrafficModel traffic) async {
    final db = await database;
    await db.insert('traffic_history', {
      'router_id': routerId,
      'timestamp': DateTime.now().toIso8601String(),
      'download_rate': traffic.currentDownloadRate,
      'upload_rate': traffic.currentUploadRate,
      'total_download': traffic.totalDownload,
      'total_upload': traffic.totalUpload,
    });
  }

  Future<List<Map<String, dynamic>>> getTrafficHistory(
    String routerId, {
    int limit = 100,
  }) async {
    final db = await database;
    return await db.query(
      'traffic_history',
      where: 'router_id = ?',
      whereArgs: [routerId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<void> cleanupOldTrafficData(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      'traffic_history',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
}
