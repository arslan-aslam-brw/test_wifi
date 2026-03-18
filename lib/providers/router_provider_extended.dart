// lib/providers/router_provider_extended.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:test_wifi/models/router_model.dart';
import '../services/database_service.dart';
import '../services/base_api_client.dart';
import '../models/router_profile.dart';
import '../models/user_bandwidth.dart';
import '../models/parental_control.dart';
import '../models/device_model.dart';
import '../models/traffic_model.dart';
import '../models/signal_model.dart';

class ExtendedRouterProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ApiClient
  BaseApiClient? _apiClient;

  // Router Information (ADD THIS)
  RouterModel? _routerInfo;
  SignalModel? _signalInfo;
  List<DeviceModel> _connectedDevices = [];
  TrafficModel? _trafficInfo;
  bool _isLoading = false;
  String? _error;

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
  // ADD THESE GETTERS
  RouterModel? get routerInfo => _routerInfo;
  SignalModel? get signalInfo => _signalInfo;
  List<DeviceModel> get connectedDevices => _connectedDevices;
  TrafficModel? get trafficInfo => _trafficInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RouterProfile> get routerProfiles => _routerProfiles;
  RouterProfile? get currentProfile => _currentProfile;
  Map<String, UserBandwidthControl> get bandwidthControls => _bandwidthControls;
  List<ParentalControlRule> get parentalRules => _parentalRules;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  Map<String, String> get settings => _settings;

  ExtendedRouterProvider() {
    _init();
  }

  Future<void> _init() async {
    await _initBiometrics();
    await _loadSettings();
    await _loadRouterProfiles();
    await _loadBandwidthControls();
    await _loadParentalRules();
  }

  // Initialize ApiClient for a specific router
  Future<void> initialize(String ip) async {
    _apiClient = BaseApiClient(baseUrl: 'http://$ip');
  }

  // ==================== Router Information Methods ====================

  // ADD THIS METHOD
  Future<void> loadRouterInfo() async {
    if (_apiClient == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiClient!.get('/api/device/information');
      _routerInfo = RouterModel.fromJson({
        'ip': _apiClient!.baseUrl.replaceAll('http://', ''),
        ...response,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error loading router info: $e');
    }
  }

  // ADD THIS METHOD
  Future<void> loadSignalInfo() async {
    if (_apiClient == null) return;

    try {
      final response = await _apiClient!.get('/api/device/signal');
      _signalInfo = SignalModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading signal info: $e');
    }
  }

  // ADD THIS METHOD
  Future<void> loadConnectedDevices() async {
    if (_apiClient == null) return;

    try {
      final response = await _apiClient!.get('/api/lan/connected-devices');
      _connectedDevices = _parseDevices(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading connected devices: $e');
    }
  }

  // ADD THIS METHOD
  List<DeviceModel> _parseDevices(Map<String, dynamic> data) {
    final List<DeviceModel> devices = [];

    if (data.containsKey('Devices')) {
      final devicesList = data['Devices'] as List;
      for (var device in devicesList) {
        devices.add(DeviceModel.fromJson(device));
      }
    } else if (data.containsKey('Clients')) {
      final clientsList = data['Clients'] as List;
      for (var client in clientsList) {
        devices.add(DeviceModel.fromJson(client));
      }
    } else if (data is List) {
      for (var item in data as List<Map<String, dynamic>>) {
        devices.add(DeviceModel.fromJson(item));
      }
    }

    return devices;
  }

  // ADD THIS METHOD
  Future<void> loadTrafficInfo() async {
    if (_apiClient == null) return;

    try {
      final response = await _apiClient!.get(
        '/api/monitoring/traffic-statistics',
      );
      _trafficInfo = TrafficModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading traffic info: $e');
    }
  }

  // ADD THIS METHOD
  Future<void> loadAllRouterData() async {
    if (_apiClient == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadRouterInfo(),
        loadSignalInfo(),
        loadConnectedDevices(),
        loadTrafficInfo(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading all data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      // Initialize API client for this router
      await initialize(profile.ipAddress);

      // Attempt login (you'll need to implement this with your auth service)
      // For now, assume success

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

      // Load router data
      await loadAllRouterData();

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

  Future<bool> setBandwidthLimit(
    String macAddress,
    int uploadLimit,
    int downloadLimit,
  ) async {
    try {
      var control = _bandwidthControls[macAddress];
      if (control == null) {
        control = UserBandwidthControl(
          deviceId: macAddress,
          deviceName: 'Unknown Device',
          macAddress: macAddress,
        );
      }

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

      if (_apiClient != null) {
        final response = await _apiClient!.post(
          '/api/bandwidth/control',
          body: {
            'mac': macAddress,
            'upload_limit': uploadLimit,
            'download_limit': downloadLimit,
            'enabled': true,
          },
        );

        return response['success'] == true || response['result'] == 'success';
      }

      return true;
    } catch (e) {
      debugPrint('Error setting bandwidth limit: $e');
      return false;
    }
  }

  Future<bool> removeBandwidthLimit(String macAddress) async {
    try {
      if (_bandwidthControls.containsKey(macAddress)) {
        final control = _bandwidthControls[macAddress]!;

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

      if (_apiClient != null) {
        final response = await _apiClient!.post(
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

  Future<bool> setDevicePriority(
    String macAddress,
    PriorityLevel priority,
  ) async {
    try {
      if (_bandwidthControls.containsKey(macAddress)) {
        final control = _bandwidthControls[macAddress]!;

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

        await _dbService.insertOrUpdateBandwidthControl(updatedControl);
        _bandwidthControls[macAddress] = updatedControl;
        notifyListeners();
      }

      if (_apiClient != null) {
        final response = await _apiClient!.post(
          '/api/qos/priority',
          body: {
            'mac': macAddress,
            'priority': priority.toString().split('.').last,
          },
        );

        return response['success'] == true || response['result'] == 'success';
      }

      return true;
    } catch (e) {
      debugPrint('Error setting device priority: $e');
      return false;
    }
  }

  Future<void> refreshBandwidthControls() async {
    await _loadBandwidthControls();
  }

  // ==================== Parental Controls ====================

  Future<void> _loadParentalRules() async {
    try {
      _parentalRules = await _dbService.getAllParentalRules();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading parental rules: $e');
    }
  }

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

      if (_apiClient != null) {
        final response = await _apiClient!.post(
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

      if (_apiClient != null) {
        final response = await _apiClient!.put(
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

      if (_apiClient != null) {
        final response = await _apiClient!.delete(
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

  Future<void> loadParentalControls() async {
    await _loadParentalRules();
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
      _loadParentalRules(),
    ]);
  }

  // ==================== Router Control Methods ====================

  Future<bool> rebootRouter() async {
    try {
      if (_apiClient != null) {
        final response = await _apiClient!.post(
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
    try {
      await initialize(ip);
      // Implement actual login logic here
      // For now, assume success and load data
      await loadAllRouterData();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // ==================== Logout and Cleanup ====================

  @override
  void dispose() {
    _cleanupOldData();
    super.dispose();
  }

  Future<void> _cleanupOldData() async {
    await _dbService.cleanupOldTrafficData(30);
  }

  Future<void> logout() async {
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

      final index = _routerProfiles.indexWhere(
        (p) => p.id == _currentProfile!.id,
      );
      if (index != -1) {
        _routerProfiles[index] = updatedProfile;
      }

      notifyListeners();
    }

    _apiClient = null;
    _routerInfo = null;
    _signalInfo = null;
    _connectedDevices = [];
    _trafficInfo = null;
  }
}
