import 'dart:convert';
import '../models/device_model.dart';
import 'base_api_client.dart';

class DeviceService {
  final BaseApiClient _apiClient;

  DeviceService(this._apiClient);

  Future<List<DeviceModel>> getConnectedDevices() async {
    try {
      final response = await _apiClient.get('/api/lan/connected-devices');
      return _parseDevices(response);
    } catch (e) {
      // Try alternative endpoint
      try {
        final response = await _apiClient.get('/api/lan/dhcp-clients');
        return _parseDevices(response);
      } catch (e) {
        return [];
      }
    }
  }

  List<DeviceModel> _parseDevices(Map<String, dynamic> data) {
    final List<DeviceModel> devices = [];

    // Handle different response formats
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

  Future<bool> blockDevice(String macAddress) async {
    try {
      final response = await _apiClient.post(
        '/api/security/mac-filter',
        body: {
          'mac': macAddress,
          'rule': 'block',
          'csrf_token': _apiClient.csrfToken,
        },
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unblockDevice(String macAddress) async {
    try {
      final response = await _apiClient.post(
        '/api/security/mac-filter',
        body: {
          'mac': macAddress,
          'rule': 'allow',
          'csrf_token': _apiClient.csrfToken,
        },
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
