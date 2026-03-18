import 'package:flutter/material.dart';

import '../models/firewall_model.dart';
import 'base_api_client.dart';

class SecurityService {
  final BaseApiClient _apiClient;

  SecurityService(this._apiClient);

  Future<FirewallSettings?> getFirewallSettings() async {
    try {
      final response = await _apiClient.get('/api/security/firewall-settings');
      return FirewallSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error getting firewall settings: $e');
      return null;
    }
  }

  Future<bool> setFirewallLevel(String level) async {
    try {
      final response = await _apiClient.post(
        '/api/security/firewall-settings',
        body: {'level': level},
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<PortForwardRule>> getPortForwardRules() async {
    try {
      final response = await _apiClient.get('/api/security/port-forwarding');
      final List<PortForwardRule> rules = [];

      if (response.containsKey('rules')) {
        final rulesList = response['rules'] as List;
        for (var rule in rulesList) {
          rules.add(PortForwardRule.fromJson(rule));
        }
      }

      return rules;
    } catch (e) {
      debugPrint('Error getting port forward rules: $e');
      return [];
    }
  }

  Future<bool> addPortForwardRule(PortForwardRule rule) async {
    try {
      final response = await _apiClient.post(
        '/api/security/port-forwarding',
        body: rule.toJson(),
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removePortForwardRule(String ruleId) async {
    try {
      final response = await _apiClient.post(
        '/api/security/port-forwarding/delete',
        body: {'id': ruleId},
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getMacFilterList() async {
    try {
      final response = await _apiClient.get('/api/security/mac-filter');
      final List<String> macList = [];

      if (response.containsKey('mac_list')) {
        final list = response['mac_list'] as List;
        for (var item in list) {
          macList.add(item['mac'] ?? '');
        }
      }

      return macList;
    } catch (e) {
      return [];
    }
  }
}
