import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/models/user_data.dart';
import '../data/repositories/auth_repository_impl.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/config/server_config.dart';
import '../../../core/api/api_client.dart';

class CollectorSubscriptionController extends StateNotifier<AsyncValue<String>> {
  late final SharedPreferences _prefs;
  final _dio = ApiClientConfig.createDio();

  CollectorSubscriptionController() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // Initial fetch
    await _fetchSubscriptionType();
  }

  Future<String> _fetchSubscriptionType() async {
    try {
      // Get the auth token
      final token = _prefs.getString('auth_token');
      if (token == null) {
        debugPrint('No auth token found');
        state = const AsyncValue.data('basic');
        return 'basic';
      }

      debugPrint('Fetching user profile with token: ${token.substring(0, 10)}...');

      // Get user data from the database
      final response = await _dio.get(
        '${ServerConfig.apiBaseUrl}/auth/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Raw response data: ${json.encode(response.data)}');
        debugPrint('User data from response: ${json.encode(response.data['user'])}');
        debugPrint('Subscription type from response: ${response.data['user']['collectorSubscriptionType']}');
        
        final userData = UserData.fromJson(response.data['user']);
        debugPrint('Parsed user data: ${json.encode(userData.toJson())}');
        debugPrint('Final subscription type: ${userData.collectorSubscriptionType}');
        debugPrint('Is pro subscription: ${userData.collectorSubscriptionType == 'premium'}');
        
        state = AsyncValue.data(userData.collectorSubscriptionType ?? 'basic');
        return userData.collectorSubscriptionType ?? 'basic';
      } else {
        debugPrint('Failed to fetch user data from DB. Status code: ${response.statusCode}');
        state = const AsyncValue.data('basic');
        return 'basic';
      }
    } catch (e, stack) {
      debugPrint('Error fetching subscription type from DB: $e');
      debugPrint('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      return 'basic';
    }
  }

  bool isPro() {
    final isPro = state.value == 'premium';
    debugPrint('isPro check: $isPro (current state: ${state.value})');
    return isPro;
  }

  String getSubscriptionBadgeText() {
    final text = state.value?.toUpperCase() ?? 'BASIC';
    debugPrint('Getting subscription badge text: $text (from state: ${state.value})');
    return text;
  }

  Color getSubscriptionBadgeColor() {
    final color = switch (state.value) {
      'premium' => Colors.blue,
      _ => Colors.amber,
    };
    debugPrint('Getting subscription badge color: $color (for state: ${state.value})');
    return color;
  }

  Future<void> setSubscriptionType(String type) async {
    debugPrint('Setting subscription type to: $type');
    
    try {
      // Get the auth token
      final token = _prefs.getString('auth_token');
      if (token == null) {
        debugPrint('No auth token found');
        return;
      }

      // Update subscription type in backend
      final response = await _dio.put(
        '${ServerConfig.apiBaseUrl}/auth/update-collector-subscription',
        data: {'subscriptionType': type},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Subscription type updated successfully in backend');
        debugPrint('Response data: ${json.encode(response.data)}');
        
        // Refresh the subscription type from the database
        await refresh();
      } else {
        throw Exception('Failed to update subscription type in backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating subscription type: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final token = _prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      debugPrint('Refreshing user profile with token: ${token.substring(0, 10)}...');

      final response = await _dio.get(
        '${ServerConfig.apiBaseUrl}/auth/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Refresh - Raw response data: ${json.encode(response.data)}');
        debugPrint('Refresh - User data from response: ${json.encode(response.data['user'])}');
        debugPrint('Refresh - Subscription type from response: ${response.data['user']['collectorSubscriptionType']}');
        
        final userData = UserData.fromJson(response.data['user']);
        debugPrint('Refresh - Parsed user data: ${json.encode(userData.toJson())}');
        debugPrint('Refresh - Final subscription type: ${userData.collectorSubscriptionType}');
        debugPrint('Refresh - Is pro subscription: ${userData.collectorSubscriptionType == 'premium'}');
        
        state = AsyncValue.data(userData.collectorSubscriptionType ?? 'basic');
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final collectorSubscriptionControllerProvider = StateNotifierProvider<CollectorSubscriptionController, AsyncValue<String>>((ref) {
  return CollectorSubscriptionController();
}); 