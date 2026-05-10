import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_microsoft.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/onboarding_divider.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_biometric.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_github.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_google.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/login_password_fields.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/signup_screen.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';



class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    // Set the status bar color based on the theme
    return Scaffold(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          
                Center(
                  child: Image.asset(
                    height: 90,
                    width: 150,
                    isDarkMode ?  TImages.darkEmblem : TImages.lightEmblem,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                // Sign In Header
                Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                  const SizedBox(height: 14),
                Text(
                  "Sign in to join the team",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                //----------------------------------- Password Authentication
                const PasswordAuthentication(),
                const SizedBox(height: 14),

                // Divider with image inside the "OR"
                const CustomDivider(),

                const SizedBox(height: 12),

                // Social Sign-In Buttons in Row (Google, Facebook, GitHub)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: GoogleAuthentication()),
                    SizedBox(width: 8),
                    Expanded(child: MicrosoftAuthentication()),
                    SizedBox(width: 8),
                    Expanded(child: GithubAuthentication()),
                  ],
                ),
                const SizedBox(height: 50),

                // Biometric Sign-In Button (no shadow, no rounded edges)
                const Center(
                  child: SizedBox(
                    width: 340,
                    child: BiometricAuthentication(
                      showSettings: false,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // "Don't have an account? Sign Up" Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUp()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: isDarkMode ? Colors.lightBlueAccent : Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
