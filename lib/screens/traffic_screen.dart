import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/router_provider.dart';

class TrafficScreen extends StatefulWidget {
  const TrafficScreen({super.key});

  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  String _timeRange = 'realtime'; // realtime, hourly, daily, monthly
  List<TrafficDataPoint> _trafficHistory = [];

  @override
  void initState() {
    super.initState();
    _loadTrafficHistory();
  }

  Future<void> _loadTrafficHistory() async {
    // Load traffic history based on selected time range
    // This would come from the router API
    _trafficHistory = _generateMockData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Monitor'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeRangeChip('Realtime', 'realtime'),
                _buildTimeRangeChip('Hourly', 'hourly'),
                _buildTimeRangeChip('Daily', 'daily'),
                _buildTimeRangeChip('Monthly', 'monthly'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<RouterProvider>(
        builder: (context, provider, child) {
          if (provider.trafficInfo == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current speeds card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Current Speeds',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSpeedIndicator(
                                'Download',
                                '${_formatBytes(provider.trafficInfo!.currentDownloadRate)}/s',
                                Icons.arrow_downward,
                                Colors.blue,
                              ),
                              _buildSpeedIndicator(
                                'Upload',
                                '${_formatBytes(provider.trafficInfo!.currentUploadRate)}/s',
                                Icons.arrow_upward,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Traffic chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Traffic History ($_timeRange)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (_timeRange == 'realtime') {
                                          return Text('${value.toInt()}s');
                                        } else if (_timeRange == 'hourly') {
                                          return Text('${value.toInt()}:00');
                                        }
                                        return Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          _formatBytes(value.toInt()),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _trafficHistory.asMap().entries.map((
                                      e,
                                    ) {
                                      return FlSpot(
                                        e.key.toDouble(),
                                        e.value.download.toDouble(),
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    dotData: FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: _trafficHistory.asMap().entries.map((
                                      e,
                                    ) {
                                      return FlSpot(
                                        e.key.toDouble(),
                                        e.value.upload.toDouble(),
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.orange,
                                    barWidth: 3,
                                    dotData: FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem('Download', Colors.blue),
                              const SizedBox(width: 20),
                              _buildLegendItem('Upload', Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Data usage summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Usage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildUsageRow(
                            'Total Download',
                            _formatBytes(provider.trafficInfo!.totalDownload),
                            Icons.download_done,
                            Colors.blue,
                          ),
                          const Divider(),
                          _buildUsageRow(
                            'Total Upload',
                            _formatBytes(provider.trafficInfo!.totalUpload),
                            Icons.upload,
                            Colors.orange,
                          ),
                          const Divider(),
                          _buildUsageRow(
                            'Total Usage',
                            _formatBytes(
                              provider.trafficInfo!.totalDownload +
                                  provider.trafficInfo!.totalUpload,
                            ),
                            Icons.data_usage,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Connection info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Connection Time',
                            _formatDuration(
                              provider.trafficInfo!.connectionTime,
                            ),
                            Icons.timer,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'WAN IP',
                            provider.wanStatus?['WanIPAddress'] ?? 'Unknown',
                            Icons.public,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'DNS Server',
                            provider.wanStatus?['PrimaryDns'] ?? 'Unknown',
                            Icons.dns,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _timeRange == value,
      onSelected: (_) {
        setState(() {
          _timeRange = value;
          _loadTrafficHistory();
        });
      },
    );
  }

  Widget _buildSpeedIndicator(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildUsageRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: TextStyle(color: Colors.grey.shade800)),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else {
      return '$minutes minutes';
    }
  }

  List<TrafficDataPoint> _generateMockData() {
    final List<TrafficDataPoint> data = [];
    final now = DateTime.now();

    for (int i = 0; i < 20; i++) {
      data.add(
        TrafficDataPoint(
          timestamp: now.subtract(Duration(minutes: 20 - i)),
          download: 100000 + (i * 5000) + (i % 5) * 10000,
          upload: 50000 + (i * 2000) + (i % 3) * 8000,
        ),
      );
    }

    return data;
  }
}

class TrafficDataPoint {
  final DateTime timestamp;
  final int download;
  final int upload;

  TrafficDataPoint({
    required this.timestamp,
    required this.download,
    required this.upload,
  });
}
