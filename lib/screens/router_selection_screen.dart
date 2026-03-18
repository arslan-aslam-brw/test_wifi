import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_wifi/screens/dashboard_screen.dart';
import 'package:test_wifi/services/router_discovery.dart';
import 'package:test_wifi/utils/helpers.dart';
import '../providers/router_provider_extended.dart';
import '../models/router_profile.dart';
import 'login_screen.dart';

class RouterSelectionScreen extends StatefulWidget {
  const RouterSelectionScreen({super.key});

  @override
  State<RouterSelectionScreen> createState() => _RouterSelectionScreenState();
}

class _RouterSelectionScreenState extends State<RouterSelectionScreen> {
  bool _isSelectionMode = false;
  final List<String> _selectedIds = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'My Routers',
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddRouterDialog(context),
            ),
        ],
      ),
      body: Consumer<ExtendedRouterProvider>(
        builder: (context, provider, child) {
          if (provider.routerProfiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.router, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No routers added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRouterDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Router'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.routerProfiles.length,
            itemBuilder: (context, index) {
              final profile = provider.routerProfiles[index];
              return _buildRouterTile(profile, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _discoverRouters(context),
        icon: const Icon(Icons.search),
        label: const Text('Discover'),
      ),
    );
  }

  Widget _buildRouterTile(
    RouterProfile profile,
    ExtendedRouterProvider provider,
  ) {
    final isSelected = _selectedIds.contains(profile.id);
    final isCurrent = provider.currentProfile?.id == profile.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(profile.status).withOpacity(0.2),
              child: Icon(
                _getStatusIcon(profile.status),
                color: _getStatusColor(profile.status),
              ),
            ),
            if (profile.isDefault)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('IP: ${profile.ipAddress}'),
            Text('Model: ${profile.model ?? 'Unknown'}'),
            Text('Last connected: ${_formatDate(profile.lastConnected)}'),
          ],
        ),
        trailing: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(profile.id),
              )
            : PopupMenuButton(
                onSelected: (value) {
                  switch (value) {
                    case 'connect':
                      _connectToRouter(profile, provider);
                      break;
                    case 'edit':
                      _showEditRouterDialog(context, profile);
                      break;
                    case 'default':
                      _setAsDefault(profile, provider);
                      break;
                    case 'delete':
                      _showDeleteDialog([profile.id], provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'connect',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Connect'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!profile.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Set as Default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(profile.id);
          } else {
            _connectToRouter(profile, provider);
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _toggleSelection(profile.id);
          });
        },
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _deleteSelected() {
    if (_selectedIds.isNotEmpty) {
      _showDeleteDialog(
        _selectedIds,
        Provider.of<ExtendedRouterProvider>(context, listen: false),
      );
    }
  }

  void _showDeleteDialog(List<String> ids, ExtendedRouterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${ids.length} router${ids.length > 1 ? 's' : ''}'),
        content: Text('Are you sure you want to delete these routers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (var id in ids) {
                provider.deleteRouterProfile(id);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _connectToRouter(
    RouterProfile profile,
    ExtendedRouterProvider provider,
  ) async {
    setState(() {
      profile.status = ConnectionStatus.connecting;
    });

    final success = await provider.switchRouter(profile);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to ${profile.name}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setAsDefault(RouterProfile profile, ExtendedRouterProvider provider) {
    for (var p in provider.routerProfiles) {
      p.isDefault = p.id == profile.id;
    }
    provider.updateRouterProfile(profile);
    setState(() {});
  }

  void _showAddRouterDialog(BuildContext context) {
    _showRouterForm(context, null);
  }

  void _showEditRouterDialog(BuildContext context, RouterProfile profile) {
    _showRouterForm(context, profile);
  }

  void _showRouterForm(BuildContext context, RouterProfile? existingProfile) {
    final nameController = TextEditingController(
      text: existingProfile?.name ?? '',
    );
    final ipController = TextEditingController(
      text: existingProfile?.ipAddress ?? '',
    );
    final usernameController = TextEditingController(
      text: existingProfile?.username ?? '',
    );
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingProfile == null ? 'Add Router' : 'Edit Router'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Router Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter IP address';
                    }
                    if (!Helpers.isValidIp(value)) {
                      return 'Invalid IP address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: existingProfile == null
                        ? 'Password'
                        : 'Password (leave empty to keep current)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
                final provider = Provider.of<ExtendedRouterProvider>(
                  context,
                  listen: false,
                );

                if (existingProfile == null) {
                  // Add new router
                  final newProfile = RouterProfile(
                    id: '',
                    name: nameController.text,
                    ipAddress: ipController.text,
                    username: usernameController.text,
                    password: passwordController.text.isNotEmpty
                        ? Helpers.encodePassword(passwordController.text)
                        : null,
                    lastConnected: DateTime.now(),
                  );
                  await provider.addRouterProfile(newProfile);
                } else {
                  // Update existing router
                  existingProfile.name = nameController.text;
                  existingProfile.ipAddress = ipController.text;
                  existingProfile.username = usernameController.text;
                  if (passwordController.text.isNotEmpty) {
                    existingProfile.password = Helpers.encodePassword(
                      passwordController.text,
                    );
                  }
                  await provider.updateRouterProfile(existingProfile);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(existingProfile == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _discoverRouters(BuildContext context) async {
    final discovered = await RouterDiscovery.discoverRouters();

    if (discovered.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routers found on network'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discovered Routers'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: discovered.length,
              itemBuilder: (context, index) {
                final router = discovered[index];
                return ListTile(
                  leading: const Icon(Icons.router),
                  title: Text(router.name ?? 'Huawei Router'),
                  subtitle: Text(router.ip),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddRouterDialog(context);
                  },
                );
              },
            ),
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
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.error:
        return Icons.error;
      case ConnectionStatus.disconnected:
        return Icons.router;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
