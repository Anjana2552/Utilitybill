class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}

class UserProfile {
  final int id;
  final User user;
  final String role;
  final String roleDisplay;
  final String? phone;
  final String? address;
  final String createdAt;
  final String updatedAt;

  UserProfile({
    required this.id,
    required this.user,
    required this.role,
    required this.roleDisplay,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      user: User.fromJson(json['user']),
      role: json['role'],
      roleDisplay: json['role_display'],
      phone: json['phone'],
      address: json['address'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'role': role,
      'role_display': roleDisplay,
      'phone': phone,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
