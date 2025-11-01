import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/core/config/server_config.dart';
import '../models/notification_models.dart';

class NotificationService {
  static final Dio _dio = Dio();
  static String? _baseUrl;

  static void initialize(String baseUrl) {
    _baseUrl = baseUrl;
  }

  static String get baseUrl => _baseUrl ?? ServerConfig.apiBaseUrlSync;

  /// Get user notifications with optional filters
  static Future<Map<String, dynamic>> getUserNotifications({
    String? type,
    bool? isRead,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (type != null) queryParams['type'] = type;
      if (isRead != null) queryParams['isRead'] = isRead;

      final response = await _dio.get(
        '$baseUrl/notifications',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'notifications': (data['data'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList(),
          'total': data['total'] ?? 0,
          'unreadCount': data['unreadCount'] ?? 0,
        };
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired, clear it and throw a specific error
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        throw Exception('Session expired. Please log in again.');
      }
      print('Error fetching notifications: $e');
      return {
        'success': false,
        'error': e.toString(),
        'notifications': <NotificationModel>[],
        'total': 0,
        'unreadCount': 0,
      };
    } catch (e) {
      print('Error fetching notifications: $e');
      return {
        'success': false,
        'error': e.toString(),
        'notifications': <NotificationModel>[],
        'total': 0,
        'unreadCount': 0,
      };
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.patch(
        '$baseUrl/notifications/$notificationId/read',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
      print('Error marking notification as read: $e');
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.patch(
        '$baseUrl/notifications/read-all',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
      print('Error marking all notifications as read: $e');
      return false;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.delete(
        '$baseUrl/notifications/$notificationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
      print('Error deleting notification: $e');
      return false;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final result = await getUserNotifications(isRead: false, limit: 1);
      return result['unreadCount'] ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
