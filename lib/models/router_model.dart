class RouterModel {
  final String ip;
  final String? name;
  final String? model;
  final String? macAddress;
  final String? serialNumber;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final int? uptime;
  final bool isConnected;

  RouterModel({
    required this.ip,
    this.name,
    this.model,
    this.macAddress,
    this.serialNumber,
    this.firmwareVersion,
    this.hardwareVersion,
    this.uptime,
    this.isConnected = false,
  });

  factory RouterModel.fromJson(Map<String, dynamic> json) {
    return RouterModel(
      ip: json['ip'] ?? '',
      name: json['name'],
      model: json['model'],
      macAddress: json['macAddress'],
      serialNumber: json['serialNumber'],
      firmwareVersion: json['firmwareVersion'],
      hardwareVersion: json['hardwareVersion'],
      uptime: json['uptime'],
      isConnected: json['isConnected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'name': name,
      'model': model,
      'macAddress': macAddress,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'uptime': uptime,
      'isConnected': isConnected,
    };
  }
}
