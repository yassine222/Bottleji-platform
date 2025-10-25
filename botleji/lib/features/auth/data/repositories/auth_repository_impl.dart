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
        print('DioException: ${e.message}');
        print('DioException type: ${e.type}');
        print('DioException response: ${e.response?.data}');
        
        if (e.response?.statusCode == 404) {
          return AuthResponse.error(
            message: 'Invalid email or password',
            statusCode: 404,
        );
        }
        
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
      final response = await _apiClient.getProfile('Bearer $token');

      print('getProfile: Response data: $response');
      
      // Check if response contains application status
      if (response.isSuccess && response.user != null) {
        print('getProfile: User data contains application status: ${response.user!.collectorApplicationStatus}');
        print('getProfile: User data contains application ID: ${response.user!.collectorApplicationId}');
        print('getProfile: User data contains application applied at: ${response.user!.collectorApplicationAppliedAt}');
      }

      // For now, return the response directly to avoid when() issues
      return response;
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
      
      // Build complete profile data by merging current data with updates
      final data = <String, dynamic>{
        'name': name ?? currentUser.name ?? '', // name is required by backend
        'roles': currentUser.roles,
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
      final data = <String, dynamic>{
        'name': name ?? currentUser.name ?? '', // name is required by backend
        'roles': currentUser.roles,
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
        
        print('Raw profile response: ${response.data}');
        
        if (response.statusCode == 200) {
          return AuthResponse.success(
            user: UserData.fromJson(response.data['user']),
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
} 