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

  void setUser(User? user) {
    _user.value = user;
  }

  Future<void> initializeUser() async {
    final savedUser = await authService.getSavedUser();
    if (savedUser != null) {
      _user.value = savedUser;
    }
  }

Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    _isLoading.value = true;
    try {
      _user.value = await authService.register(name, email, password, passwordConfirmation);
      Get.toNamed('/verify-email', arguments: {'email': email});
    } catch (e) {
      _user.value = null;
      Get.snackbar("Erreur", "Échec de l'inscription: ${e.toString().split(':').last.trim()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      _isLoading.value = false;
    }
  }
  Future<void> login(String email, String password) async {
    _isLoading.value = true;
    try {
      _user.value = await authService.login(email, password);
      Get.offAllNamed('/home');
    } catch (e) {
      _user.value = null;
      Get.snackbar(
        'Erreur',
        'Échec de la connexion: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    _isLoading.value = true;
    try {
      await authService.verifyEmail(email, code);
      Get.snackbar(
        'Succès',
        'Email vérifié avec succès !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la vérification: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading.value = true;
    try {
      await authService.forgotPassword(email);
      Get.snackbar(
        'Succès',
        'Un code de réinitialisation a été envoyé à votre email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.toNamed('/verify-password-code', arguments: {'email': email});
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la demande: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verifyPasswordCode(String email, String code) async {
    _isLoading.value = true;
    try {
      await authService.verifyPasswordCode(email, code);
      Get.snackbar(
        'Succès',
        'Code vérifié avec succès !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.toNamed('/reset-password', arguments: {'email': email, 'code': code});
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la vérification: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email, String code, String password, String passwordConfirmation) async {
    _isLoading.value = true;
    try {
      await authService.resetPassword(email, code, password, passwordConfirmation);
      Get.snackbar(
        'Succès',
        'Mot de passe réinitialisé avec succès ! Veuillez vous connecter.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la réinitialisation: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  String? getToken() {
    return _user.value?.token;
  }

  Future<void> logout() async {
    try {
      final token = getToken();

      if (token == null) {
        Get.snackbar(
          'Erreur',
          'Utilisateur non connecté',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await authService.logout(token);
      _user.value = null;
      update();
      Get.offAllNamed('/login');
      Get.snackbar(
        'Succès',
        'Déconnexion réussie',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Erreur de déconnexion: $e');
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