import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/core/api/api_client.dart';

class DropRepository {
  final Dio _dio;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DropRepository({Dio? dio}) : _dio = dio ?? ApiClientConfig.createDio();
  
  static Future<DropRepository> create() async {
    final dio = ApiClientConfig.createDio();
    return DropRepository(dio: dio);
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'drops/$timestamp.jpg';
      
      // Get reference to the file
      final fileRef = _storage.ref().child(fileName);
      
      // Set metadata for better caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path},
      );
      // Upload the file
      final uploadTask = await fileRef.putFile(imageFile, metadata);
      
      // Get the download URL
      final url = await fileRef.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create drop
  Future<Drop> createDrop({
    required String userId,
    required String imagePath,
    required int numberOfBottles,
    required int numberOfCans,
    required BottleType bottleType,
    String? notes,
    required bool leaveOutside,
    required LatLng location,
  }) async {
    try {
      final response = await _dio.post(
        '/dropoffs',  // Updated endpoint path
        data: {
          'userId': userId,
          'imageUrl': imagePath,
          'numberOfBottles': numberOfBottles,
          'numberOfCans': numberOfCans,
          'bottleType': bottleType.name,
          'notes': notes,
          'leaveOutside': leaveOutside,
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
        },
      );
      return Drop.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to create drop: ${e.response?.data?['message'] ?? e.message}');
      }
      throw Exception('Failed to create drop: $e');
    }
  }

  // Get all drops (for households - their own drops)
  Future<List<Drop>> getDrops() async {
    try {
      final response = await _dio.get('/dropoffs');  // Updated endpoint path
      
      if (response.data is! List) {
        print('❌ DropRepository: Response data is not a List: ${response.data.runtimeType}');
        return [];
      }
      
      final List<dynamic> data = response.data;
      print('🔍 DropRepository: Got ${data.length} drops from API');
      
      final drops = <Drop>[];
      for (int i = 0; i < data.length; i++) {
        try {
          final drop = Drop.fromJson(data[i]);
          drops.add(drop);
        } catch (e) {
          print('❌ DropRepository: Error parsing drop at index $i: $e');
          print('❌ DropRepository: Drop data: ${data[i]}');
          // Continue with other drops instead of failing completely
        }
      }
      
      print('🔍 DropRepository: Successfully parsed ${drops.length} drops');
      return drops;
    } catch (e) {
      print('❌ DropRepository: Error getting drops: $e');
      throw Exception('Failed to get drops: $e');
    }
  }

  // Get drops available for collectors
  Future<List<Drop>> getDropsAvailableForCollectors({String? excludeCollectorId}) async {
    try {
      // print('🔍 API: Getting drops available for collectors');
      // print('🔍 API: excludeCollectorId = $excludeCollectorId');
      
      final url = excludeCollectorId != null 
          ? '/dropoffs/available?excludeCollectorId=$excludeCollectorId'
          : '/dropoffs/available';
      
      // print('🔍 API: Calling URL: $url');
      
      final response = await _dio.get(url);
      
      // print('🔍 API: Response status: ${response.statusCode}');
      // print('🔍 API: Response data length: ${(response.data as List).length}');
      
      if (response.statusCode == 200) {
        if (response.data is! List) {
          print('❌ DropRepository: Response data is not a List: ${response.data.runtimeType}');
          return [];
        }
        
        final List<dynamic> data = response.data;
        print('🔍 DropRepository: Got ${data.length} drops available for collectors');
        
        final drops = <Drop>[];
        for (int i = 0; i < data.length; i++) {
          try {
            final drop = Drop.fromJson(data[i]);
            drops.add(drop);
          } catch (e) {
            print('❌ DropRepository: Error parsing drop at index $i: $e');
            print('❌ DropRepository: Drop data: ${data[i]}');
            // Continue with other drops instead of failing completely
          }
        }
        
        print('🔍 DropRepository: Successfully parsed ${drops.length} drops for collectors');
        return drops;
      } else {
        throw Exception('Failed to load drops: ${response.statusCode}');
      }
    } catch (e) {
      // print('❌ API: Error getting drops for collectors: $e');
      rethrow;
    }
  }

  // Get drops accepted by a specific collector
  Future<List<Drop>> getDropsAcceptedByCollector(String collectorId) async {
    try {
      final response = await _dio.get('/dropoffs/collector/$collectorId/accepted');
      return (response.data as List)
          .map((json) => Drop.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get accepted drops: $e');
    }
  }

  // Get drops by user ID
  Future<List<Drop>> getDropsByUser(String userId) async {
    try {
      // print('🔍 API: Getting drops for user: $userId');
      
      // Validate user ID
      if (userId.isEmpty) {
        // print('🔍 API: User ID is empty, returning empty list');
        return [];
      }
      
      final response = await _dio.get('/dropoffs/user/$userId');  // Updated endpoint path
      
      // print('🔍 API: Response status: ${response.statusCode}');
      // print('🔍 API: Response data length: ${(response.data as List).length}');
      
      if (response.data is! List) {
        print('❌ DropRepository: Response data is not a List: ${response.data.runtimeType}');
        return [];
      }
      
      final List<dynamic> data = response.data;
      print('🔍 DropRepository: Got ${data.length} drops for user $userId');
      
      final drops = <Drop>[];
      for (int i = 0; i < data.length; i++) {
        try {
          final drop = Drop.fromJson(data[i]);
          drops.add(drop);
        } catch (e) {
          print('❌ DropRepository: Error parsing drop at index $i: $e');
          print('❌ DropRepository: Drop data: ${data[i]}');
          // Continue with other drops instead of failing completely
        }
      }
      
      print('🔍 DropRepository: Successfully parsed ${drops.length} drops for user');
      return drops;
    } catch (e) {
      // print('❌ API Error getting user drops: $e');
      throw Exception('Failed to get user drops: $e');
    }
  }

  // Get drops by status
  Future<List<Drop>> getDropsByStatus(String status) async {
    try {
      final response = await _dio.get('/dropoffs/status/$status');  // Updated endpoint path
      return (response.data as List)
          .map((json) => Drop.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get drops by status: $e');
    }
  }

  // Update drop status
  Future<Drop> updateDropStatus(String dropId, DropStatus status) async {
    try {
      final response = await _dio.patch(
        '/dropoffs/$dropId/status',  // Updated endpoint path
        data: {'status': status.name},
      );
      return Drop.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update drop status: $e');
    }
  }

  // Update drop
  Future<Drop> updateDrop(Drop drop) async {
    try {
      final response = await _dio.put(
        '/dropoffs/${drop.id}',
        data: {
          'imageUrl': drop.imageUrl,
          'numberOfBottles': drop.numberOfBottles,
          'numberOfCans': drop.numberOfCans,
          'bottleType': drop.bottleType.name,
          'notes': drop.notes,
          'leaveOutside': drop.leaveOutside,
          'location': {
            'latitude': drop.location.latitude,
            'longitude': drop.location.longitude,
          },
        },
      );
      return Drop.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update drop: $e');
    }
  }
    

  // Assign collector to drop (creates CollectionAttempt in new system)
  Future<Drop> assignCollector(String dropId, String collectorId) async {
    try {
      // First, create a collection attempt using the new system
      print('📝 Creating collection attempt for drop: $dropId, collector: $collectorId');
      final attemptResponse = await _dio.post(
        '/dropoffs/$dropId/attempts',
        data: {'collectorId': collectorId},
      );
      print('✅ Collection attempt created: ${attemptResponse.data['_id']}');
      
      // Then update the drop status to accepted
      final response = await _dio.patch(
        '/dropoffs/$dropId/collector',  // Updated endpoint path
        data: {'collectorId': collectorId},
      );
      return Drop.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to assign collector: $e');
    }
  }

  // Confirm collection (completes CollectionAttempt as 'collected')
  Future<Drop> confirmCollection(String dropId) async {
    try {
      // First, find the active collection attempt for this drop
      print('📝 Getting active collection attempt for drop: $dropId');
      final attemptsResponse = await _dio.get('/dropoffs/$dropId/attempts');
      final attempts = attemptsResponse.data as List;
      
      // Find the active attempt
      final activeAttempt = attempts.firstWhere(
        (a) => a['status'] == 'active',
        orElse: () => null,
      );
      
      if (activeAttempt != null) {
        final attemptId = activeAttempt['_id'];
        print('✅ Found active attempt: $attemptId');
        
        // Complete the attempt as 'collected'
        await _dio.patch(
          '/dropoffs/$dropId/attempts/$attemptId/complete',
          data: {
            'outcome': 'collected',
            'notes': 'Collection completed successfully',
          },
        );
        print('✅ Collection attempt marked as collected');
      }
      
      // Then update the drop status
      final response = await _dio.patch('/dropoffs/$dropId/confirm-collection');
      return Drop.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to confirm collection: $e');
    }
  }

  // Cancel accepted drop (completes CollectionAttempt as 'cancelled')
  Future<void> cancelAcceptedDrop(String dropId, String reason, String cancelledByCollectorId) async {
    try {
      // First, find the active collection attempt for this drop
      print('📝 Getting active collection attempt for drop: $dropId');
      final attemptsResponse = await _dio.get('/dropoffs/$dropId/attempts');
      final attempts = attemptsResponse.data as List;
      
      // Find the active attempt
      final activeAttempt = attempts.firstWhere(
        (a) => a['status'] == 'active',
        orElse: () => null,
      );
      
      if (activeAttempt != null) {
        final attemptId = activeAttempt['_id'];
        print('✅ Found active attempt: $attemptId');
        
        // Complete the attempt as 'cancelled'
        await _dio.patch(
          '/dropoffs/$dropId/attempts/$attemptId/complete',
          data: {
            'outcome': 'cancelled',
            'reason': reason,
            'notes': 'Collection cancelled by collector',
          },
        );
        print('✅ Collection attempt marked as cancelled');
      }
      
      // Then update the drop status
      await _dio.patch(
        '/dropoffs/$dropId/cancel-accepted',
        data: {
          'reason': reason,
          'cancelledByCollectorId': cancelledByCollectorId,
        },
      );
    } catch (e) {
      throw Exception('Failed to cancel drop: $e');
    }
  }

  // Delete drop
  Future<void> deleteDrop(String dropId) async {
    try {
      await _dio.delete('/dropoffs/$dropId');  // Updated endpoint path
    } catch (e) {
      throw Exception('Failed to delete drop: $e');
    }
  }

  // Get user information by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      print('🔍 DropRepository: Getting user info for ID: $userId');
      
      // Get auth token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('⚠️ DropRepository: No auth token found, using fallback');
        return _getFallbackUserData();
      }
      
      // First try to get the specific user with auth token
      final response = await _dio.get(
        '/auth/user/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      print('✅ DropRepository: Got specific user data');
      return response.data;
    } catch (e) {
      print('⚠️ DropRepository: Failed to get specific user, trying profile: $e');
      
      // If that fails, try to get the current user's profile
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token == null) {
          print('⚠️ DropRepository: No auth token for profile fallback');
          return _getFallbackUserData();
        }
        
        final profileResponse = await _dio.get(
          '/auth/profile',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
        final userData = profileResponse.data['user'];
        print('✅ DropRepository: Got current user profile data');
        return {
          'name': userData['name'] ?? 'Unknown User',
          'phoneNumber': userData['phoneNumber'] ?? 'N/A',
          'profilePhoto': userData['profilePhoto'],
        };
      } catch (profileError) {
        print('❌ DropRepository: Failed to get profile data: $profileError');
        return _getFallbackUserData();
      }
    }
  }
  
  // Fallback user data when API calls fail
  Map<String, dynamic> _getFallbackUserData() {
    return {
      'name': 'Unknown User',
      'phoneNumber': 'N/A',
      'profilePhoto': null,
    };
  }
}
