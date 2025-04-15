import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  // Observables
  var selectedLocale = const Locale('en', 'US').obs;

  // Clés pour SharedPreferences
  static const String languageKey = 'language';
  static const String countryKey = 'country';

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeLanguage(); // Chargement des préférences au démarrage
  }

  // Initialisation de la langue depuis SharedPreferences
  Future<void> initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(languageKey) ?? 'en';
    final savedCountryCode = prefs.getString(countryKey) ?? 'US';
    final locale = Locale(savedLanguageCode, savedCountryCode);

    print('Language loaded: $locale'); // Vérifiez si la langue est correctement chargée

    selectedLocale.value = locale;
    Get.updateLocale(locale); // Appliquer la langue sauvegardée
  }

  // Modification de la langue et sauvegarde dans SharedPreferences
  Future<void> changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, locale.languageCode);
    await prefs.setString(countryKey, locale.countryCode ?? '');

    selectedLocale.value = locale;
    Get.updateLocale(locale); // Appliquer la nouvelle langue immédiatement
  }
}

