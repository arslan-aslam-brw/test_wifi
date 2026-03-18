import 'package:flutter/material.dart';
import '../models/signal_model.dart';

class SignalStrengthWidget extends StatelessWidget {
  final SignalModel signal;

  const SignalStrengthWidget({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Signal bars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              width: 30,
              height: 10 + (index * 8).toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index < signal.bars
                    ? _getSignalColor(index)
                    : Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Signal details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSignalDetail('RSSI', '${signal.rssi} dBm'),
            if (signal.rsrp != null)
              _buildSignalDetail('RSRP', '${signal.rsrp} dBm'),
            if (signal.rsrq != null)
              _buildSignalDetail('RSRQ', '${signal.rsrq} dB'),
            if (signal.sinr != null)
              _buildSignalDetail('SINR', '${signal.sinr} dB'),
          ],
        ),

        const SizedBox(height: 16),

        // Network info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            signal.networkType ?? 'Unknown Network',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSignalColor(int index) {
    if (index < 2) return Colors.orange;
    if (index < 3) return Colors.yellow.shade700;
    return Colors.green;
  }

  Widget _buildSignalDetail(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
