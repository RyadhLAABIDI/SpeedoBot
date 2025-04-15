import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speedobot/routes/routes.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _instaAnimation;
  late Animation<Offset> _zealAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialisation du contrôleur d'animation
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // Animation pour "Insta" (depuis la gauche)
    _instaAnimation = Tween<Offset>(
      begin: Offset(-1.5, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Animation pour "Zeal" (depuis la droite)
    _zealAnimation = Tween<Offset>(
      begin: Offset(1.5, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Animation d'agrandissement du logo
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Lancer l'animation
    _controller.forward();

    // Naviguer après 4 secondes
    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home-bg.gif'),
            fit: BoxFit.cover, // Ajuste l'image pour couvrir tout l'écran
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animation du logo
              ScaleTransition(
                scale: _logoScaleAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                   'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Animation dynamique pour "Insta" et "Zeal"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SlideTransition(
                    position: _instaAnimation,
                    child: Text(
                        'speedo'.tr,
                        style: TextStyle(
                          fontFamily: 'Montserrat', // Nouvelle police professionnelle
                          fontSize: 50,
                          fontWeight: FontWeight.bold, // Plus de professionnalisme avec du gras
                          color: Color.fromRGBO(62, 202, 167, 1.0),
                          letterSpacing: 2.0, // Meilleure lisibilité
                        ),
                      ),

                      ),
                      SlideTransition(
                       position: _zealAnimation,
                        child: Text(
                        'bot'.tr,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(54, 166, 189, 1.0),
                          letterSpacing: 2.0,
                        ),
                      ),

                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
