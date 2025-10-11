import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/training_content.dart';

class TrainingApiClient {
  final Dio _dio;

  TrainingApiClient(this._dio);

  Future<List<TrainingContent>> getAllContent({
    String? category,
    String? type,
    bool? isActive,
  }) async {
    try {
      debugPrint('📚 Fetching training content...');
      
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (type != null) queryParams['type'] = type;
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final response = await _dio.get(
        '/training',
        queryParameters: queryParams,
      );

      debugPrint('✅ Training content response: ${response.statusCode}');
      
      final data = response.data;
      final contentList = (data['content'] as List<dynamic>?)
          ?.map((json) => TrainingContent.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      debugPrint('✅ Loaded ${contentList.length} training items');
      return contentList;
    } catch (e) {
      debugPrint('❌ Error fetching training content: $e');
      rethrow;
    }
  }

  Future<TrainingContent> getContentById(String id) async {
    try {
      final response = await _dio.get('/training/$id');
      return TrainingContent.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Error fetching training content by ID: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/training/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error fetching training stats: $e');
      rethrow;
    }
  }

  Future<List<TrainingContent>> getFeaturedContent() async {
    try {
      final response = await _dio.get('/training/featured');
      final contentList = (response.data['content'] as List<dynamic>?)
          ?.map((json) => TrainingContent.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];
      return contentList;
    } catch (e) {
      debugPrint('❌ Error fetching featured content: $e');
      rethrow;
    }
  }

  Future<List<TrainingContent>> getContentByCategory(String category) async {
    try {
      final response = await _dio.get('/training/category/$category');
      final contentList = (response.data['content'] as List<dynamic>?)
          ?.map((json) => TrainingContent.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];
      return contentList;
    } catch (e) {
      debugPrint('❌ Error fetching content by category: $e');
      rethrow;
    }
  }
}

