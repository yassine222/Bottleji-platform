import 'package:botleji/features/auth/data/models/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> signup(String email, String password);
  Future<AuthResponse> verifyOtp(String email, String otp);
  Future<AuthResponse> resendOtp(String email);
  Future<AuthResponse> requestPasswordReset(String email);
  Future<AuthResponse> verifyPasswordReset(String email, String otp);
  Future<AuthResponse> resetPassword(String email, String otp, String newPassword);
  Future<AuthResponse> getProfile(String token);
  Future<AuthResponse> updateProfile(String token, Map<String, dynamic> data);
  Future<AuthResponse> logout(String token);
} 