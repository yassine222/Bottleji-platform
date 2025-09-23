import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/auth_response.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(AuthRepository());
});

class AuthNotifier extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(false);

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = false;
  }

  Future<AuthResponse> signup({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthNotifier: Starting signup process...');
      print('AuthNotifier: Email: $email');
      
      final response = await _authRepository.signup(
        email: email,
        password: password,
      );
      
      print('AuthNotifier: Signup response: $response');
      
      response.when(
        success: (user, token, message) {
          print('AuthNotifier: Signup successful');
          print('AuthNotifier: Message: $message');
          // Don't set state or save auth data yet since user needs to verify OTP
          state = false;
        },
        error: (message, statusCode) {
          print('AuthNotifier: Signup failed');
          print('AuthNotifier: Error message: $message');
          print('AuthNotifier: Status code: $statusCode');
          state = false;
        },
      );
      
      return response;
    } catch (e) {
      print('AuthNotifier: Signup exception: $e');
      state = false;
      return AuthResponse.error(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }
  }
