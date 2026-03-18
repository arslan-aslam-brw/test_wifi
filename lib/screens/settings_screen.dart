import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/router_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final routerProvider = Provider.of<RouterProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
                    routerProvider.routerInfo?.model ?? 'Unknown',
                    Icons.devices,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Serial Number',
                    routerProvider.routerInfo?.serialNumber ?? 'Unknown',
                    Icons.confirmation_number,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Firmware Version',
                    routerProvider.routerInfo?.firmwareVersion ?? 'Unknown',
                    Icons.system_update,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Hardware Version',
                    routerProvider.routerInfo?.hardwareVersion ?? 'Unknown',
                    Icons.memory,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'MAC Address',
                    routerProvider.routerInfo?.macAddress ?? 'Unknown',
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
                  subtitle: Text('${settingsProvider.refreshInterval} seconds'),
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
                  leading: const Icon(Icons.security, color: Colors.green),
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
                const Divider(),
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
                  leading: const Icon(Icons.restart_alt, color: Colors.red),
                  title: const Text('Reboot Router'),
                  subtitle: const Text('Restart your router'),
                  onTap: () {
                    _showRebootDialog(context, routerProvider);
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
                    _showLogoutDialog(context, routerProvider);
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

  void _showRebootDialog(BuildContext context, RouterProvider provider) {
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

  void _showLogoutDialog(BuildContext context, RouterProvider provider) {
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
