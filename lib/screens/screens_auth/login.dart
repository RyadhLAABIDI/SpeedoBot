import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                        tabController: _tabController,
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
  final bool isDarkMode;

  const LoginForm({super.key, required this.authController, required this.isDarkMode});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

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

  void _showErrorSnackBar(String errorMessage) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, color: Colors.red, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3).shimmer(
                duration: 1800.ms,
                color: Colors.red.withOpacity(0.3),
              ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: emailController,
              label: 'email_address'.tr,
              icon: Iconsax.direct_right,
              isDarkMode: widget.isDarkMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_email'.tr;
                }
                if (!RegExp(r'^[\w-\.]+@([\w.-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'invalid_email'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: passwordController,
              label: 'password'.tr,
              icon: Iconsax.lock,
              obscureText: _obscurePassword,
              isDarkMode: widget.isDarkMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_password'.tr;
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed('/forgot-password'),
                child: Text(
                  'forgot_password'.tr,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: screenWidth * 0.04,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
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
                        if (formKey.currentState!.validate()) {
                          try {
                            await widget.authController.login(
                              emailController.text,
                              passwordController.text,
                            );
                          } catch (e) {
                            String errorKey = 'server_unavailable';
                            String errorString = e.toString().toLowerCase();
                            if (errorString.contains('invalid credential') || errorString.contains('invalid_credentials'.tr)) {
                              errorKey = 'invalid_credentials'.tr;
                            }
                            _showErrorSnackBar(errorKey);
                          }
                        }
                      },
                child: widget.authController.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.login,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'login_now'.tr,
                            style: const TextStyle(
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
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  final AuthController authController;
  final bool isDarkMode;
  final TabController tabController;

  const SignupForm({
    super.key,
    required this.authController,
    required this.isDarkMode,
    required this.tabController,
  });

  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  final formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

  void _showErrorSnackBar(String errorMessage) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, color: Colors.red, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3).shimmer(
                duration: 1800.ms,
                color: Colors.red.withOpacity(0.3),
              ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: nameController,
              label: 'full_name'.tr,
              icon: Iconsax.profile_circle,
              isDarkMode: widget.isDarkMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_name'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: emailController,
              label: 'email_address'.tr,
              icon: Iconsax.direct_right,
              isDarkMode: widget.isDarkMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_email'.tr;
                }
                if (!RegExp(r'^[\w-\.]+@([\w.-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'invalid_email'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: passwordController,
              label: 'password'.tr,
              icon: Iconsax.lock,
              obscureText: _obscurePassword,
              isDarkMode: widget.isDarkMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_password'.tr;
                }
                if (value.length < 6) {
                  return 'password_too_short'.tr;
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: confirmPasswordController,
              label: 'confirm_password'.tr,
              icon: Iconsax.lock_1,
              obscureText: _obscureConfirmPassword,
              isDarkMode: widget.isDarkMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_confirm_password'.tr;
                }
                if (value != passwordController.text) {
                  return 'passwords_do_not_match'.tr;
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
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
                        if (formKey.currentState!.validate()) {
                          try {
                            await widget.authController.register(
                              nameController.text,
                              emailController.text,
                              passwordController.text,
                              confirmPasswordController.text,
                            );
                          } catch (e) {
                            String errorKey = 'server_unavailable';
                            String errorString = e.toString().toLowerCase();
                            if (errorString.contains('email already used') || errorString.contains('email_already_used')) {
                              errorKey = 'email_already_used';
                            }
                            _showErrorSnackBar(errorKey);
                          }
                        }
                      },
                child: widget.authController.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.user,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'create_account'.tr,
                            style: const TextStyle(
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
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final bool isDarkMode;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    required this.controller,
    required this.isDarkMode,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}