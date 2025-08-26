import 'dart:convert';
import 'package:get/utils.dart';
import 'package:http/http.dart' as http;
import 'package:speedobot/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://speedobot.com/api';
  static const String _userKey = 'current_user';

  Future<User?> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 302) {
        throw Exception('redirect_detected'.tr);
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final user = User(
          name: jsonResponse['user']?['name'] ?? jsonResponse['name'] ?? '',
          email: jsonResponse['user']?['email'] ?? jsonResponse['email'] ?? '',
          token: jsonResponse['token'] ?? '',
        );
        await _saveUser(user);
        return user;
      } else {
        final errorJson = json.decode(response.body);
        final errorMessage = errorJson['message']?.toString().toLowerCase() ?? 'unknown_error'.tr;
        if (errorMessage.contains('email already used'.tr) || errorMessage.contains('email_already_used'.tr)) {
          throw Exception('email_already_used'.tr);
        }
        throw Exception('unknown_error'.tr);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("Token", jsonResponse["token"]);
        final user = User.fromJson(jsonResponse);
        await _saveUser(user);
        return user;
      } else {
        final errorJson = json.decode(response.body);
        final errorMessage = errorJson['message']?.toString().toLowerCase() ?? 'unknown_error'.tr;
        if (errorMessage.contains('invalid credential'.tr) || errorMessage.contains('invalid_credentials'.tr)) {
          throw Exception('invalid_credentials'.tr);
        }
        throw Exception('unknown_error'.tr);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _clearUser();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("Token");
      } else {
        final errorJson = json.decode(response.body);
        throw Exception(errorJson['message']?.toString() ?? 'unknown_error'.tr);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/email/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        return;
      }
      final errorJson = json.decode(response.body);
      throw Exception(errorJson['message']?.toString() ?? 'unknown_error'.tr);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/password/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return;
      }
      final errorJson = json.decode(response.body);
      throw Exception(errorJson['message']?.toString() ?? 'unknown_error'.tr);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyPasswordCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/password/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        return;
      }
      final errorJson = json.decode(response.body);
      throw Exception(errorJson['message']?.toString() ?? 'unknown_error'.tr);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String code, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200) {
        return;
      }
      final errorJson = json.decode(response.body);
      throw Exception(errorJson['message']?.toString() ?? 'unknown_error'.tr);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    return userJson != null ? User.fromJson(json.decode(userJson)) : null;
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}