import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/core/config/server_config.dart';
import '../models/reward_models.dart';

class RewardService {
  static String get baseUrl => ServerConfig.apiBaseUrlSync;
  
  // Get user reward stats
  static Future<Map<String, dynamic>> getUserRewardStats(String userId) async {
    try {
      print('🎯 RewardService: Starting getUserRewardStats for userId: $userId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      print('🎯 RewardService: Token found: ${token != null}');
      print('🎯 RewardService: Base URL: $baseUrl');
      
      if (token == null) {
        print('🎯 RewardService: No authentication token found');
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

      print('🎯 RewardService: Making request to: $baseUrl/rewards/stats/$userId');
      final response = await dio.get('/rewards/stats/$userId');
      
      print('🎯 RewardService: Response status: ${response.statusCode}');
      print('🎯 RewardService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final stats = response.data['data']['stats'] ?? {};
        print('🎯 RewardService: Returning stats: $stats');
        return Map<String, dynamic>.from(stats);
      } else {
        print('🎯 RewardService: Failed with status: ${response.statusCode}');
        throw Exception('Failed to load reward stats: ${response.statusCode}');
      }
    } catch (e) {
      print('🎯 RewardService: Error fetching reward stats: $e');
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

  // Reward Shop Methods
  static Future<List<Map<String, dynamic>>> getRewardItems({
    String? category,
    String? subCategory,
    bool? isActive,
  }) async {
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

      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (subCategory != null) queryParams['subCategory'] = subCategory;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await dio.get('/rewards/items', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          final items = List<Map<String, dynamic>>.from(data['data'] ?? []);
          return items;
        } else if (data is List) {
          final items = List<Map<String, dynamic>>.from(data);
          return items;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load reward items: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> redeemReward(String userId, String rewardItemId, Map<String, dynamic> deliveryAddress, {String? selectedSize, String? sizeType, int? pointCost}) async {
    try {
      print('🛒 RewardService: Starting redemption...');
      print('🛒 User ID: $userId');
      print('🛒 Item ID: $rewardItemId');
      print('🛒 Point Cost: $pointCost');
      print('🛒 Selected Size: $selectedSize, Size Type: $sizeType');
      
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

      final requestData = {
        'userId': userId,
        'rewardItemId': rewardItemId,
        'pointsSpent': pointCost ?? 0, // Use actual point cost
        'deliveryAddress': deliveryAddress,
        if (selectedSize != null) 'selectedSize': selectedSize,
        if (sizeType != null) 'sizeType': sizeType,
      };
      
      print('🛒 Request data: $requestData');
      print('🛒 Making request to: $baseUrl/rewards/shop/redeem');

      final response = await dio.post('/rewards/shop/redeem', data: requestData);

      print('🛒 Response status: ${response.statusCode}');
      print('🛒 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to redeem reward: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ RewardService: Error redeeming reward: $e');
      if (e is DioException) {
        print('❌ DioException details:');
        print('❌ Status code: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
        print('❌ Request data: ${e.requestOptions.data}');
      }
      rethrow;
    }
  }

  static Future<List<RewardRedemption>> getUserRedemptions(String userId) async {
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

      final response = await dio.get('/rewards/redemptions');

      if (response.statusCode == 200) {
        final data = response.data;
        List<Map<String, dynamic>> redemptionsData = [];
        
        if (data is List) {
          redemptionsData = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          redemptionsData = List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else if (data is Map && data.containsKey('redemptions')) {
          redemptionsData = List<Map<String, dynamic>>.from(data['redemptions'] ?? []);
        }
        
        return redemptionsData.map((json) {
          try {
            return RewardRedemption.fromJson(json);
          } catch (e) {
            print('❌ Error parsing redemption: $json, Error: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load redemptions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching redemptions: $e');
      rethrow;
    }
  }
}
