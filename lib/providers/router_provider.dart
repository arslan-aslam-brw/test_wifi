import 'dart:async';
import 'package:flutter/material.dart';
import '../services/base_api_client.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/network_service.dart';
import '../services/sms_service.dart';
import '../services/security_service.dart';
import '../models/router_model.dart';
import '../models/signal_model.dart';
import '../models/device_model.dart';
import '../models/traffic_model.dart';
import '../models/sms_model.dart';
import '../models/firewall_model.dart';

class RouterProvider extends ChangeNotifier {
  late BaseApiClient _apiClient;
  late AuthService _authService;
  late DeviceService _deviceService;
  late NetworkService _networkService;
  late SmsService _smsService;
  late SecurityService _securityService;

  // Data models
  RouterModel? _routerInfo;
  SignalModel? _signalInfo;
  List<DeviceModel> _connectedDevices = [];
  TrafficModel? _trafficInfo;
  List<SmsModel> _smsMessages = [];
  FirewallSettings? _firewallSettings;
  List<PortForwardRule> _portForwardRules = [];
  Map<String, dynamic>? _wanStatus;

  // UI state
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  Timer? _autoRefreshTimer;

  // Getters
  RouterModel? get routerInfo => _routerInfo;
  SignalModel? get signalInfo => _signalInfo;
  List<DeviceModel> get connectedDevices => _connectedDevices;
  TrafficModel? get trafficInfo => _trafficInfo;
  List<SmsModel> get smsMessages => _smsMessages;
  FirewallSettings? get firewallSettings => _firewallSettings;
  List<PortForwardRule> get portForwardRules => _portForwardRules;
  Map<String, dynamic>? get wanStatus => _wanStatus;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  Future<void> initialize(String ip) async {
    _apiClient = BaseApiClient(baseUrl: 'http://$ip');
    _authService = AuthService(apiClient: _apiClient);
    _deviceService = DeviceService(_apiClient);
    _networkService = NetworkService(_apiClient);
    _smsService = SmsService(_apiClient);
    _securityService = SecurityService(_apiClient);

    // Start auto-refresh every 30 seconds
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isLoading && !_isRefreshing) {
        refreshData();
      }
    });
  }

  Future<bool> login(String username, String password, String ip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(username, password, ip);

      if (success) {
        await loadAllData();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadRouterInfo(),
        _loadSignalInfo(),
        _loadConnectedDevices(),
        _loadTrafficInfo(),
        _loadSmsMessages(),
        _loadFirewallSettings(),
        _loadPortForwardRules(),
        _loadWanStatus(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadSignalInfo(),
        _loadConnectedDevices(),
        _loadTrafficInfo(),
        _loadWanStatus(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadRouterInfo() async {
    try {
      final response = await _apiClient.get('/api/device/information');
      _routerInfo = RouterModel.fromJson({
        'ip': _apiClient.baseUrl.replaceAll('http://', ''),
        ...response,
      });
    } catch (e) {
      debugPrint('Error loading router info: $e');
    }
  }

  Future<void> _loadSignalInfo() async {
    try {
      final response = await _apiClient.get('/api/device/signal');
      _signalInfo = SignalModel.fromJson(response);
    } catch (e) {
      debugPrint('Error loading signal info: $e');
    }
  }

  Future<void> _loadConnectedDevices() async {
    try {
      _connectedDevices = await _deviceService.getConnectedDevices();
    } catch (e) {
      debugPrint('Error loading devices: $e');
    }
  }

  Future<void> _loadTrafficInfo() async {
    try {
      _trafficInfo = await _networkService.getTrafficStats();
    } catch (e) {
      debugPrint('Error loading traffic: $e');
    }
  }

  Future<void> _loadSmsMessages() async {
    try {
      _smsMessages = await _smsService.getSmsList();
    } catch (e) {
      debugPrint('Error loading SMS: $e');
    }
  }

  Future<void> _loadFirewallSettings() async {
    try {
      _firewallSettings = await _securityService.getFirewallSettings();
    } catch (e) {
      debugPrint('Error loading firewall: $e');
    }
  }

  Future<void> _loadPortForwardRules() async {
    try {
      _portForwardRules = await _securityService.getPortForwardRules();
    } catch (e) {
      debugPrint('Error loading port forwarding: $e');
    }
  }

  Future<void> _loadWanStatus() async {
    try {
      _wanStatus = await _networkService.getWanStatus();
    } catch (e) {
      debugPrint('Error loading WAN status: $e');
    }
  }

  // Device Management
  Future<bool> blockDevice(String macAddress) async {
    try {
      final success = await _deviceService.blockDevice(macAddress);
      if (success) {
        await _loadConnectedDevices();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unblockDevice(String macAddress) async {
    try {
      final success = await _deviceService.unblockDevice(macAddress);
      if (success) {
        await _loadConnectedDevices();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // WiFi Management
  Future<bool> updateWifiSettings({
    required String ssid,
    String? password,
    bool? hideSsid,
    String? band,
  }) async {
    try {
      final success = await _networkService.updateWifiSettings(
        ssid: ssid,
        password: password,
        hideSsid: hideSsid,
        band: band,
      );
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // SMS Management
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final success = await _smsService.sendSms(phoneNumber, message);
      if (success) {
        await _loadSmsMessages();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSms(List<String> smsIds) async {
    try {
      final success = await _smsService.deleteSms(smsIds);
      if (success) {
        await _loadSmsMessages();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Port Forwarding
  Future<bool> addPortForwardRule(PortForwardRule rule) async {
    try {
      final success = await _securityService.addPortForwardRule(rule);
      if (success) {
        await _loadPortForwardRules();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removePortForwardRule(String ruleId) async {
    try {
      final success = await _securityService.removePortForwardRule(ruleId);
      if (success) {
        await _loadPortForwardRules();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Router Management
  Future<bool> rebootRouter() async {
    try {
      final response = await _apiClient.post(
        '/api/device/control',
        body: {'control': 'reboot'},
      );

      if (response['success'] == true) {
        // Clear session as router will reboot
        await Future.delayed(const Duration(seconds: 5));
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _autoRefreshTimer?.cancel();
    _routerInfo = null;
    _signalInfo = null;
    _connectedDevices = [];
    _trafficInfo = null;
    _smsMessages = [];
    _firewallSettings = null;
    _portForwardRules = [];
    _wanStatus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
