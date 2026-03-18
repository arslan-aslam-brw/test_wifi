// lib/services/base_api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class BaseApiClient {
  final String baseUrl;
  String? _sessionId;
  String? csrfToken;

  BaseApiClient({required this.baseUrl});

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_sessionId != null) 'Cookie': 'SessionID_R3=$_sessionId',
      if (csrfToken != null) 'X-CSRF-Token': csrfToken!,
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

  // Helper methods
  void setSessionId(String sessionId) => _sessionId = sessionId;
  void setCsrfToken(String token) => csrfToken = token;
  void clearAuth() {
    _sessionId = null;
    csrfToken = null;
  }

  bool get isAuthenticated => _sessionId != null;
}
