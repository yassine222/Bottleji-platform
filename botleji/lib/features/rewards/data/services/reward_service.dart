import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RewardService {
  static const String baseUrl = 'http://localhost:3000/api'; // TODO: Replace with your backend URL
  
  // Get user reward stats
  static Future<Map<String, dynamic>> getUserRewardStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/rewards/stats/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stats'] ?? {};
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

      final response = await http.get(
        Uri.parse('$baseUrl/rewards/tiers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['tiers'] ?? []);
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

      final response = await http.post(
        Uri.parse('$baseUrl/rewards/spend/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'points': points,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to spend points: ${response.statusCode}');
      }
    } catch (e) {
      print('Error spending points: $e');
      rethrow;
    }
  }
}
