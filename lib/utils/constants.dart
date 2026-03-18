class AppConstants {
  static const String appName = 'Huawei Router Manager';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String apiDeviceInfo = '/api/device/information';
  static const String apiDeviceSignal = '/api/device/signal';
  static const String apiDeviceControl = '/api/device/control';
  static const String apiLogin = '/api/system/user_login';
  static const String apiLogout = '/api/system/user_logout';
  static const String apiHeartbeat = '/api/system/heartbeat';
  static const String apiTrafficStats = '/api/monitoring/traffic-statistics';
  static const String apiConnectedDevices = '/api/lan/connected-devices';
  static const String apiWifiSettings = '/api/wlan/basic-settings';
  static const String apiWifiSecurity = '/api/wlan/security-settings';
  static const String apiSmsList = '/api/sms/sms-list';
  static const String apiSendSms = '/api/sms/send-sms';
  static const String apiFirewall = '/api/security/firewall-settings';
  static const String apiPortForwarding = '/api/security/port-forwarding';

  // Default credentials
  static const List<Map<String, String>> defaultCredentials = [
    {'username': 'admin', 'password': 'admin'},
    {'username': 'admin', 'password': 'password'},
    {'username': 'root', 'password': 'admin'},
    {'username': 'admin', 'password': ''},
    {'username': 'user', 'password': 'user'},
    {'username': 'telecomadmin', 'password': 'admintelecom'},
  ];

  // Default IPs
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
}
