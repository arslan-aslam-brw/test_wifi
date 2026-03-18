import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/router_model.dart';

class RouterDiscovery {
  static const List<String> defaultIPs = [
    '192.168.1.1',
    '192.168.3.1',
    '192.168.8.1',
    '192.168.0.1',
    '192.168.100.1',
    '192.168.2.1',
    '10.0.0.1',
    '192.168.18.1',
  ];

  static const List<Map<String, String>> defaultCredentials = [
    {'username': 'admin', 'password': 'admin'},
    {'username': 'admin', 'password': 'password'},
    {'username': 'root', 'password': 'admin'},
    {'username': 'admin', 'password': ''},
    {'username': 'user', 'password': 'user'},
    {'username': 'telecomadmin', 'password': 'admintelecom'},
  ];

  static Future<List<RouterModel>> discoverRouters() async {
    final List<RouterModel> discovered = [];

    // Get current network info
    final info = NetworkInfo();
    final wifiIP = await info.getWifiIP();

    if (wifiIP != null) {
      // Scan common IPs in the same subnet
      final subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.') + 1);

      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet$i';
        if (defaultIPs.contains(ip)) {
          final router = await _checkRouter(ip);
          if (router != null) {
            discovered.add(router);
          }
        }
      }
    }

    // Also check default IPs
    for (final ip in defaultIPs) {
      if (!discovered.any((r) => r.ip == ip)) {
        final router = await _checkRouter(ip);
        if (router != null) {
          discovered.add(router);
        }
      }
    }

    return discovered;
  }

  static Future<RouterModel?> _checkRouter(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      final request = await client.getUrl(
        Uri.parse('http://$ip/api/device/information'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        return RouterModel(
          ip: ip,
          name: data['DeviceName'] ?? 'Huawei Router',
          model: data['ProductFamily'],
          macAddress: data['MacAddress1'],
          serialNumber: data['SerialNumber'],
          firmwareVersion: data['SoftwareVersion'],
          hardwareVersion: data['HardwareVersion'],
          isConnected: true,
        );
      }

      client.close();
      return null;
    } catch (e) {
      return null;
    }
  }
}
