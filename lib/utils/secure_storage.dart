import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> init() async {
    // Initialize secure storage
    await _storage.containsKey(key: 'init');
  }

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }

  static Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Session management
  static Future<void> saveSession(String sessionId) async {
    await write('session_id', sessionId);
  }

  static Future<String?> getSession() async {
    return await read('session_id');
  }

  static Future<void> clearSession() async {
    await delete('session_id');
  }

  // Credentials management (encrypted)
  static Future<void> saveCredentials(String username, String password) async {
    await write('username', username);
    await write('password', password);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final username = await read('username');
    final password = await read('password');

    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    await delete('username');
    await delete('password');
  }

  // Router info
  static Future<void> saveLastRouter(String ip) async {
    await write('last_router_ip', ip);
  }

  static Future<String?> getLastRouter() async {
    return await read('last_router_ip');
  }
}
