import 'package:flutter/material.dart';
import 'package:speedobot/screens/screens_auth/auth_screens.dart';
import 'package:speedobot/screens/screens_auth/login.dart';
import 'package:speedobot/screens/screens_auth/splash_screen.dart';
import 'package:speedobot/screens/screens_home/home.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String verifyPasswordCode = '/verify-password-code';
  static const String resetPassword = '/reset-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) =>  SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case verifyEmail:
        return MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: args?['email'] as String? ?? '',
          ),
        );
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotScreen());
      case verifyPasswordCode:
        return MaterialPageRoute(
          builder: (_) => VerifyPasswordCodeScreen(
            email: args?['email'] as String? ?? '',
          ),
        );
      case resetPassword:
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: args?['email'] as String? ?? '',
            code: args?['code'] as String? ?? '',
          ),
        );
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