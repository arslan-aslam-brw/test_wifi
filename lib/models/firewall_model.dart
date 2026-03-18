class FirewallSettings {
  final String level;
  final bool ipFilterEnabled;
  final bool macFilterEnabled;
  final bool dosProtectionEnabled;

  FirewallSettings({
    required this.level,
    required this.ipFilterEnabled,
    required this.macFilterEnabled,
    required this.dosProtectionEnabled,
  });

  factory FirewallSettings.fromJson(Map<String, dynamic> json) {
    return FirewallSettings(
      level: json['level'] ?? 'medium',
      ipFilterEnabled:
          json['ip_filter'] == '1' || json['ipFilterEnabled'] == true,
      macFilterEnabled:
          json['mac_filter'] == '1' || json['macFilterEnabled'] == true,
      dosProtectionEnabled:
          json['dos'] == '1' || json['dosProtectionEnabled'] == true,
    );
  }
}

class PortForwardRule {
  final String? id;
  final String name;
  final int externalPort;
  final int internalPort;
  final String protocol;
  final String internalIp;
  final bool enabled;

  PortForwardRule({
    this.id,
    required this.name,
    required this.externalPort,
    required this.internalPort,
    required this.protocol,
    required this.internalIp,
    required this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'external_port': externalPort,
      'internal_port': internalPort,
      'protocol': protocol,
      'internal_ip': internalIp,
      'enabled': enabled,
    };
  }

  factory PortForwardRule.fromJson(Map<String, dynamic> json) {
    return PortForwardRule(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      externalPort: int.tryParse(json['external_port']?.toString() ?? '0') ?? 0,
      internalPort: int.tryParse(json['internal_port']?.toString() ?? '0') ?? 0,
      protocol: json['protocol'] ?? 'TCP',
      internalIp: json['internal_ip'] ?? '',
      enabled: json['enabled'] == '1' || json['enabled'] == true,
    );
  }
}
