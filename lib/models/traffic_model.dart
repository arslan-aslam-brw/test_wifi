class TrafficModel {
  final int currentUpload;
  final int currentDownload;
  final int totalUpload;
  final int totalDownload;
  final int currentUploadRate;
  final int currentDownloadRate;
  final int connectionTime;
  final List<TrafficHistoryPoint>? history;

  TrafficModel({
    required this.currentUpload,
    required this.currentDownload,
    required this.totalUpload,
    required this.totalDownload,
    required this.currentUploadRate,
    required this.currentDownloadRate,
    required this.connectionTime,
    this.history,
  });

  factory TrafficModel.fromJson(Map<String, dynamic> json) {
    return TrafficModel(
      currentUpload: int.tryParse(json['CurrentUpload'] ?? '0') ?? 0,
      currentDownload: int.tryParse(json['CurrentDownload'] ?? '0') ?? 0,
      totalUpload: int.tryParse(json['TotalUpload'] ?? '0') ?? 0,
      totalDownload: int.tryParse(json['TotalDownload'] ?? '0') ?? 0,
      currentUploadRate: int.tryParse(json['CurrentUploadRate'] ?? '0') ?? 0,
      currentDownloadRate:
          int.tryParse(json['CurrentDownloadRate'] ?? '0') ?? 0,
      connectionTime: int.tryParse(json['CurrentConnectTime'] ?? '0') ?? 0,
    );
  }
}

class TrafficHistoryPoint {
  final DateTime timestamp;
  final int upload;
  final int download;

  TrafficHistoryPoint({
    required this.timestamp,
    required this.upload,
    required this.download,
  });
}
