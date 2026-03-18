// lib/providers/router_provider_extended.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:local_auth/local_auth.dart';
import '../services/database_service.dart';
import '../models/router_profile.dart';
import '../models/user_bandwidth.dart';
import '../models/parental_control.dart';

import '../models/device_model.dart';
import '../models/traffic_model.dart';
import '../services/base_api_client.dart';

class ExtendedRouterProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Add BaseApiClient
  late BaseApiClient _apiClient;

  // Connected devices list (needed for bandwidth control)
  List<DeviceModel> _connectedDevices = [];

  // Multiple router support
  List<RouterProfile> _routerProfiles = [];
  RouterProfile? _currentProfile;

  // Bandwidth control
  Map<String, UserBandwidthControl> _bandwidthControls = {};

  // Parental controls
  List<ParentalControlRule> _parentalRules = [];

  // Biometric auth
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // Settings
  Map<String, String> _settings = {};

  // Getters
  List<RouterProfile> get routerProfiles => _routerProfiles;
  RouterProfile? get currentProfile => _currentProfile;
  Map<String, UserBandwidthControl> get bandwidthControls => _bandwidthControls;
  List<ParentalControlRule> get parentalRules => _parentalRules;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  Map<String, String> get settings => _settings;
  List<DeviceModel> get connectedDevices => _connectedDevices;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Add setDevicePriority method
  Future<bool> setDevicePriority(
    String macAddress,
    PriorityLevel priority,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update local state
      if (_bandwidthControls.containsKey(macAddress)) {
        final control = _bandwidthControls[macAddress]!;

        // Create updated control with new priority
        final updatedControl = UserBandwidthControl(
          deviceId: control.deviceId,
          deviceName: control.deviceName,
          macAddress: control.macAddress,
          uploadLimit: control.uploadLimit,
          downloadLimit: control.downloadLimit,
          isLimited: control.isLimited,
          priority: priority,
          timeRestriction: control.timeRestriction,
        );

        // Save to database
        await _dbService.insertOrUpdateBandwidthControl(updatedControl);
        _bandwidthControls[macAddress] = updatedControl;
      }

      // Apply to router (API call)
      if (_apiClient != null) {
        final response = await _apiClient.post(
          '/api/qos/priority',
          body: {
            'mac': macAddress,
            'priority': priority.toString().split('.').last,
          },
        );

        _isLoading = false;
        notifyListeners();
        return response['success'] == true || response['result'] == 'success';
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting device priority: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Also add a method to refresh bandwidth controls
  Future<void> refreshBandwidthControls() async {
    _isLoading = true;
    notifyListeners();

    await _loadBandwidthControls();

    _isLoading = false;
    notifyListeners();
  }

  ExtendedRouterProvider() {
    _init();
  }

  Future<void> _init() async {
    await _initBiometrics();
    await _loadSettings();
    await _loadRouterProfiles();
    await _loadBandwidthControls();
    await loadParentalControls();
  }

  // Initialize BaseApiClient for a specific router
  Future<void> initialize(String ip) async {
    _apiClient = BaseApiClient(baseUrl: 'http://$ip');
  }

  // ==================== Biometric Authentication ====================

  Future<void> _initBiometrics() async {
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics;
      if (_biometricAvailable) {
        final devices = await _localAuth.getAvailableBiometrics();
        _biometricAvailable = devices.isNotEmpty;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing biometrics: $e');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricAvailable) return false;

    try {
      // FIXED: AuthenticationOptions is from local_auth package
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access router settings',
        options: AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<void> toggleBiometric(bool enabled) async {
    _biometricEnabled = enabled;
    await _dbService.setSetting('biometric_enabled', enabled.toString());
    _settings['biometric_enabled'] = enabled.toString();
    notifyListeners();
  }

  // ==================== Settings ====================

  Future<void> _loadSettings() async {
    _settings = await _dbService.getAllSettings();
    _biometricEnabled = _settings['biometric_enabled'] == 'true';
    notifyListeners();
  }

  Future<void> updateSetting(String key, String value) async {
    await _dbService.setSetting(key, value);
    _settings[key] = value;
    notifyListeners();
  }

  // ==================== Router Profile Management ====================

  Future<void> _loadRouterProfiles() async {
    try {
      _routerProfiles = await _dbService.getAllRouterProfiles();

      // Set current profile to default or first
      if (_routerProfiles.isNotEmpty) {
        _currentProfile = _routerProfiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => _routerProfiles.first,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading router profiles: $e');
    }
  }

  Future<void> addRouterProfile(RouterProfile profile) async {
    // FIXED: Create new profile with generated ID instead of modifying final field
    final newProfile = RouterProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: profile.name,
      ipAddress: profile.ipAddress,
      username: profile.username,
      password: profile.password,
      model: profile.model,
      macAddress: profile.macAddress,
      isDefault: profile.isDefault,
      lastConnected: profile.lastConnected,
      capabilities: profile.capabilities,
      status: profile.status,
    );

    await _dbService.insertRouterProfile(newProfile);
    _routerProfiles.add(newProfile);
    notifyListeners();
  }

  Future<void> updateRouterProfile(RouterProfile profile) async {
    await _dbService.updateRouterProfile(profile);
    final index = _routerProfiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _routerProfiles[index] = profile;
    }
    notifyListeners();
  }

  Future<void> deleteRouterProfile(String id) async {
    await _dbService.deleteRouterProfile(id);
    _routerProfiles.removeWhere((p) => p.id == id);
    if (_currentProfile?.id == id) {
      _currentProfile = _routerProfiles.isNotEmpty
          ? _routerProfiles.first
          : null;
    }
    notifyListeners();
  }

  Future<void> setDefaultRouterProfile(String id) async {
    await _dbService.setDefaultRouterProfile(id);
    for (var profile in _routerProfiles) {
      profile.isDefault = profile.id == id;
    }
    notifyListeners();
  }

  Future<bool> switchRouter(RouterProfile profile) async {
    try {
      // Update last connected time
      final updatedProfile = RouterProfile(
        id: profile.id,
        name: profile.name,
        ipAddress: profile.ipAddress,
        username: profile.username,
        password: profile.password,
        model: profile.model,
        macAddress: profile.macAddress,
        isDefault: profile.isDefault,
        lastConnected: DateTime.now(),
        capabilities: profile.capabilities,
        status: ConnectionStatus.connected,
      );

      await _dbService.updateRouterProfile(updatedProfile);
      _currentProfile = updatedProfile;

      // Update in list
      final index = _routerProfiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _routerProfiles[index] = updatedProfile;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error switching router: $e');
      return false;
    }
  }

  // ==================== Bandwidth Controls ====================

  Future<void> _loadBandwidthControls() async {
    try {
      final controls = await _dbService.getAllBandwidthControls();
      _bandwidthControls = {
        for (var control in controls) control.macAddress: control,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bandwidth controls: $e');
    }
  }

  // Method to load connected devices
  Future<void> _loadConnectedDevices() async {
    // This would be implemented to fetch from router
    // For now, keep existing list or load from DB
  }

  Future<bool> setBandwidthLimit(
    String macAddress,
    int uploadLimit,
    int downloadLimit,
  ) async {
    try {
      // Get existing or create new control
      var control = _bandwidthControls[macAddress];
      if (control == null) {
        // FIXED: Use a default device when not found
        control = UserBandwidthControl(
          deviceId: macAddress,
          deviceName: 'Unknown Device',
          macAddress: macAddress,
        );
      }

      // FIXED: Create updated control instead of modifying final fields
      final updatedControl = UserBandwidthControl(
        deviceId: control.deviceId,
        deviceName: control.deviceName,
        macAddress: control.macAddress,
        uploadLimit: uploadLimit,
        downloadLimit: downloadLimit,
        isLimited: true,
        priority: control.priority,
        timeRestriction: control.timeRestriction,
      );

      await _dbService.insertOrUpdateBandwidthControl(updatedControl);
      _bandwidthControls[macAddress] = updatedControl;
      notifyListeners();

      // Apply to router (API call) - FIXED: Use proper API call
      if (_apiClient != null) {
        final response = await _apiClient.post(
          '/api/bandwidth/control',
          body: {
            'mac': macAddress,
            'upload_limit': uploadLimit,
            'download_limit': downloadLimit,
            'enabled': true,
          },
        );

        // FIXED: Check response properly
        return response['success'] == true || response['result'] == 'success';
      }

      return true; // Assume success if no API client
    } catch (e) {
      debugPrint('Error setting bandwidth limit: $e');
      return false;
    }
  }

  Future<bool> removeBandwidthLimit(String macAddress) async {
    try {
      if (_bandwidthControls.containsKey(macAddress)) {
        final control = _bandwidthControls[macAddress]!;

        // FIXED: Create updated control with isLimited = false
        final updatedControl = UserBandwidthControl(
          deviceId: control.deviceId,
          deviceName: control.deviceName,
          macAddress: control.macAddress,
          uploadLimit: 0,
          downloadLimit: 0,
          isLimited: false,
          priority: control.priority,
          timeRestriction: control.timeRestriction,
        );

        await _dbService.insertOrUpdateBandwidthControl(updatedControl);
        _bandwidthControls[macAddress] = updatedControl;
        notifyListeners();
      }

      // Apply to router (API call) - FIXED: Use proper API call
      if (_apiClient != null) {
        final response = await _apiClient.post(
          '/api/bandwidth/control/remove',
          body: {'mac': macAddress},
        );

        return response['success'] == true || response['result'] == 'success';
      }

      return true;
    } catch (e) {
      debugPrint('Error removing bandwidth limit: $e');
      return false;
    }
  }

  // ==================== Parental Controls ====================

  Future<void> loadParentalControls() async {
    try {
      _parentalRules = await _dbService.getAllParentalRules();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading parental rules: $e');
    }
  }

  // FIXED: Added missing _encodeContentFilters method
  Map<String, dynamic> _encodeContentFilters(List<ContentFilter> filters) {
    final result = <String, dynamic>{};

    for (var filter in filters) {
      if (filter.type == FilterType.youtubeRestricted) {
        result['youtube'] = {'restricted': filter.youtubeRestricted};
      } else {
        result['web'] = {
          'type': filter.type.toString().split('.').last,
          'blocked': filter.blockedCategories,
          'allowed': filter.allowedCategories,
          'safe_search': filter.safeSearch,
        };
      }
    }

    return result;
  }

  Future<bool> addParentalControlRule(ParentalControlRule rule) async {
    try {
      await _dbService.insertParentalRule(rule);
      _parentalRules.add(rule);
      notifyListeners();

      // Apply to router (API call) - FIXED: Use proper API call
      if (_apiClient != null) {
        final response = await _apiClient.post(
          '/api/parental-control/rules',
          body: {
            'device_id': rule.deviceId,
            'child_name': rule.childName,
            'schedules': rule.schedules.map((s) => s.toJson()).toList(),
            'filters': _encodeContentFilters(rule.contentFilters),
            'enabled': rule.enabled,
            'expiry': rule.expiryDate?.toIso8601String(),
          },
        );

        return response['success'] == true || response['result'] == 'success';
      }

      return true;
    } catch (e) {
      debugPrint('Error adding parental control: $e');
      return false;
    }
  }

  Future<bool> updateParentalControlRule(ParentalControlRule rule) async {
    try {
      await _dbService.updateParentalRule(rule);
      final index = _parentalRules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _parentalRules[index] = rule;
      }
      notifyListeners();

      // Apply to router (API call) - FIXED: Use proper API call
      if (_apiClient != null) {
        final response = await _apiClient.post(
          '/api/parental-control/rules/${rule.id}',
          body: {
            'device_id': rule.deviceId,
            'child_name': rule.childName,
            'schedules': rule.schedules.map((s) => s.toJson()).toList(),
            'filters': _encodeContentFilters(rule.contentFilters),
            'enabled': rule.enabled,
            'expiry': rule.expiryDate?.toIso8601String(),
          },
        );

        return response['success'] == true || response['result'] == 'success';
      }

      return true;
    } catch (e) {
      debugPrint('Error updating parental control: $e');
      return false;
    }
  }

  Future<bool> deleteParentalControlRule(String ruleId) async {
    try {
      await _dbService.deleteParentalRule(ruleId);
      _parentalRules.removeWhere((r) => r.id == ruleId);
      notifyListeners();

      // Apply to router (API call) - FIXED: Use proper API call
      if (_apiClient != null) {
        final response = await _apiClient.delete(
          '/api/parental-control/rules/$ruleId',
        );
        return response['success'] == true || response['result'] == 'success';
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting parental control: $e');
      return false;
    }
  }

  // ==================== Traffic History ====================

  Future<void> saveTrafficHistory(TrafficModel traffic) async {
    if (_currentProfile != null) {
      await _dbService.insertTrafficData(_currentProfile!.id, traffic);
    }
  }

  Future<List<Map<String, dynamic>>> getTrafficHistory({
    int limit = 100,
  }) async {
    if (_currentProfile != null) {
      return await _dbService.getTrafficHistory(
        _currentProfile!.id,
        limit: limit,
      );
    }
    return [];
  }

  // ==================== Load All Data ====================

  Future<void> loadAllData() async {
    await Future.wait([
      _loadRouterProfiles(),
      _loadBandwidthControls(),
      loadParentalControls(),
      _loadConnectedDevices(),
    ]);
  }

  // ==================== Logout and Cleanup ====================

  @override
  void dispose() {
    _cleanupOldData();
    super.dispose();
  }

  Future<void> _cleanupOldData() async {
    // Clean up traffic history older than 30 days
    await _dbService.cleanupOldTrafficData(30);
  }

  // FIXED: Removed super.logout() call and implemented properly
  Future<void> logout() async {
    // Clear current profile status
    if (_currentProfile != null) {
      final updatedProfile = RouterProfile(
        id: _currentProfile!.id,
        name: _currentProfile!.name,
        ipAddress: _currentProfile!.ipAddress,
        username: _currentProfile!.username,
        password: _currentProfile!.password,
        model: _currentProfile!.model,
        macAddress: _currentProfile!.macAddress,
        isDefault: _currentProfile!.isDefault,
        lastConnected: _currentProfile!.lastConnected,
        capabilities: _currentProfile!.capabilities,
        status: ConnectionStatus.disconnected,
      );

      await _dbService.updateRouterProfile(updatedProfile);
      _currentProfile = updatedProfile;

      // Update in list
      final index = _routerProfiles.indexWhere(
        (p) => p.id == _currentProfile!.id,
      );
      if (index != -1) {
        _routerProfiles[index] = updatedProfile;
      }

      notifyListeners();
    }

    // Clear API client
    _apiClient = null as BaseApiClient;
  }

  // ==================== Router Control Methods ====================

  Future<bool> rebootRouter() async {
    try {
      if (_apiClient != null) {
        final response = await _apiClient.post(
          '/api/device/control',
          body: {'control': 'reboot'},
        );
        return response['success'] == true || response['result'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error rebooting router: $e');
      return false;
    }
  }

  // Login method
  Future<bool> login(String username, String password, String ip) async {
    // This would be implemented with your auth service
    // For now, return true as placeholder
    return true;
  }
}
