import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/2fa_screen.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/onboarding_divider.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_github.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_google.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_microsoft.dart';
import 'package:flutter_realtime_workspace/app/components/common/auth_confirmation_screen.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_realtime_workspace/core/utils/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_email_password.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/login.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/2fa_logic.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp>
    with SingleTickerProviderStateMixin {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late AnimationController _controller;
  late Animation<double> _animation;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Emblem Image at the Top (dark/light mode)
                AnimatedBuilder(
                  animation: _animation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 0.0),
                    child: Image.asset(
                      isDarkMode ? TImages.darkEmblem : TImages.lightEmblem,
                      height: 90,
                      width: 200,
                    ),
                  ),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value,
                      child: child,
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                  textAlign: TextAlign.left,
                ),

                // --- Branding/Description for Workspace TeamSpot ---
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // <-- align left
                  children: [
                    Text(
                      "Workspace TeamSpot",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Collaborate, manage projects, and connect with your team in one modern workspace.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                // --- End Branding/Description ---

                const SizedBox(height: 14),

                // Signup Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Input
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode 
                              ? const Color(0xFF1E293B).withOpacity(0.8)
                              : Colors.white,
                          hintText: "Enter email address",
                          hintStyle: TextStyle(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                            size: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        ),
                        validator: ValidationBuilder().email().required().build(),
                      ),

                      const SizedBox(height: 12),

                      // Password Input (styled like email, with eye icon)
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode 
                              ? const Color(0xFF1E293B).withOpacity(0.8)
                              : Colors.white,
                          hintText: "Enter password",
                          hintStyle: TextStyle(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                            size: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: isDarkMode ? Colors.white54 : Colors.grey[600],
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        ),
                        validator: ValidationBuilder().minLength(6).required().build(),
                      ),

                      const SizedBox(height: 12),

                      // Confirm Password Input (styled like email, with eye icon)
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode 
                              ? const Color(0xFF1E293B).withOpacity(0.8)
                              : Colors.white,
                          hintText: "Confirm password",
                          hintStyle: TextStyle(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                            size: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: isDarkMode ? Colors.white54 : Colors.grey[600],
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Sign Up Button (ensure text/icon visible)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              print("SignUp button pressed. Starting sign up...");
                              try {
                                final userCred = await signUpWithEmailAndPassword(
                                  emailController.text,
                                  passwordController.text,
                                );
                                print("User created: ${userCred.user?.uid}, Email: ${userCred.user?.email}");
                                // Generate and send 2FA code
                                // await TwoFALogic.generateAndSend2FACode(userCred.user!.uid);
                                print("2FA code generated and sent for UID: ${userCred.user!.uid}");
                                if (context.mounted) {
                                  print("Navigating to TwoFAScreen...");
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TwoFAScreen(),
                                    ),
                                  );
                                }
                              } on Exception catch (e) {
                                print("Sign up error: $e");
                                if (context.mounted) {
                                  await showAuthConfirmation(
                                    context,
                                    status: AuthConfirmationStatus.failure,
                                    message: e.toString(),
                                    actionLabel: "Try Again",
                                  );
                                }
                              }
                            } else {
                              print("Form validation failed.");
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: 18),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Authentication()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Divider with image inside the "OR"
                const CustomDivider(),

                const SizedBox(height: 12),

                // Social Sign-In Buttons in Row (Google, Microsoft, GitHub)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: GoogleAuthentication()),
                    SizedBox(width: 8),
                    Expanded(child: MicrosoftAuthentication()),
                    SizedBox(width: 8),
                    Expanded(child: GithubAuthentication()),
                  ],
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ]),
      ),
      )));
  }
}
