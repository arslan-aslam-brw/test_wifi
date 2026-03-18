import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/router_provider_extended.dart';
import '../models/user_bandwidth.dart';
import '../models/device_model.dart';

class BandwidthControlScreen extends StatefulWidget {
  const BandwidthControlScreen({super.key});

  @override
  State<BandwidthControlScreen> createState() => _BandwidthControlScreenState();
}

class _BandwidthControlScreenState extends State<BandwidthControlScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, limited, unlimited
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );
    await provider.refreshBandwidthControls();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );
    await provider.refreshBandwidthControls();

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandwidth Control'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search devices...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterType == 'all',
                        onSelected: (_) => setState(() => _filterType = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Limited'),
                        selected: _filterType == 'limited',
                        onSelected: (_) =>
                            setState(() => _filterType = 'limited'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Unlimited'),
                        selected: _filterType == 'unlimited',
                        onSelected: (_) =>
                            setState(() => _filterType = 'unlimited'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<ExtendedRouterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || _isRefreshing) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get devices from provider - you may need to add a method to get connected devices
          final devices = _getDevicesFromProvider(provider);
          final filteredDevices = _filterDevices(
            devices,
            provider.bandwidthControls,
          );

          if (filteredDevices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No devices found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDevices.length,
              itemBuilder: (context, index) {
                final device = filteredDevices[index];
                final control = provider.bandwidthControls[device.macAddress];
                return _buildDeviceBandwidthCard(device, control, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshData,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  // Helper method to get devices - you may need to modify this based on your provider
  List<DeviceModel> _getDevicesFromProvider(ExtendedRouterProvider provider) {
    // If provider has connectedDevices getter, use it
    // Otherwise, create mock devices or get from bandwidth controls
    if (provider.connectedDevices.isNotEmpty) {
      return provider.connectedDevices;
    }

    // Create devices from bandwidth controls if no connected devices
    return provider.bandwidthControls.values.map((control) {
      return DeviceModel(
        macAddress: control.macAddress,
        ipAddress: '192.168.1.x', // Placeholder
        name: control.deviceName,
        hostname: control.deviceName,
        isActive: true,
      );
    }).toList();
  }

  List<DeviceModel> _filterDevices(
    List<DeviceModel> devices,
    Map<String, UserBandwidthControl> controls,
  ) {
    return devices.where((device) {
      final control = controls[device.macAddress];

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final name = device.name.toLowerCase();
        final ip = device.ipAddress.toLowerCase();
        final mac = device.macAddress.toLowerCase();
        if (!name.contains(_searchQuery) &&
            !ip.contains(_searchQuery) &&
            !mac.contains(_searchQuery)) {
          return false;
        }
      }

      // Apply type filter
      switch (_filterType) {
        case 'limited':
          return control?.isLimited ?? false;
        case 'unlimited':
          return !(control?.isLimited ?? false);
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildDeviceBandwidthCard(
    DeviceModel device,
    UserBandwidthControl? control,
    ExtendedRouterProvider provider,
  ) {
    final isLimited = control?.isLimited ?? false;
    final uploadLimit = control?.uploadLimit ?? 0;
    final downloadLimit = control?.downloadLimit ?? 0;
    final priority = control?.priority ?? PriorityLevel.normal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: device.isActive
              ? Colors.green.shade100
              : Colors.grey.shade100,
          child: Icon(
            Icons.devices,
            color: device.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.ipAddress),
            if (control != null && control.hasRestrictions)
              Text(
                control.getSummary(),
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bandwidth limit switch
                SwitchListTile(
                  title: const Text('Bandwidth Limit'),
                  subtitle: const Text('Enable bandwidth control'),
                  value: isLimited,
                  onChanged: (value) async {
                    if (value) {
                      _showBandwidthDialog(context, device, control, provider);
                    } else {
                      await provider.removeBandwidthLimit(device.macAddress);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bandwidth limit removed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),

                if (isLimited) ...[
                  const Divider(),

                  // Current limits
                  ListTile(
                    title: const Text('Download Limit'),
                    subtitle: Text(_formatSpeed(downloadLimit)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showBandwidthDialog(
                        context,
                        device,
                        control,
                        provider,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Upload Limit'),
                    subtitle: Text(_formatSpeed(uploadLimit)),
                  ),

                  const Divider(),

                  // Priority selector
                  const Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPriorityButton(
                        'High',
                        PriorityLevel.high,
                        priority,
                        device.macAddress,
                        provider,
                      ),
                      _buildPriorityButton(
                        'Normal',
                        PriorityLevel.normal,
                        priority,
                        device.macAddress,
                        provider,
                      ),
                      _buildPriorityButton(
                        'Low',
                        PriorityLevel.low,
                        priority,
                        device.macAddress,
                        provider,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityButton(
    String label,
    PriorityLevel level,
    PriorityLevel currentLevel,
    String macAddress,
    ExtendedRouterProvider provider,
  ) {
    final isSelected = level == currentLevel;

    return ElevatedButton(
      onPressed: () async {
        final success = await provider.setDevicePriority(macAddress, level);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Priority updated to $label'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        minimumSize: const Size(80, 36),
      ),
      child: Text(label),
    );
  }

  void _showBandwidthDialog(
    BuildContext context,
    DeviceModel device,
    UserBandwidthControl? control,
    ExtendedRouterProvider provider,
  ) {
    final downloadController = TextEditingController(
      text: (control?.downloadLimit ?? 0).toString(),
    );
    final uploadController = TextEditingController(
      text: (control?.uploadLimit ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bandwidth Limit for ${device.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: downloadController,
                decoration: const InputDecoration(
                  labelText: 'Download Limit (Kbps)',
                  border: OutlineInputBorder(),
                  suffixText: 'Kbps',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter download limit';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: uploadController,
                decoration: const InputDecoration(
                  labelText: 'Upload Limit (Kbps)',
                  border: OutlineInputBorder(),
                  suffixText: 'Kbps',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter upload limit';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final download = int.parse(downloadController.text);
                final upload = int.parse(uploadController.text);

                final success = await provider.setBandwidthLimit(
                  device.macAddress,
                  upload,
                  download,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bandwidth limit applied'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to apply limit'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  String _formatSpeed(int kbps) {
    if (kbps < 1024) return '$kbps Kbps';
    return '${(kbps / 1024).toStringAsFixed(1)} Mbps';
  }
}
