import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs(); // Charger la préférence de thème au démarrage
  }

  // Charger la préférence du thème à partir de SharedPreferences
  _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false; // Par défaut, thème clair
  }

  // Changer le thème et sauvegarder la préférence dans SharedPreferences
  void toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode.value); // Sauvegarder le choix du thème
  }
}
