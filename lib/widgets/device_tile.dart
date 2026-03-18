import 'package:flutter/material.dart';
import '../models/device_model.dart';

class DeviceTile extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;
  final VoidCallback? onRename;

  const DeviceTile({
    super.key,
    required this.device,
    this.onBlock,
    this.onUnblock,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getDeviceColor().withOpacity(0.2),
              child: Icon(_getDeviceIcon(), color: _getDeviceColor()),
            ),
            if (!device.isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.wifi, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  device.ipAddress,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.memory, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  device.macAddress,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'block':
                onBlock?.call();
                break;
              case 'unblock':
                onUnblock?.call();
                break;
              case 'rename':
                onRename?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            if (device.isActive)
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block Device'),
                  ],
                ),
              )
            else
              const PopupMenuItem(
                value: 'unblock',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Unblock Device'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    final name = device.name.toLowerCase();
    if (name.contains('iphone') || name.contains('ipad')) {
      return Icons.phone_iphone;
    } else if (name.contains('android') || name.contains('galaxy')) {
      return Icons.android;
    } else if (name.contains('laptop') || name.contains('notebook')) {
      return Icons.laptop;
    } else if (name.contains('tv') || name.contains('television')) {
      return Icons.tv;
    } else if (name.contains('printer')) {
      return Icons.print;
    } else if (name.contains('camera')) {
      return Icons.videocam;
    } else {
      return Icons.devices;
    }
  }

  Color _getDeviceColor() {
    if (device.isActive) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }
}
