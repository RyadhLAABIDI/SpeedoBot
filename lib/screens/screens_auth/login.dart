import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:speedobot/controllers/auth_controller.dart';
import 'package:speedobot/screens/screens_home/home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF0a0e17), Color(0xFF0a0e17)]
                : [Color(0xFFf1f1f1), Color(0xFFffffff)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: screenHeight * 0.2,
                  width: screenWidth * 0.3,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.0000001),
                Text(
                  'welcome_to_speedobot'.tr,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : Color.fromRGBO(0, 216, 255, 1),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.08,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF3ECAA7),
                  unselectedLabelColor: isDarkMode ? Colors.grey[300] : Colors.grey[500],
                  indicatorColor: const Color(0xFF3ECAA7),
                  tabs: [
                    Tab(text: 'login'.tr),
                    Tab(text: 'signup'.tr),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LoginForm(authController: _authController, isDarkMode: isDarkMode),
                      SignupForm(
                        authController: _authController,
                        isDarkMode: isDarkMode,
                        tabController: _tabController, // Passer le TabController
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class LoginForm extends StatefulWidget {
  final AuthController authController;
  final bool isDarkMode; // Ajouter la variable pour la couleur de thème
  const LoginForm({super.key, required this.authController, required this.isDarkMode});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: emailController,
            label: 'email_address'.tr,
            icon: Iconsax.direct_right,
            isDarkMode: widget.isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: passwordController,
            label: 'password'.tr,
            icon: Iconsax.lock,
            obscureText: true,
            isDarkMode: widget.isDarkMode,
          ),
          const SizedBox(height: 25),
          Obx(() {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDarkMode ? Color(0xFF3ECAA7) : Color(0xFF17c9ef),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: widget.authController.isLoading
                  ? null
                  : () async {
                      await widget.authController.login(
                          emailController.text, passwordController.text);
                      if (widget.authController.user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      }
                    },
              child: widget.authController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.login,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'login_now'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  final AuthController authController;
  final bool isDarkMode;
  final TabController tabController; // Ajouter le TabController comme paramètre

  const SignupForm({
    super.key,
    required this.authController,
    required this.isDarkMode,
    required this.tabController, // Ajouter au constructeur
  });

  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: nameController,
            label: 'full_name'.tr,
            icon: Iconsax.profile_circle,
            isDarkMode: widget.isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: emailController,
            label: 'email_address'.tr,
            icon: Iconsax.direct_right,
            isDarkMode: widget.isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: passwordController,
            label: 'password'.tr,
            icon: Iconsax.lock,
            obscureText: true,
            isDarkMode: widget.isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: confirmPasswordController,
            label: 'confirm_password'.tr,
            icon: Iconsax.lock_1,
            obscureText: true,
            isDarkMode: widget.isDarkMode,
          ),
          const SizedBox(height: 25),
          Obx(() {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDarkMode ? Color(0xFF3ECAA7) : Color(0xFF17c9ef),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: widget.authController.isLoading
                  ? null
                  : () async {
                      await widget.authController.register(
                        nameController.text,
                        emailController.text,
                        passwordController.text,
                        confirmPasswordController.text,
                      );
                      if (widget.authController.user != null) {
                        // Basculer vers l'onglet de connexion (index 0)
                        widget.tabController.animateTo(0);
                        // Afficher un message de succès
                        Get.snackbar(
                          'Succès',
                          'Inscription réussie ! Veuillez vous connecter.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    },
              child: widget.authController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.user,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'create_account'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final bool isDarkMode; // Ajouter la variable pour la couleur de thème

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
