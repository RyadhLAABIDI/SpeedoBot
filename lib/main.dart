import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedobot/models/user.dart';
import 'package:speedobot/routes/routes.dart';
import 'package:speedobot/controllers/auth_controller.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/controllers/AppTranslations.dart';
import 'package:speedobot/controllers/TranslationController.dart';
import 'package:speedobot/screens/screens_auth/login.dart';
import 'package:speedobot/screens/screens_home/home.dart';

// Définir le RouteObserver global
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des contrôleurs
  final authController = Get.put(AuthController());
  final themeController = Get.put(ThemeController());
  final languageController = Get.put(LanguageController());

  // Attendre l'initialisation des préférences de thème et de langue
  await themeController.loadThemeFromPrefs(); // Nouvelle méthode pour attendre le chargement
  await languageController.initializeLanguage();

  // Vérifier l'état de l'utilisateur
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('Token');
  print("toke***************** : $token");

  // Charger l'utilisateur sauvegardé
  User? savedUser = await authController.authService.getSavedUser();
  if (savedUser != null && token != null && token.isNotEmpty) {
    authController.setUser(savedUser); // Utiliser la méthode setUser pour restaurer l'utilisateur
  }

  // Décider de l'écran initial
  Widget screen = (token != null && token.isNotEmpty && savedUser != null)
      ? const HomeScreen()
      : const AuthScreen();

  runApp(MegabotApp(screen: screen));
}

class MegabotApp extends StatelessWidget {
  final Widget screen;
  const MegabotApp({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Megabot',
          theme: ThemeData(
            fontFamily: 'Outfit',
            primarySwatch: Colors.blue,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF02111a),
            primaryColor: const Color(0xFF02111a),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF02111a),
            ),
          ),
          themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          translations: AppTranslations(),
          locale: languageController.selectedLocale.value,
          fallbackLocale: const Locale('en', 'US'),
          home: screen,
          onGenerateRoute: AppRoutes.generateRoute,
          navigatorObservers: [routeObserver], // Ajouter le RouteObserver
        ));
  }
}