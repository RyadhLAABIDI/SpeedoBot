import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:speedobot/controllers/auth_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;

  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController codeController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser l'email passé via le constructeur, sinon vérifier Get.arguments
    final String? email = widget.email ?? (Get.arguments is Map ? Get.arguments['email'] as String? : null);

    if (email == null || email.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Erreur : Email non fourni',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = Get.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0a0e17), const Color(0xFF0a0e17)]
                : [const Color(0xFFF1F1F1), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.2,
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'verify_email'.tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'enter_verification_code'.tr + ' $email',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    CustomTextField(
                      controller: codeController,
                      label: 'verification_code'.tr,
                      icon: Iconsax.code,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_enter_code'.tr;
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                          return 'invalid_code_format'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Obx(() {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF3ECAA7) : const Color(0xFF17c9ef),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _authController.isLoading
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  await _authController.verifyEmail(email, codeController.text);
                                }
                              },
                        child: _authController.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.tick_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'verify_now'.tr,
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
                    SizedBox(height: screenHeight * 0.03), // Ajouté pour l'espace en bas
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = Get.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0a0e17), const Color(0xFF0a0e17)]
                : [const Color(0xFFF1F1F1), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.2,
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'forgot_password'.tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'enter_email_reset'.tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    CustomTextField(
                      controller: emailController,
                      label: 'email_address'.tr,
                      icon: Iconsax.direct_right,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_enter_email'.tr;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'invalid_email'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Obx(() {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF3ECAA7) : const Color(0xFF17c9ef),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _authController.isLoading
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  await _authController.forgotPassword(emailController.text);
                                }
                              },
                        child: _authController.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.message, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'send_reset_code'.tr,
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
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'back_to_login'.tr,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: screenWidth * 0.04,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03), // Ajouté pour l'espace en bas
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyPasswordCodeScreen extends StatefulWidget {
  final String? email;

  const VerifyPasswordCodeScreen({super.key, this.email});

  @override
  State<VerifyPasswordCodeScreen> createState() => _VerifyPasswordCodeScreenState();
}

class _VerifyPasswordCodeScreenState extends State<VerifyPasswordCodeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController codeController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? email = widget.email ?? (Get.arguments is Map ? Get.arguments['email'] as String? : null);

    if (email == null || email.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Erreur : Email non fourni',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = Get.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0a0e17), const Color(0xFF0a0e17)]
                : [const Color(0xFFF1F1F1), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.2,
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'verify_reset_code'.tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'enter_reset_code'.tr + ' $email',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    CustomTextField(
                      controller: codeController,
                      label: 'verification_code'.tr,
                      icon: Iconsax.code,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_enter_code'.tr;
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                          return 'invalid_code_format'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Obx(() {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF3ECAA7) : const Color(0xFF17c9ef),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _authController.isLoading
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  await _authController.verifyPasswordCode(email, codeController.text);
                                }
                              },
                        child: _authController.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.tick_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'verify_now'.tr,
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
                    SizedBox(height: screenHeight * 0.03), // Ajouté pour l'espace en bas
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? code;

  const ResetPasswordScreen({super.key, this.email, this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? email = widget.email ?? (Get.arguments is Map ? Get.arguments['email'] as String? : null);
    final String? code = widget.code ?? (Get.arguments is Map ? Get.arguments['code'] as String? : null);

    if (email == null || email.isEmpty || code == null || code.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Erreur : Données manquantes',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = Get.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0a0e17), const Color(0xFF0a0e17)]
                : [const Color(0xFFF1F1F1), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.2,
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'reset_password'.tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'enter_new_password'.tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    CustomTextField(
                      controller: passwordController,
                      label: 'password'.tr,
                      icon: Iconsax.lock,
                      obscureText: true,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_enter_password'.tr;
                        }
                        if (value.length < 6) {
                          return 'password_too_short'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    CustomTextField(
                      controller: confirmPasswordController,
                      label: 'confirm_password'.tr,
                      icon: Iconsax.lock_1,
                      obscureText: true,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_confirm_password'.tr;
                        }
                        if (value != passwordController.text) {
                          return 'passwords_do_not_match'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Obx(() {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF3ECAA7) : const Color(0xFF17c9ef),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _authController.isLoading
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  await _authController.resetPassword(
                                    email,
                                    code,
                                    passwordController.text,
                                    confirmPasswordController.text,
                                  );
                                }
                              },
                        child: _authController.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.key, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'reset_now'.tr,
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
                    SizedBox(height: screenHeight * 0.03), // Ajouté pour l'espace en bas
                  ],
                ),
              ),
            ),
          ),
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

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    required this.controller,
    required this.isDarkMode,
    this.validator,
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