import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BaseApiClient {
  final String baseUrl;
  String? _sessionId;
  String? _csrfToken;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  BaseApiClient({required this.baseUrl});

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_sessionId != null) 'Cookie': 'SessionID_R3=$_sessionId',
      if (_csrfToken != null) 'X-CSRF-Token': _csrfToken!,
    };
  }

  // GET
  Future<Map<String, dynamic>> get(String endpoint) async {
    return _request(endpoint, method: 'GET');
  }

  // POST
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _request(endpoint, method: 'POST', body: body);
  }

  // PUT
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _request(endpoint, method: 'PUT', body: body);
  }

  // DELETE
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _request(endpoint, method: 'DELETE', body: body);
  }

  // PATCH
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _request(endpoint, method: 'PATCH', body: body);
  }

  // Generic request handler
  Future<Map<String, dynamic>> _request(
    String endpoint, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.Request(method, uri);
      request.headers.addAll(_headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('$method request to $endpoint failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'method': method,
        'endpoint': endpoint,
      };
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    _extractSessionId(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true, 'statusCode': response.statusCode};
      }

      try {
        final data = jsonDecode(response.body);
        return {'success': true, 'statusCode': response.statusCode, ...data};
      } catch (e) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': response.body,
        };
      }
    } else {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': 'HTTP Error ${response.statusCode}',
        'message': response.body,
      };
    }
  }

  void _extractSessionId(http.Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      final sessionMatch = RegExp(r'SessionID_R3=([^;]+)').firstMatch(cookies);
      _sessionId = sessionMatch?.group(1);
    }
  }

  // ADD THESE METHODS for credential management
  Future<void> saveCredentials(String username, String password) async {
    try {
      await _secureStorage.write(key: 'username', value: username);
      await _secureStorage.write(
        key: 'password',
        value: _encodePassword(password),
      );
      debugPrint('Credentials saved securely');
    } catch (e) {
      debugPrint('Error saving credentials: $e');
      rethrow;
    }
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final username = await _secureStorage.read(key: 'username');
      final password = await _secureStorage.read(key: 'password');

      if (username != null && password != null) {
        return {'username': username, 'password': password};
      }
      return null;
    } catch (e) {
      debugPrint('Error reading credentials: $e');
      return null;
    }
  }

  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: 'username');
      await _secureStorage.delete(key: 'password');
      debugPrint('Credentials cleared');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
      rethrow;
    }
  }

  String _encodePassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  String _decodePassword(String encodedPassword) {
    return utf8.decode(base64Decode(encodedPassword));
  }

  // Session management methods
  void setSessionId(String sessionId) => _sessionId = sessionId;
  void setCsrfToken(String token) => _csrfToken = token;

  void clearAuth() {
    _sessionId = null;
    _csrfToken = null;
  }

  bool get isAuthenticated => _sessionId != null;

  // Get current session info
  String? get sessionId => _sessionId;
  String? get csrfToken => _csrfToken;
}
