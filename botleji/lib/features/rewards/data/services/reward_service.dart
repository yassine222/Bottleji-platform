import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/core/config/server_config.dart';

class RewardService {
  static String get baseUrl => ServerConfig.apiBaseUrl;
  
  // Get user reward stats
  static Future<Map<String, dynamic>> getUserRewardStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.get('/rewards/stats/$userId');

      if (response.statusCode == 200) {
        return response.data['stats'] ?? {};
      } else {
        throw Exception('Failed to load reward stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reward stats: $e');
      rethrow;
    }
  }

  // Get all tiers information
  static Future<List<Map<String, dynamic>>> getAllTiers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.get('/rewards/tiers');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['tiers'] ?? []);
      } else {
        throw Exception('Failed to load tiers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tiers: $e');
      rethrow;
    }
  }

  // Spend points (for future reward shop)
  static Future<Map<String, dynamic>> spendPoints(String userId, int points, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.post('/rewards/spend/$userId', data: {
        'points': points,
        'reason': reason,
      });

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to spend points: ${response.statusCode}');
      }
    } catch (e) {
      print('Error spending points: $e');
      rethrow;
    }
  }
}
