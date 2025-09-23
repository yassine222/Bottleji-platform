class UserData {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool isProfileComplete;
  final String? phoneNumber;
  final String? address;
  final String? profilePhoto;

  const UserData({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.isProfileComplete,
    this.phoneNumber,
    this.address,
    this.profilePhoto,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isProfileComplete': isProfileComplete,
      'phoneNumber': phoneNumber,
      'address': address,
      'profilePhoto': profilePhoto,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.isProfileComplete == isProfileComplete &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.profilePhoto == profilePhoto;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      role,
      isProfileComplete,
      phoneNumber,
      address,
      profilePhoto,
    );
  }

  @override
  String toString() {
    return 'UserData(id: $id, email: $email, name: $name, role: $role, isProfileComplete: $isProfileComplete, phoneNumber: $phoneNumber, address: $address, profilePhoto: $profilePhoto)';
  }
} 