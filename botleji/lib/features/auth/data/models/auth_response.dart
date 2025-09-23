import 'user_data.dart';

class AuthResponse {
  final bool isSuccess;
  final UserData? user;
  final String? token;
  final String? message;
  final String? errorMessage;
  final int? statusCode;

  const AuthResponse._({
    required this.isSuccess,
    this.user,
    this.token,
    this.message,
    this.errorMessage,
    this.statusCode,
  });

  factory AuthResponse.success({
    UserData? user,
    String? token,
    String? message,
  }) {
    return AuthResponse._(
      isSuccess: true,
      user: user,
      token: token,
      message: message,
  );
  }

  factory AuthResponse.error({
    required String message,
    int statusCode = 401,
  }) {
    return AuthResponse._(
      isSuccess: false,
      statusCode: statusCode,
  );
  }

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    print('AuthResponse.fromJson: Parsing response: $json');
    print('AuthResponse.fromJson: Contains token: ${json.containsKey('token')}');
    print('AuthResponse.fromJson: Contains user: ${json.containsKey('user')}');
    print('AuthResponse.fromJson: Contains message: ${json.containsKey('message')}');
    
    // Error response format: {"message": "...", "error": "...", "statusCode": xxx}
    if (json.containsKey('error')) {
      print('AuthResponse.fromJson: Error response detected');
      return AuthResponse.error(
        message: json['message'] as String? ?? 'An error occurred',
        statusCode: json['statusCode'] as int? ?? 401,
  );
    }

    // Success response format for login: {"user": {...}, "token": "..."}
    if (json.containsKey('user') && json.containsKey('token')) {
      print('AuthResponse.fromJson: Login response detected');
      return AuthResponse.success(
        user: UserData.fromJsonWithDebug(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
        message: json['message'] as String?,  
  );
    }

    // Profile response format: {"user": {...}}
    if (json.containsKey('user')) {
      print('AuthResponse.fromJson: Profile response detected');
      return AuthResponse.success(
        user: UserData.fromJsonWithDebug(json['user'] as Map<String, dynamic>),
        token: null,
        message: null,
  );
    }

    // Success response format for OTP verification: {"message": "...", "token": "...", "user": {...}}
    if (json.containsKey('token') && json.containsKey('user')) {
      print('AuthResponse.fromJson: OTP verification response with user data detected');
      print('AuthResponse.fromJson: User data: ${json['user']}');
      final userData = UserData.fromJsonWithDebug(json['user'] as Map<String, dynamic>);
      print('AuthResponse.fromJson: Parsed user data: $userData');
      return AuthResponse.success(
        message: json['message'] as String?,
        token: json['token'] as String,
        user: userData,
  );
    }

    // Success response format for OTP verification (old format): {"message": "...", "token": "..."}
    if (json.containsKey('token') && !json.containsKey('user')) {
      print('AuthResponse.fromJson: OTP verification response detected (no user data)');
      return AuthResponse.success(
        message: json['message'] as String?,
        token: json['token'] as String,
        user: null, 
  );
    }

    // Success response format for signup or password reset: {"message": "..."}
    if (json.containsKey('message')) {
      print('AuthResponse.fromJson: Message-only response detected');
      return AuthResponse.success(
        message: json['message'] as String,
        user: null,
        token: null,
  );
    }

    // Default error response if no known format is matched
    print('AuthResponse.fromJson: Unknown response format');
    return AuthResponse.error(
      message: 'Invalid response format',
      statusCode: 500,
  );
  }

  // Helper methods to replace when() functionality
  T when<T>({
    required T Function(UserData? user, String? token, String? message) success,
    required T Function(String message, int statusCode) error,
  }) {
    if (isSuccess) {
      return success(user, token, message);
    } else {
      return error(errorMessage ?? 'Unknown error', statusCode ?? 500);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResponse &&
        other.isSuccess == isSuccess &&
        other.user == user &&
        other.token == token &&
        other.message == message &&
        other.errorMessage == errorMessage &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      isSuccess,
      user,
      token,
      message,
      errorMessage,
      statusCode,
  );
  }

  @override
  String toString() {
    return 'AuthResponse(isSuccess: $isSuccess, user: $user, token: $token, message: $message, errorMessage: $errorMessage, statusCode: $statusCode)';
  }
} 