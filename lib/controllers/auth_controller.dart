import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedobot/services/auth_service.dart';
import 'package:flutter/material.dart';

import 'package:speedobot/models/user.dart';

class AuthController extends GetxController {
  final AuthService authService = AuthService();
  Rx<User?> _user = Rx<User?>(null);
  RxBool _isLoading = false.obs;

  User? get user => _user.value;
  bool get isLoading => _isLoading.value;

  // Nouvelle méthode pour définir l'utilisateur
  void setUser(User? user) {
    _user.value = user;
  }

  // Méthode pour initialiser l'utilisateur au démarrage
  Future<void> initializeUser() async {
    final savedUser = await authService.getSavedUser();
    if (savedUser != null) {
      _user.value = savedUser;
    }
  }

  // Méthode pour enregistrer un nouvel utilisateur
  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    _isLoading.value = true;
    try {
      _user.value = await authService.register(name, email, password, passwordConfirmation);
    } catch (e) {
      _user.value = null;
      Get.snackbar("Error", "Registration failed: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  // Méthode pour connecter un utilisateur
  Future<void> login(String email, String password) async {
    _isLoading.value = true;
    try {
      _user.value = await authService.login(email, password);
    } catch (e) {
      _user.value = null;
      Get.snackbar("Error", "Login failed: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  // Méthode pour récupérer le token si l'utilisateur est connecté
  String? getToken() {
    return _user.value?.token;
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    try {
      final token = getToken();

      if (token == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      await authService.logout(token); // Déléguer la déconnexion à AuthService
      _user.value = null; // Effacer les données utilisateur
      update(); // Mettre à jour l'état
      Get.offAllNamed('/login'); // Rediriger vers la page de login

      if (Get.context != null) {
        Get.snackbar(
          'Succès',
          'Déconnexion réussie',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Erreur de déconnexion: $e');
      if (Get.context != null) {
        Get.snackbar(
          'Erreur',
          'Une erreur est survenue lors de la déconnexion: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}