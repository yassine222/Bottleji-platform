class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);

  @override
  String toString() => 'LoginRequest(email: $email, password: $password)';
}

class SignupRequest {
  final String email;
  final String password;
  final String fullName;
  final String phone;

  const SignupRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SignupRequest &&
        other.email == email &&
        other.password == password &&
        other.fullName == fullName &&
        other.phone == phone;
  }

  @override
  int get hashCode => Object.hash(email, password, fullName, phone);

  @override
  String toString() => 'SignupRequest(email: $email, password: $password, fullName: $fullName, phone: $phone)';
}

class OtpVerificationRequest {
  final String email;
  final String otp;

  const OtpVerificationRequest({
    required this.email,
    required this.otp,
  });

  factory OtpVerificationRequest.fromJson(Map<String, dynamic> json) {
    return OtpVerificationRequest(
      email: json['email'] as String,
      otp: json['otp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OtpVerificationRequest &&
        other.email == email &&
        other.otp == otp;
  }

  @override
  int get hashCode => Object.hash(email, otp);

  @override
  String toString() => 'OtpVerificationRequest(email: $email, otp: $otp)';
}

class ResendOtpRequest {
  final String email;

  const ResendOtpRequest({
    required this.email,
  });

  factory ResendOtpRequest.fromJson(Map<String, dynamic> json) {
    return ResendOtpRequest(
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResendOtpRequest &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(email, email);

  @override
  String toString() => 'ResendOtpRequest(email: $email)';
} 