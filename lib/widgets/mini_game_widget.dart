import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';

class MiniQuizGame extends StatefulWidget {
  final VoidCallback? onFinish;

  const MiniQuizGame({Key? key, this.onFinish}) : super(key: key);

  @override
  _MiniQuizGameState createState() => _MiniQuizGameState();
}

class _MiniQuizGameState extends State<MiniQuizGame>
    with TickerProviderStateMixin {
  late final List<_QuizQuestion> _questions;
  int _current = 0;
  int _score = 0;
  bool _locked = false;
  double _timeLeft = 1.0;
  Timer? _timer;
  int? _selectedIndex;
  late AnimationController _animationController;
  late AnimationController _bgAnimationController;
  final Random _random = Random();

  // Couleurs néon améliorées
  final Color neonBlue = const Color(0xFF00CFFF);
  final Color neonPink = const Color(0xFF00A896);
  final Color neonGreen = const Color(0xFF00FFC2);
  final Color neonPurple = const Color(0xFF14285E);
  final Color backgroundColor = const Color(0xFF0A0E2D);

  // Dégradés dynamiques
  List<Color> currentGradient = [];
  List<Alignment> gradientAlignment = [];
  Timer? _gradientTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _initializeQuestions();
    _startTimer();
    _initDynamicBackground();
  }

  void _initDynamicBackground() {
    // Initialiser le premier dégradé
    _updateGradient();
    
    // Changer le dégradé toutes les 5 secondes
    _gradientTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateGradient();
    });
  }

  void _updateGradient() {
    setState(() {
      // Générer un nouveau dégradé aléatoire
      currentGradient = [
        _generateNeonColor(),
        _generateNeonColor(),
        _generateNeonColor(),
      ];
      
      // Nouvelle position aléatoire
      gradientAlignment = [
        Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1),
        Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1),
      ];
    });
  }

  Color _generateNeonColor() {
    final colors = [neonBlue, neonPink, neonGreen, neonPurple];
    return colors[_random.nextInt(colors.length)].withOpacity(0.8);
  }

  void _initializeQuestions() {
    final List<_QuizQuestion> baseQuestions = [
      // Science
      _QuizQuestion(question: 'Quelle planète est la plus proche du Soleil ?', options: ['Terre', 'Mercure', 'Mars'], correctIndex: 1),
      _QuizQuestion(question: 'Combien de paires de chromosomes chez l\'humain ?', options: ['23', '46', '22'], correctIndex: 0),
      // Histoire
      _QuizQuestion(question: 'Qui a découvert l\'Amérique ?', options: ['Christophe Colomb', 'Napoléon', 'Einstein'], correctIndex: 0),
      _QuizQuestion(question: 'En quelle année a eu lieu la Révolution française ?', options: ['1789', '1492', '1914'], correctIndex: 0),
      // Géographie
      _QuizQuestion(question: 'Quelle est la capitale du Canada ?', options: ['Toronto', 'Vancouver', 'Ottawa'], correctIndex: 2),
      _QuizQuestion(question: 'Quel est le plus long fleuve du monde ?', options: ['Nil', 'Amazone', 'Yangtsé'], correctIndex: 1),
      // Sport
      _QuizQuestion(question: 'Combien de joueurs dans une équipe de football ?', options: ['9', '11', '10'], correctIndex: 1),
      _QuizQuestion(question: 'Quel pays a remporté la Coupe du Monde 2018 ?', options: ['Allemagne', 'Brésil', 'France'], correctIndex: 2),
      // Cinéma
      _QuizQuestion(question: 'Quel film a gagné l\'Oscar 2020 ?', options: ['Joker', '1917', 'Parasite'], correctIndex: 2),
      _QuizQuestion(question: 'Qui a réalisé Inception ?', options: ['Spielberg', 'Nolan', 'Cameron'], correctIndex: 1),
      //Entertainment
      _QuizQuestion(question: 'Qui est le roi de la pop ?', options: ['Elvis', 'Michael Jackson', 'Prince'], correctIndex: 1),
      _QuizQuestion(question: 'Quel instrument a 88 touches ?', options: ['Guitare', 'Piano', 'Pianola'], correctIndex: 1),
      // Informatique
      _QuizQuestion(question: 'Que signifie HTML ?', options: ['Hyper Text Markup Language', 'How To Make Logic', 'High Tech Modern Language'], correctIndex: 0),
      _QuizQuestion(question: 'Flutter est écrit en quel langage ?', options: ['Java', 'Kotlin', 'Dart'], correctIndex: 2),
      // Culture générale
      _QuizQuestion(question: 'Combien y a-t-il de continents ?', options: ['5', '6', '7'], correctIndex: 2),
      _QuizQuestion(question: 'Combien de côtés a un hexagone ?', options: ['5', '6', '8'], correctIndex: 1),
      // Ajout libre
      _QuizQuestion(question: 'Quel est l\'élément chimique O ?', options: ['Or', 'Oxygène', 'Osmium'], correctIndex: 1),
      _QuizQuestion(question: 'Quelle langue est la plus parlée dans le monde ?', options: ['Anglais', 'Mandarin', 'Espagnol'], correctIndex: 1),
      // Futuriste
      _QuizQuestion(question: 'Quelle technologie simule un environnement immersif ?', options: ['VR', 'AI', 'IoT'], correctIndex: 0),
      _QuizQuestion(question: 'Quel est le nom du robot d\'OpenAI ?', options: ['Siri', 'Alexa', 'ChatGPT'], correctIndex: 2),
      // Mathématiques
      _QuizQuestion(question: 'Combien font 7 x 8 ?', options: ['56', '64', '58'], correctIndex: 0),
      _QuizQuestion(question: 'Le nombre pi est...', options: ['Irrationnel', 'Rationnel', 'Entier'], correctIndex: 0),
      // Technologies web
      _QuizQuestion(question: 'CSS sert à...', options: ['Créer des bases de données', 'Styliser les pages web', 'Programmer des apps mobiles'], correctIndex: 1),
      _QuizQuestion(question: 'Quel protocole sécurise un site ?', options: ['HTTP', 'FTP', 'HTTPS'], correctIndex: 2),
      // Bonus divers
      _QuizQuestion(question: 'Quel métal est liquide à température ambiante ?', options: ['Fer', 'Mercure', 'Zinc'], correctIndex: 1),
      _QuizQuestion(question: 'Quel organe pompe le sang ?', options: ['Foie', 'Cœur', 'Poumon'], correctIndex: 1),
      // AI et Tech
      _QuizQuestion(question: 'Que signifie GPU ?', options: ['Graphical Processing Unit', 'General Program Unit', 'Giant Power Usage'], correctIndex: 0),
      _QuizQuestion(question: 'Quel est le langage de base du web ?', options: ['HTML', 'C++', 'Python'], correctIndex: 0),
      _QuizQuestion(question: 'Quelle est la couleur du sang dans le corps humain ?', options: ['Rouge', 'Bleu', 'Vert'], correctIndex: 0),
      _QuizQuestion(question: 'Quel est le plus grand océan ?', options: ['Atlantique', 'Arctique', 'Pacifique'], correctIndex: 2),
      _QuizQuestion(question: 'En quelle année l\'homme a-t-il marché sur la Lune ?', options: ['1969', '1975', '1959'], correctIndex: 0),
      _QuizQuestion(question: 'Quel pays est connu pour la samba ?', options: ['Mexique', 'Brésil', 'Argentine'], correctIndex: 1),
      _QuizQuestion(question: 'Combien de lettres dans l\'alphabet français ?', options: ['25', '26', '27'], correctIndex: 1),
      _QuizQuestion(question: 'Quelle est la capitale de l\'Australie ?', options: ['Sydney', 'Melbourne', 'Canberra'], correctIndex: 2),
      _QuizQuestion(question: 'Quel sport utilise une crosse ?', options: ['Hockey', 'Football', 'Basketball'], correctIndex: 0),
      _QuizQuestion(question: 'Qui a peint la Joconde ?', options: ['Van Gogh', 'Leonardo da Vinci', 'Picasso'], correctIndex: 1),
      _QuizQuestion(question: 'Quelle est la plus grande planète ?', options: ['Terre', 'Jupiter', 'Saturne'], correctIndex: 1),
      _QuizQuestion(question: 'Combien de zéros dans un milliard ?', options: ['6', '9', '12'], correctIndex: 1),
      _QuizQuestion(question: 'Quelle note est entre do et mi ?', options: ['La', 'Ré', 'Sol'], correctIndex: 1),
      _QuizQuestion(question: 'Quel est le symbole chimique du fer ?', options: ['Fe', 'Ir', 'In'], correctIndex: 0),
      _QuizQuestion(question: 'Quel organe est responsable de la digestion ?', options: ['Cœur', 'Estomac', 'Poumon'], correctIndex: 1),
      _QuizQuestion(question: 'Combien de cordes a une guitare classique ?', options: ['4', '6', '7'], correctIndex: 1),
      _QuizQuestion(question: 'Quel est l\'instrument principal du jazz ?', options: ['Trompette', 'Piano', 'Violon'], correctIndex: 0),
      _QuizQuestion(question: 'Quelle ville est surnommée la Ville Lumière ?', options: ['Londres', 'Paris', 'Tokyo'], correctIndex: 1),
      _QuizQuestion(question: 'Quel est le pays le plus peuplé ?', options: ['Chine', 'Inde', 'États-Unis'], correctIndex: 1),
      _QuizQuestion(question: 'Quel animal est le roi de la jungle ?', options: ['Tigre', 'Lion', 'Panthère'], correctIndex: 1),
      _QuizQuestion(question: 'Dans quelle mer se trouve l\'île de Chypre ?', options: ['Adriatique', 'Égée', 'Méditerranée'], correctIndex: 2),
      _QuizQuestion(question: 'Quel est le plus petit continent ?', options: ['Europe', 'Océanie', 'Afrique'], correctIndex: 1),
      _QuizQuestion(question: 'Qui a écrit "Les Misérables" ?', options: ['Zola', 'Victor Hugo', 'Molière'], correctIndex: 1),
      _QuizQuestion(question: 'Quel est le métal le plus léger ?', options: ['Aluminium', 'Lithium', 'Plomb'], correctIndex: 1),
      _QuizQuestion(question: 'Combien de jours dans une année bissextile ?', options: ['364', '365', '366'], correctIndex: 2),
      _QuizQuestion(question: 'Quel est le langage natif de l\'iPhone ?', options: ['Swift', 'Kotlin', 'C#'], correctIndex: 0),
      _QuizQuestion(question: 'Quel est le plus grand désert du monde ?', options: ['Sahara', 'Antarctique', 'Gobi'], correctIndex: 1),
      _QuizQuestion(question: 'Qui chante "Shape of You" ?', options: ['Ed Sheeran', 'Drake', 'Justin Bieber'], correctIndex: 0),
      _QuizQuestion(question: 'Combien de cœurs a une pieuvre ?', options: ['1', '2', '3'], correctIndex: 2),
      _QuizQuestion(question: 'Quelle est la capitale de la Tunisie ?', options: ['Tunis', 'Sfax', 'Bizerte'], correctIndex: 0),
      _QuizQuestion(question: 'Quelle console a lancé Mario pour la première fois ?', options: ['PlayStation', 'Game Boy', 'NES'], correctIndex: 2),
      _QuizQuestion(question: 'Quel est l\'acronyme de "intelligence artificielle" ?', options: ['IA', 'AI', 'IAI'], correctIndex: 1),
    ];
    baseQuestions.shuffle();
    _questions = baseQuestions;
  }

  void _startTimer() {
    _timeLeft = 1.0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft = (_timeLeft - 0.05 / 15).clamp(0.0, 1.0));
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    _timer?.cancel();
    if (_current + 1 < _questions.length) {
      _animationController.reset();
      _animationController.forward();
      
      setState(() {
        _current++;
        _locked = false;
        _selectedIndex = null;
      });
      _startTimer();
    } else {
      setState(() => _locked = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onFinish?.call();
      });
    }
  }

  void _check(int index) {
    if (_locked) return;
    
    setState(() {
      _locked = true;
      _selectedIndex = index;
    });
    
    if (index == _questions[_current].correctIndex) {
      _score++;
    }

    Future.delayed(const Duration(milliseconds: 1800), _nextQuestion);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gradientTimer?.cancel();
    _animationController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    final screenSize = MediaQuery.of(context).size;
    
    return AnimatedContainer(
      duration: const Duration(seconds: 5),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: gradientAlignment.isEmpty ? Alignment.topLeft : gradientAlignment[0],
          end: gradientAlignment.isEmpty ? Alignment.bottomRight : gradientAlignment[1],
          colors: currentGradient.isEmpty 
              ? [backgroundColor, Colors.black] // Correction: Remplacement de darken()
              : currentGradient,
          tileMode: TileMode.mirror,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: neonBlue.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: neonPink.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // En-tête avec effet verre - Correction: Animation déplacée sur le Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('QUIZ ULTIME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: neonBlue,
                          blurRadius: 10,
                        ),
                        Shadow(
                          color: neonPink,
                          blurRadius: 20,
                        ),
                      ],
                    )).animate().fadeIn().scaleXY(begin: 0.8, end: 1),
                    
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [neonBlue.withOpacity(0.7), neonPurple.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Text('SCORE: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                ).animate().scale(delay: 200.ms).shake(delay: 300.ms),
              ],
            ),
          ).animate().blurXY(begin: 10, end: 0), // Correction: Animation appliquée ici
          
          // Barre de progression avec effet lumineux
          Container(
            height: 8,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withOpacity(0.3),
                  blurRadius: 6,
                )
              ],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: 500.ms,
                  curve: Curves.linear,
                  width: screenSize.width * _timeLeft,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [neonGreen, neonBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ],
            ).animate().slideY(begin: -1, end: 0),
          ),
          
          // Compte à rebours avec animation
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('QUESTION ${_current + 1}/${_questions.length}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                    )).animate().fadeIn(),
                    
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: neonPink.withOpacity(0.5)),
                  ),
                  child: AnimatedCountdown(
                    timeLeft: _timeLeft,
                    neonPink: neonPink,
                  ),
                ),
              ],
            ),
          ),
          
          // Question avec effet de profondeur
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: neonBlue.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            )
            .animate(controller: _animationController)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut)
            .blurXY(begin: 5, end: 0),
          ),
          
          // Options avec effets modernes
          ...List.generate(q.options.length, (i) {
            final isCorrect = i == q.correctIndex;
            final isSelected = i == _selectedIndex;
            final showCorrect = _locked && isCorrect;
            final showWrong = _locked && isSelected && !isCorrect;
            
            return GestureDetector(
              onTap: () => _check(i),
              child: AnimatedContainer(
                duration: 600.ms,
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: showCorrect
                      ? neonGreen.withOpacity(0.2)
                      : showWrong
                          ? Colors.red.withOpacity(0.2)
                          : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: showCorrect
                        ? neonGreen
                        : showWrong
                            ? Colors.red
                            : neonBlue,
                    width: showCorrect || showWrong ? 2.5 : 1.2,
                  ),
                  boxShadow: showCorrect
                      ? [BoxShadow(color: neonGreen, blurRadius: 15, spreadRadius: 2)]
                      : showWrong
                          ? [BoxShadow(color: Colors.red, blurRadius: 15, spreadRadius: 2)]
                          : [BoxShadow(color: neonBlue.withOpacity(0.3), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    // Animation du cercle indicateur
                    AnimatedContainer(
                      duration: 300.ms,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: showCorrect
                            ? neonGreen
                            : showWrong
                                ? Colors.red
                                : Colors.transparent,
                        border: Border.all(
                          color: showCorrect
                              ? neonGreen
                              : showWrong
                                  ? Colors.red
                                  : neonBlue,
                          width: 2,
                        ),
                        boxShadow: showCorrect || showWrong
                            ? [BoxShadow(color: neonBlue, blurRadius: 10, spreadRadius: 2)]
                            : null,
                      ),
                      child: Center(
                        child: showCorrect
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                                .animate().scale(delay: 200.ms)
                            : showWrong
                                ? const Icon(Icons.close, size: 18, color: Colors.white)
                                    .animate().shake()
                                : Text(
                                    String.fromCharCode(65 + i),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        q.options[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: (i * 100).ms)
              .slideY(
                begin: 0.5,
                end: 0,
                duration: 500.ms,
                delay: (i * 100).ms,
                curve: Curves.easeOutBack,
              )
              .then()
              .shake(
                duration: showWrong ? 600.ms : 0.ms,
                offset: const Offset(8, 0),
              ),
            );
          }),
        ],
      ),
    )
    .animate()
    .scaleXY(
      begin: 0.95,
      end: 1,
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }
}

class AnimatedCountdown extends StatelessWidget {
  final double timeLeft;
  final Color neonPink;

  const AnimatedCountdown({
    super.key,
    required this.timeLeft,
    required this.neonPink,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '${(timeLeft * 15).ceil()}s',
      style: TextStyle(
        color: neonPink,
        fontFamily: 'Orbitron',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: neonPink.withOpacity(0.8),
            blurRadius: 10,
          ),
        ],
      ),
    )
    .animate(
      onPlay: (controller) => controller.repeat(),
    )
    .fadeOut(duration: 500.ms, curve: Curves.easeOut)
    .fadeIn(duration: 500.ms, curve: Curves.easeIn)
    .scaleXY(end: 1.2, duration: 250.ms)
    .then()
    .scaleXY(end: 1.0, duration: 250.ms);
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}