// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'base_api_client.dart';

class AuthService extends ChangeNotifier {
  final BaseApiClient _apiClient;
  bool _isAuthenticated = false;
  String? _username;

  AuthService({required BaseApiClient apiClient}) : _apiClient = apiClient;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  Future<bool> login(String username, String password, String ip) async {
    try {
      debugPrint('Attempting login to $ip with username: $username');

      // Step 1: Get login state
      final stateResponse = await _apiClient.get('/api/system/state');
      debugPrint('State response: $stateResponse');

      // Step 2: Get login nonce
      final nonceResponse = await _apiClient.get(
        '/api/system/user_login_nonce',
      );
      final csrfToken = nonceResponse['csrf_token'];
      debugPrint('CSRF Token: $csrfToken');

      // Step 3: Perform login
      final loginData = {
        'username': username,
        'password': _encodePassword(password),
        'csrf_token': csrfToken,
      };

      final loginResponse = await _apiClient.post(
        '/api/system/user_login',
        body: loginData,
      );

      debugPrint('Login response: $loginResponse');

      if (loginResponse['success'] == true ||
          loginResponse['result'] == 'success') {
        _isAuthenticated = true;
        _username = username;

        // Save credentials using the BaseApiClient method
        await _apiClient.saveCredentials(username, password);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login failed: $e');
      return false;
    }
  }

  Future<bool> checkSession() async {
    try {
      final response = await _apiClient.get('/api/system/heartbeat');
      return response.containsKey('interval') || response['success'] == true;
    } catch (e) {
      debugPrint('Session check failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/api/system/user_logout');
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isAuthenticated = false;
      _username = null;

      // Clear credentials using the BaseApiClient method
      await _apiClient.clearCredentials();
      _apiClient.clearAuth();

      notifyListeners();
    }
  }

  String _encodePassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  // Helper method to get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    return await _apiClient.getSavedCredentials();
  }

  // Helper method to check if credentials exist
  Future<bool> hasSavedCredentials() async {
    final credentials = await _apiClient.getSavedCredentials();
    return credentials != null;
  }

  // Auto-login with saved credentials
  Future<bool> autoLogin() async {
    final credentials = await _apiClient.getSavedCredentials();
    if (credentials != null) {
      return await login(
        credentials['username']!,
        credentials['password']!,
        _apiClient.baseUrl.replaceAll('http://', ''),
      );
    }
    return false;
  }
}
