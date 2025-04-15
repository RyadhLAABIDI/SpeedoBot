// lib/routes.dart

import 'package:flutter/material.dart';
import 'package:speedobot/screens/screens_home/home.dart'; // Importer ton HomeScreen
import 'package:speedobot/screens/screens_auth/login.dart';
import 'package:speedobot/screens/screens_auth/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      // Tu peux ajouter d'autres routes ici si tu as plus de pages
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found!'),
            ),
          ),
        );
    }
  }
}
