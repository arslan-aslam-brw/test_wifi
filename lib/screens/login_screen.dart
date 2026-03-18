import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_wifi/models/router_model.dart';
import '../providers/router_provider_extended.dart';
import '../services/router_discovery.dart';
import '../models/router_profile.dart';
import 'dashboard_screen.dart';
import '../utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  String? _selectedRouterId;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );

    // Check if biometric login is enabled and available
    if (provider.biometricEnabled && provider.biometricAvailable) {
      // Don't auto-load credentials, wait for biometric
      return;
    }

    // Load last used router
    if (provider.routerProfiles.isNotEmpty) {
      final lastRouter = provider.routerProfiles.firstWhere(
        (p) => p.isDefault,
        orElse: () => provider.routerProfiles.first,
      );

      setState(() {
        _selectedRouterId = lastRouter.id;
        _ipController.text = lastRouter.ipAddress;
        _usernameController.text = lastRouter.username;
        // Password is not loaded for security
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExtendedRouterProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.router,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Huawei Router Manager',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Manage your Huawei router settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Router Selection Dropdown (if multiple profiles exist)
                  if (provider.routerProfiles.length > 1)
                    _buildRouterDropdown(provider),

                  // IP Address Field
                  TextFormField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Router IP Address',
                      hintText: 'e.g., 192.168.1.1',
                      prefixIcon: const Icon(Icons.router),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _discoverRouters,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter router IP';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // Remember Me Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Remember me'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Connect to Router',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  // Biometric Login Button (NEW)
                  _buildBiometricLoginButton(context, provider),

                  const SizedBox(height: 16),

                  // Add Router Button
                  TextButton.icon(
                    onPressed: _showAddRouterDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Router'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Biometric Login Button Widget
  Widget _buildBiometricLoginButton(
    BuildContext context,
    ExtendedRouterProvider provider,
  ) {
    if (!provider.biometricAvailable || !provider.biometricEnabled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _loginWithBiometrics(provider),
          icon: const Icon(Icons.fingerprint),
          label: const Text('Login with Biometrics'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Biometric Login Method
  Future<void> _loginWithBiometrics(ExtendedRouterProvider provider) async {
    setState(() => _isLoading = true);

    try {
      // Authenticate with biometrics
      final authenticated = await provider.authenticateWithBiometrics();

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Get the default or last used router profile
      RouterProfile? targetProfile;

      if (_selectedRouterId != null) {
        targetProfile = provider.routerProfiles.firstWhere(
          (p) => p.id == _selectedRouterId,
          orElse: () => provider.routerProfiles.first,
        );
      } else {
        targetProfile = provider.routerProfiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => provider.routerProfiles.first,
        );
      }

      if (targetProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved router found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Auto-login with saved credentials
      final success = await provider.switchRouter(targetProfile);

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${targetProfile.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Router Dropdown for multiple profiles
  Widget _buildRouterDropdown(ExtendedRouterProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRouterId ?? provider.routerProfiles.first.id,
          hint: const Text('Select Router'),
          isExpanded: true,
          items: provider.routerProfiles.map((profile) {
            return DropdownMenuItem(
              value: profile.id,
              child: Row(
                children: [
                  Icon(
                    Icons.router,
                    size: 20,
                    color: profile.isDefault ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          profile.ipAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRouterId = value;
              final selected = provider.routerProfiles.firstWhere(
                (p) => p.id == value,
              );
              _ipController.text = selected.ipAddress;
              _usernameController.text = selected.username;
              // Don't auto-fill password for security
              _passwordController.clear();
            });
          },
        ),
      ),
    );
  }

  // Router Discovery Method
  Future<void> _discoverRouters() async {
    setState(() => _isLoading = true);

    try {
      final routers = await RouterDiscovery.discoverRouters();

      if (routers.isNotEmpty && mounted) {
        _ipController.text = routers.first.ip;

        // Show dialog with all discovered routers
        if (routers.length > 1) {
          _showRouterSelectionDialog(routers);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${routers.length} router(s)'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No routers found on network'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Router Selection Dialog
  void _showRouterSelectionDialog(List<RouterModel> routers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Router'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: routers.length,
            itemBuilder: (context, index) {
              final router = routers[index];
              return ListTile(
                title: Text(router.name ?? 'Huawei Router'),
                subtitle: Text(router.ip),
                onTap: () {
                  _ipController.text = router.ip;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Add Router Dialog
  void _showAddRouterDialog() {
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Router'),
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
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
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

                final newProfile = RouterProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  ipAddress: ipController.text,
                  username: usernameController.text,
                  password: Helpers.encodePassword(passwordController.text),
                  lastConnected: DateTime.now(),
                );

                await provider.addRouterProfile(newProfile);

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _ipController.text = newProfile.ipAddress;
                    _usernameController.text = newProfile.username;
                    _selectedRouterId = newProfile.id;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Router added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Main Login Method
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final provider = Provider.of<ExtendedRouterProvider>(
        context,
        listen: false,
      );

      // Check if we're using an existing profile or creating a new session
      RouterProfile? profile;

      if (_selectedRouterId != null) {
        profile = provider.routerProfiles.firstWhere(
          (p) => p.id == _selectedRouterId,
          orElse: () => RouterProfile(
            id: '',
            name: 'Temporary',
            ipAddress: _ipController.text,
            username: _usernameController.text,
            lastConnected: DateTime.now(),
          ),
        );
      } else {
        profile = RouterProfile(
          id: '',
          name: 'Temporary',
          ipAddress: _ipController.text,
          username: _usernameController.text,
          lastConnected: DateTime.now(),
        );
      }

      // Initialize and login
      await provider.initialize(profile!.ipAddress);
      final success = await provider.login(
        _usernameController.text,
        _passwordController.text,
        _ipController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Save credentials if remember me is checked
        if (_rememberMe) {
          profile.password = Helpers.encodePassword(_passwordController.text);
          profile.name = profile.name == 'Temporary'
              ? 'Router ${profile.ipAddress}'
              : profile.name;

          if (_selectedRouterId == null) {
            await provider.addRouterProfile(profile);
          } else {
            await provider.updateRouterProfile(profile);
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Check credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
