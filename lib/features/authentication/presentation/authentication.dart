import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_divider.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_facebook.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_functions.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_github.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_google.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_password.dart';
import 'package:flutter_realtime_workspace/features/authentication/presentation/signup_screen.dart';
import 'package:flutter_realtime_workspace/screens/onboarding_welcome.dart';

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> with Func {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App name "Zidio Group2" at the top center
                const Center(
                  child: Text(
                    "Zidio Group2",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Placeholder image before Sign In header
                Center(
                  child: Image.asset(
                    'assets/images/keys.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),

                // Sign In Header
                const Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "Sign in to join the team",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                // Password Authentication
                const PasswordAuthentication(),
                const SizedBox(height: 20),

                // Divider with image inside the "OR"
                const CustomDivider(),
                Center(
                  child: Image.asset(
                    'assets/images/locks.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                // Social Sign-In Buttons in Column (Google, Facebook, GitHub)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(const GoogleAuthentication(), 'Google'),
                    const SizedBox(height: 15),
                    _socialButton(const FacebookAuthentication(), 'Facebook'),
                    const SizedBox(height: 15),
                    _socialButton(const GithubAuthentication(), 'GitHub'),
                  ],
                ),
                const SizedBox(height: 15),

                const CustomDivider(),

                const SizedBox(height: 15),

                // Biometric Sign-In Button with Neo-morphism effect
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      bool success = await signInWithBiometrics(context);
                      if (success) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Welcome(
                                displayName: "",
                                photoURL: "",
                                email: "",
                              ),
                            ),
                          );
                        } else {
                          callCustomStatusAlert(context,
                              "Failed to authenticate with Biometrics", false);
                        }
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            offset: const Offset(-3, -3),
                            blurRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.grey.shade400,
                            offset: const Offset(3, 3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Use Biometric",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.fingerprint,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // "Don't have an account? Sign Up" Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
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
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for social sign-in buttons
  Widget _socialButton(Widget authWidget, String label) {
    return Container(
      height: 55,
      width: double.infinity, // Full-width buttons for better alignment
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.shade300,
        //     offset: Offset(2, 2),
        //     blurRadius: 5,
        //   ),
        // ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: authWidget,
        ),
      ),
    );
  }
}
