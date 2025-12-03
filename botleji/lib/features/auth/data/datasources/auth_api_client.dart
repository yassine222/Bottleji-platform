import 'package:dio/dio.dart';
import '../models/auth_request.dart';
import '../models/auth_response.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/server_config.dart';

class AuthApiClient {
  final Dio _dio;
  static String get baseUrl => ServerConfig.apiBaseUrlSync;

  AuthApiClient(this._dio) {
    // Add global interceptor to handle 401 errors
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token expiration gracefully
          _showSessionExpiredDialog();
          // Don't throw the error, just return a custom response
          handler.resolve(Response(
            requestOptions: error.requestOptions,
            data: {
              'message': 'Session expired',
              'error': 'Unauthorized',
              'statusCode': 401,
            },
          ));
        } else {
          handler.next(error);
        }
      },
    ),
    );
  }

  void _showSessionExpiredDialog() {
    // Show session expired dialog
    // This will be handled by the calling code
    print('Session expired - showing dialog');
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '$baseUrl/auth/login',
      data: request.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _dio.post(
      '$baseUrl/auth/signup',
      data: request.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> verifyOtp(OtpVerificationRequest request) async {
    final response = await _dio.post(
      '$baseUrl/auth/verify-otp',
      data: request.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> resendOtp(ResendOtpRequest request) async {
    final response = await _dio.post(
      '$baseUrl/auth/resend-otp',
      data: request.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> requestPasswordReset(Map<String, String> data) async {
    final response = await _dio.post(
      '$baseUrl/auth/request-password-reset',
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> verifyPasswordReset(Map<String, String> data) async {
    final response = await _dio.post(
      '$baseUrl/auth/verify-password-reset',
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> resetPassword(Map<String, String> data) async {
    final response = await _dio.post(
      '$baseUrl/auth/reset-password',
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> getProfile(String token) async {
    final response = await _dio.get(
      '$baseUrl/auth/profile',
      options: Options(headers: {'Authorization': token}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> logout(String token) async {
    final response = await _dio.post(
      '$baseUrl/auth/logout',
      options: Options(headers: {'Authorization': token}),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> setupProfile(Map<String, dynamic> data, String token) async {
    final response = await _dio.post(
      '$baseUrl/auth/setup-profile',
      data: data,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> updateProfile(Map<String, dynamic> data, String token) async {
    final response = await _dio.put(
      '$baseUrl/auth/update-profile',
      data: data,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber, String token) async {
    final response = await _dio.post(
      '$baseUrl/auth/send-phone-otp',
      data: {'phoneNumber': phoneNumber},
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPhoneOTP(String phoneNumber, String otp, String token) async {
    final response = await _dio.post(
      '$baseUrl/auth/verify-phone-otp',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      },
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmail(String otp, String token) async {
    final response = await _dio.post(
      '$baseUrl/auth/verify-email',
      data: {'otp': otp},
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resendEmailVerification(String token) async {
    final response = await _dio.post(
      '$baseUrl/auth/resend-email-verification',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> checkEmailAvailability(String email, String token) async {
    final response = await _dio.get(
      '$baseUrl/auth/check-email',
      queryParameters: {'email': email},
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      }),
    );
    return response.data as Map<String, dynamic>;
  }
} 