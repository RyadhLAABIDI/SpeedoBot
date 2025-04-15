// lib/models/user.dart
class User {
  final String name;
  final String email;
  final String token;

  User({
    required this.name,
    required this.email,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'] ?? json['access_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'token': token,
    };
  }
}