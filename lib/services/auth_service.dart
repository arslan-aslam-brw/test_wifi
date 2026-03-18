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
      // Step 1: Get login state
      final stateResponse = await _apiClient.get('/api/system/state');

      // Step 2: Get login nonce
      final nonceResponse = await _apiClient.get(
        '/api/system/user_login_nonce',
      );
      final csrfToken = nonceResponse['csrf_token'];

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

      if (loginResponse['success'] == true) {
        _isAuthenticated = true;
        _username = username;
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
      return response.containsKey('interval');
    } catch (e) {
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
      await _apiClient.clearCredentials();
      notifyListeners();
    }
  }

  String _encodePassword(String password) {
    return base64Encode(utf8.encode(password));
  }
}
