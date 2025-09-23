import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/models/auth_response.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController() : super(const AsyncValue.data(null));

  /// Login user
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = AuthRepository();
      final response = await repository.login(email: email, password: password);

      response.when(
        success: (user, message, statusCode) {
          if (user != null) {
            state = AsyncValue.data(User(
              id: user.id,
              email: user.email,
              name: user.name ?? email.split('@')[0],
            ));
          } else {
            state = const AsyncValue.data(null);
          }
        },
        error: (message, statusCode) {
          state = AsyncValue.error(message, StackTrace.current);
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Register user
  Future<AuthResponse> register(String email, String password) async {
    final repository = AuthRepository();
    return await repository.signup(email: email, password: password);
  }

  /// Logout user
  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = const AsyncValue.data(null);
  }

  /// Verify OTP
  Future<AuthResponse> verifyOtp(String email, String otp) async {
    final repository = AuthRepository();
    final response = await repository.verifyOtp(email: email, otp: otp);

    response.when(
      success: (user, message, statusCode) {
        if (user != null) {
          state = AsyncValue.data(User(
            id: user.id,
            email: user.email,
            name: user.name ?? email.split('@')[0],
          ));
        }
      },
      error: (message, statusCode) {
        // Optional: handle error
      },
    );

    return response;
  }
}

/// Riverpod provider
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(),
);
