import 'package:flutter/material.dart';
import 'dart:math';
import 'package:get/get.dart';
import 'package:speedobot/screens/screens_home/icon.dart';


import 'package:speedobot/screens/screens_chat/ChatScreen.dart';
import 'package:speedobot/screens/screens_chat/pdf_tools_screen.dart';
import 'package:speedobot/screens/screens_chat/grammar_check_screen.dart';
import 'package:speedobot/screens/screens_chat/humanizer_screen.dart';
import 'package:speedobot/screens/screens_chat/compose_email_screen.dart';
import 'package:speedobot/screens/screens_chat/write_essay_screen.dart';
import 'package:speedobot/screens/screens_chat/translate_screen.dart';
import 'package:speedobot/screens/screens_chat/song_lyrics_screen.dart';
import 'package:speedobot/screens/screens_chat/image_generation_screen.dart';
import 'package:speedobot/screens/screens_chat/forecast_development_screen.dart';
import 'package:speedobot/screens/screens_chat/recipe_generator_screen.dart';
import 'package:speedobot/screens/screens_chat/math_solver_screen.dart';
import 'package:speedobot/screens/screens_chat/science_screen.dart';
import 'package:speedobot/screens/screens_chat/history_screen.dart';
import 'package:speedobot/screens/screens_chat/geography_screen.dart';
import 'package:speedobot/screens/screens_chat/philosophy_screen.dart';
import 'package:speedobot/screens/screens_chat/medical_screen.dart';
import 'package:speedobot/screens/screens_chat/computer_science_screen.dart';
import 'package:speedobot/screens/screens_chat/horoscope_screen.dart';
import 'package:speedobot/screens/screens_chat/tarot_screen.dart';
import 'package:speedobot/screens/screens_chat/therapist_screen.dart';
import 'package:speedobot/screens/screens_chat/recomend_place_screen.dart';
import 'package:speedobot/screens/screens_chat/dream_interpreter_screen.dart';
import 'package:speedobot/screens/screens_chat/AnalyzeImageScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // Variables et contrôleurs
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late AnimationController _arrowController;
  late AnimationController _gradientRotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _currentTitle = 'chat'.tr;
  IconData _currentIcon = Icons.chat;
  int _selectedMenuIndex = 0;
  int _activeItemIndex = -1;
  double _rotationAngle = 0.0;

final List<Map<String, dynamic>> _menuItems = [
  {'icon': Icons.chat, 'label': 'chat'.tr, 'screen': const ChatScreen()},
  {'icon': Icons.analytics, 'label': 'analyze_image'.tr, 'screen': const AnalyzeImageScreen()},
  {'icon': Icons.picture_as_pdf, 'label': 'pdf_tools'.tr, 'screen': const PdfFormScreen()},
  {'icon': Icons.check_circle_outline, 'label': 'grammar_check'.tr, 'screen': const GrammarCheckScreen()},
  {'icon': Icons.account_circle, 'label': 'humanizer'.tr, 'screen': const HumanizerScreen()},
  {'icon': Icons.email, 'label': 'compose_email'.tr, 'screen': const ComposeEmailScreen()},
  {'icon': Icons.article, 'label': 'write_essay'.tr, 'screen': const WriteEssayScreen()},
  {'icon': Icons.language, 'label': 'translate'.tr, 'screen': const TranslateScreen()},
  {'icon': Icons.music_note, 'label': 'song_lyrics'.tr, 'screen': const SongLyricsScreen()},
  {'icon': Icons.image, 'label': 'image_generation'.tr, 'screen': const ImageGenerationScreen()},
  {'icon': Icons.cloud, 'label': 'forecast_development'.tr, 'screen': const ForecastDevelopmentScreen()},
  {'icon': Icons.restaurant, 'label': 'recipe_generator'.tr, 'screen': const RecipeGeneratorScreen()},
  {'icon': Icons.calculate, 'label': 'math_solver'.tr, 'screen': const MathSolverScreen()},
  {'icon': Icons.science, 'label': 'science'.tr, 'screen': const ScienceScreen()},
  {'icon': Icons.history, 'label': 'history'.tr, 'screen': const HistoryScreen()},
  {'icon': Icons.map, 'label': 'geography'.tr, 'screen': const GeographyScreen()},
  {'icon': Icons.lightbulb_outline, 'label': 'philosophy'.tr, 'screen': const PhilosophyScreen()},
  {'icon': Icons.medical_services, 'label': 'medical'.tr, 'screen': const MedicalScreen()},
  {'icon': Icons.computer, 'label': 'computer_science'.tr, 'screen': const ComputerScienceScreen()},
  {'icon': Icons.alarm, 'label': 'horoscope'.tr, 'screen': const HoroscopeScreen()},
  {'icon': Icons.star, 'label': 'tarot'.tr, 'screen': const TarotScreen()},
  {'icon': Icons.health_and_safety, 'label': 'therapist'.tr, 'screen': const TherapistScreen()},
  {'icon': Icons.location_city, 'label': 'recomend_place'.tr, 'screen': const RecomendPlaceScreen()},
  {'icon': Icons.interpreter_mode, 'label': 'dream_interpreter'.tr, 'screen': const DreamInterpreterScreen()},
];


  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

     _gradientRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

     _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween(begin: 0.95, end: 1.05).animate(_pulseController);
  
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      _activeItemIndex = -1;
      _isMenuOpen ? _animationController.forward() : _animationController.reverse();
    });
  }
  

  void _changeTitleAndIcon(int index) {
    setState(() {
      _currentTitle = _menuItems[index]['label'];
      _currentIcon = _menuItems[index]['icon'];
      _activeItemIndex = index;
    });
  }

  void _navigateToSelectedScreen() {
    setState(() {
      _selectedMenuIndex = _activeItemIndex;
      _isMenuOpen = false;
      _activeItemIndex = -1;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Icon(
            _currentIcon,
            size: 30,
            color: const Color(0xFF41be8c), // Icône avec couleur fixe
          ),
          const SizedBox(width: 10),
          Text(
            _currentTitle,
            style: TextStyle(
              color: const Color(0xFF41be8c), // Texte avec couleur fixe
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: _buildAppBarBackground(context),  // Passage de `context` ici
      actions: [
       IconButton(
  icon: AnimatedSwitcher(
    duration: const Duration(milliseconds: 500),
    transitionBuilder: (child, animation) {
      return RotationTransition(
        turns: Tween<double>(begin: 0.5, end: 1).animate(animation),
        child: ScaleTransition(
          scale: animation,
          child: child,
        ),
      );
    },
    child: _isMenuOpen
        ? Container(
            key: const ValueKey('close'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF41be8c),
                  const Color(0xFF3ECAA7),
                ],
                transform: const GradientRotation(0.785),
              ),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 28,
              color: Colors.white,
            ),
          )
        : const AnimatedRobotIcon(), // Nouveau robot
  ),
  onPressed: _toggleMenu,
),
      ],
    ),
    body: Stack(
      children: [
        IndexedStack(
          index: _selectedMenuIndex,
          children: _menuItems.map((item) => item['screen'] as Widget).toList(),
        ),
        if (_isMenuOpen) _buildRotatingMenu(),
        if (_activeItemIndex >= 0) _buildCenterMenuItem(),
      ],
    ),
  );
}




Widget _buildAppBarBackground(BuildContext context) {
  // Utiliser la couleur du thème actuel
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0a0e17) // couleur sombre pour le mode sombre
              : const Color(0xFFFFFFFF), // blanc pour le mode clair
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF02111a) // couleur sombre pour le mode sombre
              : const Color(0xFFFFFFFF), // blanc pour le mode clair
        ],
      ),
    ),
  );
}



Widget _buildRotatingMenu() {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;

  // Ajuster la taille du menu en fonction de la largeur de l'écran
  double menuSize = screenWidth > 600 ? 400 : 350; // Menu plus grand sur les écrans larges
  double iconSize = screenWidth > 600 ? 30 : 15;  // Ajuster la taille des icônes en fonction de l'écran

  return GestureDetector(
    onTap: _toggleMenu,
    child: Container(
      color: Colors.black.withOpacity(0.95),
      child: Stack(
        children: [
          // Titre animé
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, sin(_pulseController.value * 2 * pi) * 5),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          const Color(0xFF6FEDD8),
                          const Color(0xFF3ECAA7),
                          Color(0xFF3F51B5), // Indigo
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'choose_your_domain'.tr,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rotationAngle += details.primaryDelta! * 0.01;
                });
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_animationController, _gradientRotationController, _pulseController]),
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateZ(_rotationAngle),
                    alignment: Alignment.center,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: menuSize,
                        height: menuSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              const Color(0xFF6FEDD8),
                              Color.fromRGBO(54, 166, 189, 1.0),
                              const Color(0xFF3ECAA7),
                              const Color(0xFF2A8F7A),
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                            transform: GradientRotation(_gradientRotationController.value * 2 * pi),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(54, 166, 189, 0.4),
                              blurRadius: 30,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: const Color(0xFF3ECAA7).withOpacity(0.3),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: 0.7,
                                    child: Transform.scale(
                                      scale: 1 + (_pulseController.value * 0.1),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 60,
                                        height: 60,
                                        color: Colors.white.withOpacity(0.2),
                                        colorBlendMode: BlendMode.overlay,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            ...List.generate(_menuItems.length, (index) {
                              final angle = (2 * pi / _menuItems.length) * index;
                              return _buildHolographicMenuItem(angle, index, iconSize);
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

 Positioned _buildHolographicMenuItem(double angle, int index, double iconSize) {
  const radius = 150.0;
  double xPosition = 160 + radius * cos(angle) - (iconSize / 2);  // Ajuster la position en X
  double yPosition = 160 + radius * sin(angle) - (iconSize / 2);  // Ajuster la position en Y
  
  return Positioned(
    left: xPosition,
    top: yPosition,
    child: Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateZ(angle + pi/2),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..translate(0.0, _activeItemIndex == index ? -10.0 : 0.0),
        child: IconButton(
          icon: MouseRegion(
            onHover: (_) => setState(() => _activeItemIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _activeItemIndex == index
                      ? [
                          Color(0xFF6FEDD8).withOpacity(0.9),
                          Color(0xFF3ECAA7).withOpacity(0.9),
                        ]
                      : [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.black, // Bordure toujours noire
                  width: 2.0, // Épaisseur augmentée pour plus de visibilité
                ),
                boxShadow: _activeItemIndex == index
                    ? [
                        BoxShadow(
                          color: Color(0xFF6FEDD8).withOpacity(0.6),
                          blurRadius: 25,
                          spreadRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Color(0xFF3ECAA7).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              padding: EdgeInsets.all(iconSize / 2), // Ajuster le padding pour la taille de l'icône
              child: Icon(
                _menuItems[index]['icon'],
                size: iconSize, // Appliquer la taille dynamique de l'icône
                color: _activeItemIndex == index
                    ? Colors.white // Couleur quand actif/survolé
                    : Color.fromARGB(255, 8, 203, 154).withOpacity(0.9), // Couleur verte initiale
              ),
            ),
          ),
          onPressed: () => _changeTitleAndIcon(index),
        ),
      ),
    ),
  );
}

  Widget _buildCenterMenuItem() {
    final selectedItem = _menuItems[_activeItemIndex];
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_arrowController, _pulseController]),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..translate(0.0, sin(_arrowController.value * 2 * pi) * 5.0),
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
               gradient: const RadialGradient(
  colors: [
    Color(0xFF000000), // Noir pur
    Color(0xFF212121), // Noir légèrement éclairci
  ],
  radius: 0.75,
  stops: [0.4, 1.0],
),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _activeItemIndex = -1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: 1 + (_pulseController.value * 0.1),
                        child: Icon(
                          selectedItem['icon'],
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    selectedItem['label'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  AnimatedOpacity(
                    opacity: _arrowController.value,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      'click_to_confirm'.tr,
                      style: TextStyle(
                        color: Color(0xDEFFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MouseRegion(
                    onEnter: (_) => _arrowController.forward(),
                    onExit: (_) => _arrowController.reverse(),
                    child: GestureDetector(
                      onTap: _navigateToSelectedScreen,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateZ(pi / 4)
                          ..rotateX(-pi / 8),
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7120F2), Color(0xFF00F2FE)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _gradientRotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}