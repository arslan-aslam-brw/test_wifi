import '../models/traffic_model.dart';
import 'base_api_client.dart';

class NetworkService {
  final BaseApiClient _apiClient;

  NetworkService(this._apiClient);

  Future<TrafficModel> getTrafficStats() async {
    try {
      final response = await _apiClient.get(
        '/api/monitoring/traffic-statistics',
      );
      return TrafficModel.fromJson(response);
    } catch (e) {
      return TrafficModel(
        currentUpload: 0,
        currentDownload: 0,
        totalUpload: 0,
        totalDownload: 0,
        currentUploadRate: 0,
        currentDownloadRate: 0,
        connectionTime: 0,
      );
    }
  }

  Future<Map<String, dynamic>> getWifiSettings() async {
    try {
      final response = await _apiClient.get('/api/wlan/basic-settings');
      return response;
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateWifiSettings({
    required String ssid,
    String? password,
    bool? hideSsid,
    String? band,
  }) async {
    try {
      // Update SSID
      await _apiClient.post(
        '/api/wlan/basic-settings',
        body: {
          'ssid': ssid,
          'ssid_hidden': hideSsid ?? false,
          'wifi_band': band ?? '2.4g',
          'csrf_token': _apiClient.csrfToken,
        },
      );

      // Update password if provided
      if (password != null && password.isNotEmpty) {
        await _apiClient.post(
          '/api/wlan/security-settings',
          body: {'wpa_psk': password, 'csrf_token': _apiClient.csrfToken},
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getWanStatus() async {
    try {
      final response = await _apiClient.get('/api/monitoring/status');
      return response;
    } catch (e) {
      return {};
    }
  }
}
