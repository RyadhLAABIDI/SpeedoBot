import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/controllers/auth_controller.dart';
import 'package:speedobot/screens/screens_auth/login.dart';
import 'package:speedobot/screens/screens_home/chat_screen.dart';
import 'package:speedobot/controllers/TranslationController.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speedobot/screens/screens_home/RemoveBackgroundScreen.dart';

void main() => runApp(const MegabotApp());

class MegabotApp extends StatelessWidget {
  const MegabotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Megabot',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: 'Outfit',
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF02111a),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF3ECAA7),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF02111a),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF3ECAA7),
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF02111a),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final AuthController authController = Get.put(AuthController());
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _pages = [
    const HomeContent(),
    const MainScreen(),
    const RemoveBackgroundScreen(),
  ];

  static void _logout() async {
    await Get.find<AuthController>().logout();
    Get.offAll(() => const AuthScreen());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Get.until((route) => route.isFirst);
  }

  void _toggleTheme() {
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => SettingsPlaceholder(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex == 0) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        leading: IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: Color(0xFF3ECAA7),
            size: 24,
          ),
          onPressed: _navigateToSettings,
        ),
        title: Image.asset(
          'assets/images/logo.png',
          width: 120,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF3ECAA7)),
            onPressed: _logout,
          ),
        ],
      );
    }
    return null;
  }

  BottomNavigationBar _buildModernNavBar(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      items: [
        _buildAnimatedNavItem(0, Icons.home_outlined, Icons.home_rounded),
        _buildAnimatedNavItem(1, Icons.forum_outlined, Icons.forum_rounded),
        _buildAnimatedNavItem(2, Icons.video_call_outlined, Icons.video_call_rounded),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF3ECAA7),
      unselectedItemColor: Colors.grey.withOpacity(0.7),
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        _animationController.forward().then((_) => _animationController.reverse());
        _onItemTapped(index);
      },
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
    );
  }

  BottomNavigationBarItem _buildAnimatedNavItem(int index, IconData icon, IconData activeIcon) {
    return BottomNavigationBarItem(
      icon: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _selectedIndex == index ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                gradient: _selectedIndex == index 
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF3ECAA7).withOpacity(0.2),
                          const Color(0xFF3ECAA7).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedIndex == index ? activeIcon : icon,
                    size: _selectedIndex == index ? 28 : 24,
                  ),
                  if (_selectedIndex == index)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        height: 3,
                        width: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3ECAA7),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3ECAA7).withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      label: ['home'.tr, 'chat'.tr, 'remove_background'.tr][index],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildModernNavBar(context),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: const [
                  _HeaderSection(),
                  _ServicesGrid(),
                  _AboutSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatefulWidget {
  const _HeaderSection();

  @override
  __HeaderSectionState createState() => __HeaderSectionState();
}

class __HeaderSectionState extends State<_HeaderSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 20.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Image.asset('assets/images/robot.png'),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              'revolutionize_workflow'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3ECAA7),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              'leverage_technology'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildCtaButton(context),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _positionAnimation.value),
                  child: CustomPaint(
                    size: const Size(24, 60),
                    painter: _CompleteArrowPainter(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          SvgPicture.asset('assets/images/3.svg', height: 30),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.rocket_launch_rounded, size: 10),
      label: Text('start_free_trial'.tr),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        backgroundColor: const Color(0xFF3ECAA7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
        homeState?._onItemTapped(1);
      },
    );
  }
}

class _CompleteArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3ECAA7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final lineStart = Offset(size.width / 2, 0);
    final lineEnd = Offset(size.width / 2, size.height - 15);
    canvas.drawLine(lineStart, lineEnd, paint);

    final path = Path();
    path.moveTo(size.width / 2 - 8, size.height - 20);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 8, size.height - 20);
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    List<ServiceItem> serviceItems = [
      ServiceItem(
        icon: 'assets/images/search.svg',
        title: 'ai_specialist_title'.tr,
        description: 'ai_specialist_description'.tr,
      ),
      ServiceItem(
        icon: 'assets/images/graph.svg',
        title: 'marketing_pro_title'.tr,
        description: 'marketing_pro_description'.tr,
      ),
      ServiceItem(
        icon: 'assets/images/copy.svg',
        title: 'content_wizard_title'.tr,
        description: 'content_wizard_description'.tr,
      ),
      ServiceItem(
        icon: 'assets/images/text.svg',
        title: 'copywriting_title'.tr,
        description: 'copywriting_description'.tr,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: serviceItems.length,
        itemBuilder: (context, index) => _ServiceCard(
          icon: serviceItems[index].icon,
          title: serviceItems[index].title,
          description: serviceItems[index].description,
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 32),
              child: SvgPicture.asset(
                icon,
                color: const Color(0xFF3ECAA7),
                fit: BoxFit.scaleDown,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(
            'why_choose_speedobot'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF3ECAA7),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _FeatureTile(
                icon: Icons.auto_awesome_mosaic_rounded,
                title: 'multi_purpose_ai_title'.tr,
                subtitle: 'multi_purpose_ai_description'.tr,
              ),
              _FeatureTile(
                icon: Icons.security_rounded,
                title: 'secure_and_reliable_title'.tr,
                subtitle: 'secure_and_reliable_description'.tr,
              ),
              _FeatureTile(
                icon: Icons.update_rounded,
                title: 'continuous_updates_title'.tr,
                subtitle: 'continuous_updates_description'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0e17),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3ECAA7), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color(0xFF3ECAA7),
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? null : Colors.white,
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF02111a),
                    const Color(0xFF0a1824).withOpacity(0.9),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'settings'.tr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF41be8c),
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildThemeSection(context, isDarkMode),
                _buildSectionDescription(
                  context,
                  isDarkMode,
                  'customize_appearance'.tr,
                ),
                _buildSectionDivider(isDarkMode),
                
                const SizedBox(height: 30),
                
                _buildLanguageSection(context, isDarkMode),
                _buildSectionDescription(
                  context,
                  isDarkMode,
                  'choose_language'.tr,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, bool isDarkMode) {
    final themeController = Get.find<ThemeController>();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: isDarkMode 
          ? Colors.white.withOpacity(0.05)
          : Colors.grey[50]!.withOpacity(0.6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3ECAA7).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: const Color(0xFF3ECAA7),
              size: 22,
            ),
          ),
          title: Text(
            'theme'.tr,
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.9) 
                  : Colors.black.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            isDarkMode ? 'dark_mode_activated'.tr : 'light_mode_activated'.tr,
            style: TextStyle(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.6) 
                  : Colors.black.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          trailing: Transform.scale(
            scale: 1.2,
            child: Switch(
              activeColor: const Color(0xFF3ECAA7),
              activeTrackColor: const Color(0xFF3ECAA7).withOpacity(0.4),
              value: isDarkMode,
              onChanged: (value) {
                themeController.toggleTheme();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, bool isDarkMode) {
    final currentLanguage = Get.locale?.languageCode ?? 'fr';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: isDarkMode 
          ? Colors.white.withOpacity(0.05)
          : Colors.grey[50]!.withOpacity(0.6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3ECAA7).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.translate,
              color: const Color(0xFF3ECAA7),
              size: 22,
            ),
          ),
          title: Text(
            'Language'.tr,
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.9) 
                  : Colors.black.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _getLanguageName(currentLanguage),
            style: TextStyle(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.6) 
                  : Colors.black.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildLanguageOption('en', 'english'.tr, context),
                  _buildLanguageOption('fr', 'french'.tr, context),
                  _buildLanguageOption('ar', 'arabic'.tr, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDescription(BuildContext context, bool isDarkMode, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24),
      child: Text(
        text.tr,
        style: TextStyle(
          color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
          fontSize: 14,
          height: 1.4,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildSectionDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 30,
      endIndent: 30,
      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildLanguageOption(String code, String name, BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage('assets/flags/${code}_flag.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.9)
              : Colors.black.withOpacity(0.9),
          fontSize: 16,
        ),
      ),
      trailing: Get.locale?.languageCode == code
          ? Icon(
              Icons.check_circle,
              color: const Color(0xFF3ECAA7),
            )
          : null,
      onTap: () {
        final newLocale = Locale(code);
        Get.find<LanguageController>().changeLanguage(newLocale);
      },
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'english'.tr;
      case 'fr':
        return 'french'.tr;
      case 'ar':
        return 'arabic'.tr;
      default:
        return 'Français';
    }
  }
}

List<ServiceItem> serviceItems = [
  ServiceItem(
    icon: 'assets/images/search.svg',
    title: 'ai_specialist_title'.tr,
    description: 'ai_specialist_description'.tr,
  ),
  ServiceItem(
    icon: 'assets/images/graph.svg',
    title: 'marketing_pro_title'.tr,
    description: 'marketing_pro_description'.tr,
  ),
  ServiceItem(
    icon: 'assets/images/copy.svg',
    title: 'content_wizard_title'.tr,
    description: 'content_wizard_description'.tr,
  ),
  ServiceItem(
    icon: 'assets/images/text.svg',
    title: 'copywriting_title'.tr,
    description: 'copywriting_description'.tr,
  ),
];

class ServiceItem {
  final String icon;
  final String title;
  final String description;

  ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}