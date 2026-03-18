import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  static const String _autoRefreshKey = 'autoRefresh';
  static const String _refreshIntervalKey = 'refreshInterval';
  static const String _notificationsKey = 'notifications';

  bool _isDarkMode = false;
  bool _autoRefresh = true;
  int _refreshInterval = 30;
  bool _notificationsEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get autoRefresh => _autoRefresh;
  int get refreshInterval => _refreshInterval;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _autoRefresh = prefs.getBool(_autoRefreshKey) ?? true;
    _refreshInterval = prefs.getInt(_refreshIntervalKey) ?? 30;
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleAutoRefresh() async {
    _autoRefresh = !_autoRefresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRefreshKey, _autoRefresh);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int seconds) async {
    _refreshInterval = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshIntervalKey, seconds);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
    notifyListeners();
  }
}
