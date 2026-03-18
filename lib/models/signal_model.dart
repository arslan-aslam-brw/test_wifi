class SignalModel {
  final int rssi;
  final int? rsrp;
  final int? rsrq;
  final int? sinr;
  final String? networkType;
  final String? band;
  final String? cellId;
  final int bars;

  SignalModel({
    required this.rssi,
    this.rsrp,
    this.rsrq,
    this.sinr,
    this.networkType,
    this.band,
    this.cellId,
    required this.bars,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) {
    int rssi = int.tryParse(json['rssi']?.toString() ?? '-100') ?? -100;

    return SignalModel(
      rssi: rssi,
      rsrp: int.tryParse(json['rsrp']?.toString() ?? ''),
      rsrq: int.tryParse(json['rsrq']?.toString() ?? ''),
      sinr: int.tryParse(json['sinr']?.toString() ?? ''),
      networkType: json['network_type'],
      band: json['bands'],
      cellId: json['cell_id'],
      bars: _calculateBars(rssi),
    );
  }

  static int _calculateBars(int rssi) {
    if (rssi >= -70) return 4;
    if (rssi >= -80) return 3;
    if (rssi >= -90) return 2;
    if (rssi >= -100) return 1;
    return 0;
  }
}
