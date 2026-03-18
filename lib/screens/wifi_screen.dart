import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/router_provider.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ssidController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _hideSsid = false;
  String _selectedBand = '2.4g';
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController();
    _passwordController = TextEditingController();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    // Load current WiFi settings from provider
    // This would need to be implemented in the provider
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final routerProvider = Provider.of<RouterProvider>(
        context,
        listen: false,
      );

      // This would need to be implemented in the provider
      // final success = await routerProvider.updateWifiSettings(
      //   ssid: _ssidController.text,
      //   password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      //   hideSsid: _hideSsid,
      //   band: _selectedBand,
      // );

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WiFi settings updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Network Name (SSID)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ssidController,
                      decoration: InputDecoration(
                        hintText: 'Enter WiFi name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.wifi),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter WiFi name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText:
                            'Enter new password (leave empty to keep current)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Hide SSID'),
                      subtitle: const Text(
                        'Network will not broadcast its name',
                      ),
                      value: _hideSsid,
                      onChanged: (value) {
                        setState(() {
                          _hideSsid = value;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('WiFi Band'),
                      subtitle: Text(
                        _selectedBand == '2.4g' ? '2.4 GHz' : '5 GHz',
                      ),
                      trailing: DropdownButton<String>(
                        value: _selectedBand,
                        items: const [
                          DropdownMenuItem(
                            value: '2.4g',
                            child: Text('2.4 GHz'),
                          ),
                          DropdownMenuItem(value: '5g', child: Text('5 GHz')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedBand = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
