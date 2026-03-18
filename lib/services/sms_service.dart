import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/sms_model.dart';
import 'base_api_client.dart';

class SmsService {
  final BaseApiClient _apiClient;

  SmsService(this._apiClient);

  Future<List<SmsModel>> getSmsList({int page = 1, int count = 20}) async {
    try {
      final response = await _apiClient.get(
        '/api/sms/sms-list?page=$page&count=$count',
      );
      return _parseSmsList(response);
    } catch (e) {
      debugPrint('Error getting SMS list: $e');
      return [];
    }
  }

  List<SmsModel> _parseSmsList(Map<String, dynamic> data) {
    final List<SmsModel> smsList = [];

    if (data.containsKey('messages')) {
      final messages = data['messages'] as List;
      for (var msg in messages) {
        smsList.add(SmsModel.fromJson(msg));
      }
    } else if (data.containsKey('Messages')) {
      final messages = data['Messages'] as List;
      for (var msg in messages) {
        smsList.add(SmsModel.fromJson(msg));
      }
    }

    return smsList;
  }

  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final response = await _apiClient.post(
        '/api/sms/send-sms',
        body: {'phone': phoneNumber, 'message': message},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> deleteSms(List<String> smsIds) async {
    try {
      final response = await _apiClient.post(
        '/api/sms/delete-sms',
        body: {'ids': smsIds},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error deleting SMS: $e');
      return false;
    }
  }

  Future<int> getSmsCount() async {
    try {
      final response = await _apiClient.get('/api/sms/sms-count');
      return int.tryParse(response['count']?.toString() ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
