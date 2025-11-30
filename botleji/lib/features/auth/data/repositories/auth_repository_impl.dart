import 'package:dio/dio.dart';
import 'dart:convert';
import '../datasources/auth_api_client.dart';
import '../models/auth_request.dart';
import '../models/auth_response.dart';
import '../models/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/server_config.dart';

class AuthRepository {
  final AuthApiClient _apiClient;

  AuthRepository({AuthApiClient? apiClient}) : _apiClient = apiClient ?? AuthApiClient(
    Dio(BaseOptions(
      baseUrl: ServerConfig.apiBaseUrlSync,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
        }
    ),),
  );

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
      };
      print('Sending login request data: $requestData');
      
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          }
      ));
      
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('Dio: $object'),
      ));
      
      try {
        final response = await dio.post(
          '/auth/login',
          data: requestData,
        );
        print('Raw server response: ${response.data}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Create success response with user data and token
          return AuthResponse.success(
            user: UserData.fromJson(response.data['user']),
            token: response.data['token'],
            message: 'Login successful',
        );
        } else {
          final message = response.data['message'] ?? 'Login failed';
          print('Login failed with message: $message');
          return AuthResponse.error(
            message: message,
            statusCode: response.statusCode ?? 500,
        );
        }
    } on DioException catch (e) {
        print('🔍 DioException: ${e.message}');
        print('🔍 DioException type: ${e.type}');
        print('🔍 DioException status code: ${e.response?.statusCode}');
        print('🔍 DioException response data: ${e.response?.data}');
        print('🔍 DioException response data type: ${e.response?.data.runtimeType}');
        
        if (e.response?.statusCode == 404) {
          return AuthResponse.error(
            message: 'Invalid email or password',
            statusCode: 404,
        );
        }
        
        // Handle network/tunnel errors (530, 502, 503, etc.)
        if (e.response?.statusCode != null && 
            (e.response!.statusCode! >= 500 || e.response!.statusCode == 530)) {
          return AuthResponse.error(
            message: 'Server is temporarily unavailable. Please check your connection or try again later.',
            statusCode: e.response!.statusCode!,
          );
        }
        
        // Handle error message that could be a string, list, or Map
        String message;
        final responseData = e.response?.data;
        
        if (responseData is Map<String, dynamic>) {
          // Response is JSON
          dynamic errorMessage = responseData['message'];
          if (errorMessage is List) {
            message = errorMessage.join(', ');
          } else if (errorMessage != null) {
            message = errorMessage.toString();
          } else {
            // Try to get message from error field or use default
            message = responseData['error']?.toString() ?? 
                     e.message ?? 
                     'An error occurred';
          }
        } else if (responseData is String) {
          // Response is HTML or plain text (like Cloudflare error pages)
          message = 'Server error. Please try again later.';
        } else {
          // Fallback
          message = e.message ?? 'An error occurred';
        }
        
        print('🔍 Extracted error message: $message');
        print('🔍 Final status code: ${e.response?.statusCode ?? 500}');
        return AuthResponse.error(
          message: message,
          statusCode: e.response?.statusCode ?? 500,
        );
      }
    } catch (e, stack) {
      print('Login exception: $e');
      print('Stack trace: $stack');
      return AuthResponse.error(
        message: 'An error occurred during login',
        statusCode: 500,
        );
    }
  }

  Future<AuthResponse> signup({
    required String email,
    required String password,
  }) async {
    try {
      print('Repository: Starting signup process...');
      print('Repository: Email: $email');
      
      final requestData = {
        'email': email,
        'password': password,
      };
      print('Repository: Signup request data: $requestData');
      
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          }
      ));
      
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('Dio: $object'),
      ));
      
      try {
        final response = await dio.post(
          '/auth/signup',
          data: requestData,
        );
        print('Repository: Raw server response: ${response.data}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Create success response with message
          return AuthResponse.success(
            message: response.data['message'] as String? ?? 'Signup successful',
            user: null,
            token: null,
        );
        } else {
          final message = response.data['message'] ?? 'Signup failed';
          print('Repository: Signup failed with message: $message');
          return AuthResponse.error(
            message: message,
            statusCode: response.statusCode ?? 500, 
        );
        }
    } on DioException catch (e) {
        print('Repository: DioException: ${e.message}');
        print('Repository: DioException type: ${e.type}');
        print('Repository: DioException response: ${e.response?.data}');
        
        final errorMessage = e.response?.data['message'] ?? 'An error occurred';
        print('Repository: Error message: $errorMessage');
        return AuthResponse.error(
          message: errorMessage,
          statusCode: e.response?.statusCode ?? 500,
        );
      }
    } catch (e, stack) {
      print('Repository: Signup exception: $e');
      print('Repository: Stack trace: $stack');
      return AuthResponse.error(
        message: 'An error occurred during signup',
        statusCode: 500,
        );
    }
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      print('Repository: Starting OTP verification...');
      print('Repository: Email: $email, OTP: $otp');
      
      final requestData = {
        'email': email,
        'otp': otp,
      };
      print('Repository: OTP verification request data: $requestData');
      
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          }
      ));
      
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('Dio: $object'),
      ));
      
      try {
        final response = await dio.post(
          '/auth/verify-otp',
          data: requestData,
        );
        print('Repository: Raw server response: ${response.data}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Create success response with token
          return AuthResponse.success(
            message: response.data['message'] as String?,
            token: response.data['token'] as String,
            user: null, 
        );
        } else {
          final message = response.data['message'] ?? 'OTP verification failed';
          print('Repository: OTP verification failed with message: $message');
          return AuthResponse.error(
            message: message,
            statusCode: response.statusCode ?? 500,
        );
        }
      } on DioException catch (e) {
        print('Repository: DioException: ${e.message}');
        print('Repository: DioException type: ${e.type}');
        print('Repository: DioException response: ${e.response?.data}');
        
        final errorMessage = e.response?.data['message'] ?? 'An error occurred';
        print('Repository: Error message: $errorMessage');
        return AuthResponse.error(
          message: errorMessage,
          statusCode: e.response?.statusCode ?? 500,
        );
      }
    } catch (e, stack) {
      print('Repository: OTP verification exception: $e');
      print('Repository: Stack trace: $stack');
      return AuthResponse.error(
        message: 'An error occurred during OTP verification',
        statusCode: 500,
        );
    }
  }

  Future<AuthResponse> resendOtp(String email) async {
    try {
      return await _apiClient.resendOtp(ResendOtpRequest(email: email));
    } on DioException catch (e) {
      return AuthResponse.error(
        message: e.response?.data['message'] ?? 'An error occurred',
        statusCode: e.response?.statusCode ?? 500,
        );
    }
  }

  Future<AuthResponse> requestPasswordReset(String email) async {
    try {
      return await _apiClient.requestPasswordReset({'email': email});
    } on DioException catch (e) {
      return AuthResponse.error(
        message: e.response?.data['message'] ?? 'An error occurred',
        statusCode: e.response?.statusCode ?? 500,
        );
    }
  }

  Future<AuthResponse> verifyPasswordReset({
    required String email,
    required String otp,
  }) async {
    try {
      return await _apiClient.verifyPasswordReset({
        'email': email,
        'otp': otp,
      });
    } on DioException catch (e) {
      return AuthResponse.error(
        message: e.response?.data['message'] ?? 'An error occurred',
        statusCode: e.response?.statusCode ?? 500,
        );
    }
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      return await _apiClient.resetPassword({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      return AuthResponse.error(
        message: e.response?.data['message'] ?? 'An error occurred',
        statusCode: e.response?.statusCode ?? 500,  
        );
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<UserData?> _getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authData = prefs.getString('auth_data');
      if (authData != null) {
        final Map<String, dynamic> userDataMap = json.decode(authData);
        return UserData.fromJson(userDataMap);
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  @override
  Future<AuthResponse> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('getProfile: No token found');
        return AuthResponse.error(message: 'Not authenticated', statusCode: 401);
      }

      print('getProfile: Fetching profile with token: $token');
      
      // Use Dio directly to get raw response for debugging
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      ));
      
      final response = await dio.get('/auth/profile');
      
      print('📊 getProfile - Raw profile response: ${response.data}');
      print('📊 getProfile - Response status: ${response.statusCode}');
      
      if (response.data['user'] != null) {
        print('📊 getProfile - User data exists in response');
        print('📊 getProfile - Earnings history in response: ${response.data['user']['earningsHistory']}');
        print('📊 getProfile - Earnings history type: ${response.data['user']['earningsHistory']?.runtimeType}');
        if (response.data['user']['earningsHistory'] != null) {
          print('📊 getProfile - Earnings history is array: ${response.data['user']['earningsHistory'] is List}');
          print('📊 getProfile - Earnings history length: ${(response.data['user']['earningsHistory'] as List?)?.length ?? 0}');
          if (response.data['user']['earningsHistory'] is List && (response.data['user']['earningsHistory'] as List).isNotEmpty) {
            print('📊 getProfile - First earnings history item: ${(response.data['user']['earningsHistory'] as List).first}');
          }
        }
        print('📊 getProfile - Total earnings: ${response.data['user']['totalEarnings']}');
      }
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Debug parsed earnings history
      if (authResponse.isSuccess && authResponse.user != null) {
        print('📊 getProfile - Parsed user data earnings history: ${authResponse.user!.earningsHistory}');
        print('📊 getProfile - Parsed earnings history type: ${authResponse.user!.earningsHistory.runtimeType}');
        if (authResponse.user!.earningsHistory != null) {
          print('📊 getProfile - Parsed earnings history length: ${authResponse.user!.earningsHistory!.length}');
          if (authResponse.user!.earningsHistory!.isNotEmpty) {
            print('📊 getProfile - First earnings history item: ${authResponse.user!.earningsHistory!.first}');
            print('📊 getProfile - First earnings history item keys: ${authResponse.user!.earningsHistory!.first.keys}');
          }
        }
        print('📊 getProfile - Parsed total earnings: ${authResponse.user!.totalEarnings}');
        
        print('getProfile: User data contains application status: ${authResponse.user!.collectorApplicationStatus}');
        print('getProfile: User data contains application ID: ${authResponse.user!.collectorApplicationId}');
        print('getProfile: User data contains application applied at: ${authResponse.user!.collectorApplicationAppliedAt}');
      }

      return authResponse;
    } catch (e) {
      print('getProfile: Exception: $e');
      if (e is DioException) {
        print('getProfile: DioException type: ${e.type}');
        print('getProfile: DioException response: ${e.response?.data}');
        // Handle error message that could be a string or list
        dynamic errorMessage = e.response?.data['message'];
        String message;
        if (errorMessage is List) {
          message = errorMessage.join(', ');
        } else {
          message = errorMessage?.toString() ?? 'Failed to fetch profile';
        }
        
        return AuthResponse.error(
          message: message,
          statusCode: e.response?.statusCode ?? 500,  
        );
      }
      return AuthResponse.error(message: 'Failed to fetch profile', statusCode: 500);
    }
  }

  Future<AuthResponse> setupProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? profilePhoto,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('setupProfile: No token found');
        return AuthResponse.error(message: 'Not authenticated', statusCode: 401);
      }

      print('setupProfile: Setting up profile with token: $token');
      
      // Get current user data to merge with updates
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        print('setupProfile: Could not get current user data');
        return AuthResponse.error(message: 'Could not get current user data', statusCode: 500);
      }
      
      // Build complete profile data - name, phoneNumber, and address are now required
      // Only send fields that are in SetupProfileDto (name, phoneNumber, address, profilePhoto)
      // Do NOT send 'roles' as it's not in the DTO and will cause validation failure with forbidNonWhitelisted
      final data = <String, dynamic>{
        'name': name ?? currentUser.name ?? '', // name is required by backend
        'phoneNumber': phoneNumber ?? currentUser.phoneNumber ?? '', // phoneNumber is now required
        'address': address ?? currentUser.address ?? '', // address is now required
      };
      
      // Only include profilePhoto if provided (it's optional)
      if (profilePhoto != null) {
        data['profilePhoto'] = profilePhoto;
      } else if (currentUser.profilePhoto != null) {
        data['profilePhoto'] = currentUser.profilePhoto;
      }

      print('setupProfile: Sending data: $data');
      final response = await _apiClient.setupProfile(data, 'Bearer $token');
      print('setupProfile: Response: $response');

      return response;
    } on DioException catch (e) {
      print('setupProfile: DioException: ${e.message}');
      print('setupProfile: DioException response: ${e.response?.data}');
      
      // Handle error message that could be a string or list
      dynamic errorMessage = e.response?.data['message'];
      String message;
      if (errorMessage is List) {
        message = errorMessage.join(', ');
      } else {
        message = errorMessage?.toString() ?? 'An error occurred';
      }
      
      return AuthResponse.error(
        message: message,
        statusCode: e.response?.statusCode ?? 500,
        );
    } catch (e) {
      print('setupProfile: Exception: $e');
      return AuthResponse.error(
        message: 'An error occurred during profile setup',
        statusCode: 500,
        );
    }
  }

  Future<AuthResponse> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? profilePhoto,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('updateProfile: No token found');
        return AuthResponse.error(message: 'Not authenticated', statusCode: 401);
      }

      print('updateProfile: Updating profile with token: $token');
      
      // Get current user data to merge with updates
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        print('updateProfile: Could not get current user data');
        return AuthResponse.error(message: 'Could not get current user data', statusCode: 500);
      }
      
      // Build complete profile data by merging current data with updates
      // Only send fields that are in SetupProfileDto (name, phoneNumber, address, profilePhoto)
      // Do NOT send 'roles' as it's not in the DTO and will cause validation failure with forbidNonWhitelisted
      final data = <String, dynamic>{
        'name': name ?? currentUser.name ?? '', // name is required by backend
      };
      
      // Only include fields that are provided or have current values
      if (phoneNumber != null) {
        data['phoneNumber'] = phoneNumber;
      } else if (currentUser.phoneNumber != null) {
        data['phoneNumber'] = currentUser.phoneNumber;
      }
      
      if (address != null) {
        data['address'] = address;
      } else if (currentUser.address != null) {
        data['address'] = currentUser.address;
      }
      
      if (profilePhoto != null) {
        data['profilePhoto'] = profilePhoto;
      } else if (currentUser.profilePhoto != null) {
        data['profilePhoto'] = currentUser.profilePhoto;
      }

      print('updateProfile: Sending data: $data');
      final response = await _apiClient.updateProfile(data, 'Bearer $token');
      print('updateProfile: Response: $response');

      return response;
    } on DioException catch (e) {
      print('updateProfile: DioException: ${e.message}');
      print('updateProfile: DioException response: ${e.response?.data}');
      
      // Handle error message that could be a string or list
      dynamic errorMessage = e.response?.data['message'];
      String message;
      if (errorMessage is List) {
        message = errorMessage.join(', ');
      } else {
        message = errorMessage?.toString() ?? 'An error occurred';
      }
      
      return AuthResponse.error(
        message: message,
        statusCode: e.response?.statusCode ?? 500,
        );
    } catch (e) {
      print('updateProfile: Exception: $e');
      return AuthResponse.error(
        message: 'An error occurred during profile update',
        statusCode: 500,
        );
    }
  }

  @override
  Future<AuthResponse> logout(String token) async {
    try {
      print('Repository: Logging out with token: $token');
      final response = await _apiClient.logout(token);
      print('Repository: Logout response: $response');
      return response;
    } on DioException catch (e) {
      print('Repository: Logout error: ${e.message}');
      print('Repository: Logout error type: ${e.type}');
      print('Repository: Logout error response: ${e.response?.data}');
      // Handle error message that could be a string or list
      dynamic errorMessage = e.response?.data['message'];
      String message;
      if (errorMessage is List) {
        message = errorMessage.join(', ');
      } else {
        message = errorMessage?.toString() ?? 'An error occurred during logout';
      }
      
      return AuthResponse.error(
        message: message,
        statusCode: e.response?.statusCode ?? 500,
        );
    } catch (e) {
      print('Repository: Logout exception: $e');
      return AuthResponse.error(
        message: 'An error occurred during logout',
        statusCode: 500,
        );
    }
  }

  Future<AuthResponse> _handleApiCall(Future<AuthResponse> Function() apiCall) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print('Session expired - 401 Unauthorized');
        return AuthResponse.error(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }

  Future<AuthResponse> refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return AuthResponse.error(
          message: 'No authentication token found',
          statusCode: 401,
        );
      }
      
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          }
      ));
      
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('Dio: $object'),
      ));
      
      try {
        final response = await dio.get('/auth/profile');
        
        print('📊 refreshUserData - Raw profile response: ${response.data}');
        print('📊 refreshUserData - Response status: ${response.statusCode}');
        
        if (response.data['user'] != null) {
          print('📊 refreshUserData - User data exists in response');
          print('📊 refreshUserData - Reward history in response: ${response.data['user']['rewardHistory']}');
          print('📊 refreshUserData - Reward history type: ${response.data['user']['rewardHistory'].runtimeType}');
          if (response.data['user']['rewardHistory'] != null) {
            print('📊 refreshUserData - Reward history is array: ${response.data['user']['rewardHistory'] is List}');
            print('📊 refreshUserData - Reward history length: ${(response.data['user']['rewardHistory'] as List?)?.length ?? 0}');
            if (response.data['user']['rewardHistory'] is List && (response.data['user']['rewardHistory'] as List).isNotEmpty) {
              print('📊 refreshUserData - First reward history item: ${(response.data['user']['rewardHistory'] as List).first}');
            }
          }
          // Debug earnings history
          print('📊 refreshUserData - Earnings history in response: ${response.data['user']['earningsHistory']}');
          print('📊 refreshUserData - Earnings history type: ${response.data['user']['earningsHistory']?.runtimeType}');
          if (response.data['user']['earningsHistory'] != null) {
            print('📊 refreshUserData - Earnings history is array: ${response.data['user']['earningsHistory'] is List}');
            print('📊 refreshUserData - Earnings history length: ${(response.data['user']['earningsHistory'] as List?)?.length ?? 0}');
            if (response.data['user']['earningsHistory'] is List && (response.data['user']['earningsHistory'] as List).isNotEmpty) {
              print('📊 refreshUserData - First earnings history item: ${(response.data['user']['earningsHistory'] as List).first}');
            }
          }
          print('📊 refreshUserData - Total earnings: ${response.data['user']['totalEarnings']}');
        }
        
        if (response.statusCode == 200) {
          final userData = UserData.fromJson(response.data['user']);
          print('📊 refreshUserData - Parsed user data reward history: ${userData.rewardHistory}');
          print('📊 refreshUserData - Parsed reward history type: ${userData.rewardHistory.runtimeType}');
          if (userData.rewardHistory != null) {
            print('📊 refreshUserData - Parsed reward history length: ${userData.rewardHistory!.length}');
          }
          
          // Debug parsed earnings history
          print('📊 refreshUserData - Parsed user data earnings history: ${userData.earningsHistory}');
          print('📊 refreshUserData - Parsed earnings history type: ${userData.earningsHistory.runtimeType}');
          if (userData.earningsHistory != null) {
            print('📊 refreshUserData - Parsed earnings history length: ${userData.earningsHistory!.length}');
            if (userData.earningsHistory!.isNotEmpty) {
              print('📊 refreshUserData - First earnings history item: ${userData.earningsHistory!.first}');
              print('📊 refreshUserData - First earnings history item keys: ${userData.earningsHistory!.first.keys}');
            }
          }
          print('📊 refreshUserData - Parsed total earnings: ${userData.totalEarnings}');
          
          return AuthResponse.success(
            user: userData,
            token: token,
            message: 'Profile refreshed successfully',
        );
        } else {
          final message = response.data['message'] ?? 'Failed to refresh profile';
          print('Profile refresh failed with message: $message');
          return AuthResponse.error(
            message: message,
            statusCode: response.statusCode ?? 500,
        );
        }
    } on DioException catch (e) {
        print('DioException: ${e.message}');
        print('DioException type: ${e.type}');
        print('DioException response: ${e.response?.data}');
        
        // Handle error message that could be a string or list
        dynamic errorMessage = e.response?.data['message'];
        String message;
        if (errorMessage is List) {
          message = errorMessage.join(', ');
        } else {
          message = errorMessage?.toString() ?? 'An error occurred';
        }
        print('Error message: $message');
        return AuthResponse.error(
          message: message,
          statusCode: e.response?.statusCode ?? 500,
        );
      }
    } catch (e) {
      print('Unexpected error during profile refresh: $e');
      return AuthResponse.error(
        message: 'An unexpected error occurred',
        statusCode: 500,
        );
    }
  }

  Future<void> invalidateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('⚠️ No token found, cannot invalidate session');
        return;
      }
      
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      ));
      
      try {
        await dio.post('/auth/invalidate-session');
        print('✅ Session invalidated successfully');
      } on DioException catch (e) {
        print('❌ Error invalidating session: ${e.message}');
        // Don't throw, just log the error
      }
    } catch (e) {
      print('❌ Error invalidating session: $e');
      // Don't throw, just log the error
    }
  }

  Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _apiClient.sendPhoneOTP(phoneNumber, 'Bearer $token');
      return response;
    } catch (e) {
      print('sendPhoneOTP: Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPhoneOTP(String phoneNumber, String otp) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _apiClient.verifyPhoneOTP(phoneNumber, otp, 'Bearer $token');
      return response;
    } catch (e) {
      print('verifyPhoneOTP: Error: $e');
      rethrow;
    }
  }
} 