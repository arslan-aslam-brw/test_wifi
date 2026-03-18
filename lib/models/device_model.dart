class DeviceModel {
  final String macAddress;
  final String ipAddress;
  final String name;
  final String hostname;
  final String? interface;
  final bool isActive;
  final int? signalStrength;
  final int? uploadSpeed;
  final int? downloadSpeed;
  final Duration? connectionTime;

  DeviceModel({
    required this.macAddress,
    required this.ipAddress,
    required this.name,
    required this.hostname,
    this.interface,
    this.isActive = true,
    this.signalStrength,
    this.uploadSpeed,
    this.downloadSpeed,
    this.connectionTime,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      macAddress: json['mac'] ?? json['MacAddress'] ?? '',
      ipAddress: json['ip'] ?? json['IpAddress'] ?? '',
      name: json['name'] ?? json['hostname'] ?? 'Unknown Device',
      hostname: json['hostname'] ?? json['name'] ?? '',
      interface: json['interface'],
      isActive: json['active'] ?? json['isActive'] ?? true,
      signalStrength: json['signal'] != null
          ? int.tryParse(json['signal'].toString())
          : null,
    );
  }
}
