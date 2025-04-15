import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speedobot/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://speedobot.com/api';
  static const String _userKey = 'current_user';

  Future<User?> register(String name, String email, String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      await _saveUser(user);
      return user;
    }
    throw Exception('Échec de l\'inscription: ${response.body}');
  }

  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print(jsonResponse["token"]);
      prefs.setString("Token", jsonResponse["token"]);
      final user = User.fromJson(jsonResponse);
      await _saveUser(user);
      return user;
    }
    throw Exception('Échec de la connexion: ${response.body}');
  }

  Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    print('Réponse de l\'API (logout) : ${response.body}');

    if (response.statusCode == 200) {
      await _clearUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("Token"); // Supprimer complètement la clé "Token"
    } else {
      throw Exception('Échec de la déconnexion: ${response.body}');
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