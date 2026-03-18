import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test_wifi/utils/database_management_screen.dart';
import '../providers/router_provider_extended.dart';
import '../providers/settings_provider.dart';
import '../utils/database_backup.dart';
import '../utils/database_location.dart';
import '../utils/helpers.dart';
import 'router_selection_screen.dart';
import 'bandwidth_control_screen.dart';
import 'parental_control_screen.dart';

class ExtendedSettingsScreen extends StatefulWidget {
  const ExtendedSettingsScreen({super.key});

  @override
  State<ExtendedSettingsScreen> createState() => _ExtendedSettingsScreenState();
}

class _ExtendedSettingsScreenState extends State<ExtendedSettingsScreen> {
  bool _isLoading = false;
  String _databaseSize = 'Unknown';
  int _routerCount = 0;
  int _parentalRuleCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );

    setState(() {
      _routerCount = provider.routerProfiles.length;
      _parentalRuleCount = provider.parentalRules.length;
    });

    // Get database size
    final size = await DatabaseLocation.getFormattedDatabaseSize();
    setState(() {
      _databaseSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExtendedRouterProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Router Information Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Router Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Model',
                          provider.routerInfo?.model ?? 'Unknown',
                          Icons.devices,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Serial Number',
                          provider.routerInfo?.serialNumber ?? 'Unknown',
                          Icons.confirmation_number,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Firmware Version',
                          provider.routerInfo?.firmwareVersion ?? 'Unknown',
                          Icons.system_update,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Hardware Version',
                          provider.routerInfo?.hardwareVersion ?? 'Unknown',
                          Icons.memory,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'MAC Address',
                          provider.routerInfo?.macAddress ?? 'Unknown',
                          Icons.wifi,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Settings Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'App Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Enable dark theme'),
                        value: settingsProvider.isDarkMode,
                        onChanged: (value) {
                          settingsProvider.toggleDarkMode();
                        },
                        secondary: const Icon(Icons.dark_mode),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Auto Refresh'),
                        subtitle: const Text('Automatically refresh data'),
                        value: settingsProvider.autoRefresh,
                        onChanged: (value) {
                          settingsProvider.toggleAutoRefresh();
                        },
                        secondary: const Icon(Icons.refresh),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Refresh Interval'),
                        subtitle: Text(
                          '${settingsProvider.refreshInterval} seconds',
                        ),
                        leading: const Icon(Icons.timer),
                        trailing: DropdownButton<int>(
                          value: settingsProvider.refreshInterval,
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15s')),
                            DropdownMenuItem(value: 30, child: Text('30s')),
                            DropdownMenuItem(value: 60, child: Text('60s')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setRefreshInterval(value);
                            }
                          },
                        ),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Notifications'),
                        subtitle: const Text('Show push notifications'),
                        value: settingsProvider.notificationsEnabled,
                        onChanged: (value) {
                          settingsProvider.toggleNotifications();
                        },
                        secondary: const Icon(Icons.notifications),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Biometric Authentication Section
                if (provider.biometricAvailable)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Biometric Login'),
                          subtitle: const Text(
                            'Use fingerprint or face to login',
                          ),
                          value: provider.biometricEnabled,
                          onChanged: (value) {
                            if (value) {
                              _enableBiometrics(context, provider);
                            } else {
                              provider.toggleBiometric(false);
                            }
                          },
                          secondary: const Icon(Icons.fingerprint),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Router Management Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Router Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.router, color: Colors.blue),
                        title: const Text('Manage Routers'),
                        subtitle: Text('${_routerCount} router(s) configured'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RouterSelectionScreen(),
                            ),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.wifi, color: Colors.blue),
                        title: const Text('WiFi Settings'),
                        subtitle: const Text('Configure WiFi network'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/wifi');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.security,
                          color: Colors.green,
                        ),
                        title: const Text('Firewall Settings'),
                        subtitle: const Text('Configure firewall rules'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showFirewallSettings(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.settings_ethernet,
                          color: Colors.orange,
                        ),
                        title: const Text('Port Forwarding'),
                        subtitle: const Text('Manage port forwarding rules'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showPortForwarding(context);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Advanced Features Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Advanced Features',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.speed, color: Colors.purple),
                        title: const Text('Bandwidth Control'),
                        subtitle: const Text('Manage speed limits per device'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BandwidthControlScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.family_restroom,
                          color: Colors.green,
                        ),
                        title: const Text('Parental Controls'),
                        subtitle: Text('${_parentalRuleCount} active rule(s)'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentalControlScreen(),
                            ),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.local_laundry_service_outlined,
                          color: Colors.teal,
                        ),
                        title: const Text('QoS Settings'),
                        subtitle: const Text(
                          'Quality of Service configuration',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showQosSettings(context);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // NEW: Data Management Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Data Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.storage, color: Colors.blue),
                        title: const Text('Database Management'),
                        subtitle: Text(
                          'Size: $_databaseSize • $_routerCount routers',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DatabaseManagementScreen(),
                            ),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const Divider(),

                      // NEW: Backup Option
                      ListTile(
                        leading: const Icon(Icons.backup, color: Colors.green),
                        title: const Text('Backup & Restore'),
                        subtitle: const Text('Backup or restore your data'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showBackupDialog(context),
                      ),
                      const Divider(),

                      // NEW: Export Data Option
                      ListTile(
                        leading: const Icon(
                          Icons.analytics,
                          color: Colors.orange,
                        ),
                        title: const Text('Export Data'),
                        subtitle: const Text('Export as JSON for analysis'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _exportData(),
                      ),
                      const Divider(),

                      ListTile(
                        leading: const Icon(
                          Icons.storage,
                          color: Colors.purple,
                        ),
                        title: const Text('Database Management'),
                        subtitle: const Text('View and manage local database'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DatabaseManagementScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),

                      // NEW: Clear Data Option
                      ListTile(
                        leading: const Icon(
                          Icons.delete_sweep,
                          color: Colors.red,
                        ),
                        title: const Text('Clear All Data'),
                        subtitle: const Text('Delete all stored information'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showClearDataDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Router Maintenance Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Router Maintenance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.update, color: Colors.purple),
                        title: const Text('Firmware Update'),
                        subtitle: const Text('Check for updates'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _checkForUpdates(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.restart_alt,
                          color: Colors.red,
                        ),
                        title: const Text('Reboot Router'),
                        subtitle: const Text('Restart your router'),
                        onTap: () {
                          _showRebootDialog(context, provider);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // About Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('App Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Show privacy policy
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Logout'),
                        onTap: () {
                          _showLogoutDialog(context, provider);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  // NEW: Backup Dialog
  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.blue),
              title: const Text('Create Backup'),
              subtitle: const Text('Save a copy of your data'),
              onTap: () async {
                Navigator.pop(context);
                await _createBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.green),
              title: const Text('Restore from Backup'),
              subtitle: const Text('Restore data from backup file'),
              onTap: () {
                Navigator.pop(context);
                _restoreFromBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Share Backup'),
              subtitle: const Text('Share database file'),
              onTap: () async {
                Navigator.pop(context);
                await DatabaseBackup.shareBackup();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // NEW: Create Backup
  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      final backupFile = await DatabaseBackup.createBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created: ${backupFile.path.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'SHARE',
              onPressed: () async {
                await Share.shareXFiles([
                  backupFile.path as XFile,
                ], text: 'Router Manager Backup');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Restore from Backup
  Future<void> _restoreFromBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null) {
        setState(() => _isLoading = true);

        final filePath = result.files.single.path!;
        final success = await DatabaseBackup.restoreBackup(filePath);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore successful. Please restart app.'),
              backgroundColor: Colors.green,
            ),
          );

          // Reload provider data
          final provider = Provider.of<ExtendedRouterProvider>(
            context,
            listen: false,
          );
          await provider.loadAllData();
          await _loadStats();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Export Data
  Future<void> _exportData() async {
    setState(() => _isLoading = true);

    try {
      await DatabaseBackup.exportToJson();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Clear Data Dialog
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all stored data?\n\n'
          'This includes:\n'
          '• All router profiles\n'
          '• Bandwidth control settings\n'
          '• Parental control rules\n'
          '• App settings\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                await DatabaseBackup.clearAllData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate to login
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // Existing Methods (from previous code)
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _enableBiometrics(
    BuildContext context,
    ExtendedRouterProvider provider,
  ) async {
    final authenticated = await provider.authenticateWithBiometrics();

    if (authenticated && mounted) {
      provider.toggleBiometric(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login enabled'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFirewallSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firewall Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Security Level'),
              subtitle: const Text('Low, Medium, High'),
              trailing: DropdownButton<String>(
                value: 'medium',
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {},
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('IP Filtering'),
              value: true,
              onChanged: (value) {},
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('MAC Filtering'),
              value: true,
              onChanged: (value) {},
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('DoS Protection'),
              value: true,
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPortForwarding(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Port Forwarding',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddPortRuleDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('No port forwarding rules configured'),
          ],
        ),
      ),
    );
  }

  void _showAddPortRuleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Port Forwarding Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Rule Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'External Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Internal Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Internal IP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: 'TCP',
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'TCP', child: Text('TCP')),
                  DropdownMenuItem(value: 'UDP', child: Text('UDP')),
                  DropdownMenuItem(value: 'BOTH', child: Text('TCP/UDP')),
                ],
                onChanged: (value) {},
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rule added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQosSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QoS Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'Traffic Prioritization',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SwitchListTile(
              title: const Text('Enable QoS'),
              value: true,
              onChanged: (value) {},
            ),

            const Divider(),

            const Text(
              'Application Prioritization',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(
              title: const Text('Video Streaming'),
              trailing: DropdownButton<String>(
                value: 'High',
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) {},
              ),
            ),

            ListTile(
              title: const Text('Gaming'),
              trailing: DropdownButton<String>(
                value: 'High',
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) {},
              ),
            ),

            ListTile(
              title: const Text('Web Browsing'),
              trailing: DropdownButton<String>(
                value: 'Normal',
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) {},
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRebootDialog(
    BuildContext context,
    ExtendedRouterProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reboot Router'),
        content: const Text(
          'Are you sure you want to reboot the router? All connections will be disconnected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show progress dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final success = await provider.rebootRouter();

              if (context.mounted) {
                Navigator.pop(context); // Close progress dialog

                if (success) {
                  // Navigate to login screen
                  Navigator.pushReplacementNamed(context, '/login');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Router is rebooting...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reboot router'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reboot'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    ExtendedRouterProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await provider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firmware Update'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking for updates...'),
          ],
        ),
      ),
    );

    // Simulate update check
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Firmware Update'),
            content: const Text('Your router firmware is up to date.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }
}
