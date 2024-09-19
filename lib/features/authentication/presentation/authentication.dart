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
          // Enables scrollability
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App name "Zidio Group2" at the top center
                Center(
                  child: Text(
                    "Zidio Group2",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                SizedBox(height: 40), // Add space for sleekness

                // Placeholder image before Sign In header
                Center(
                  child: Image.asset(
                    'assets/images/keys.png',
                    height: 100,
                    width: 100,
                  ),
                ),

                SizedBox(height: 20),

                // Sign In Header
                const Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Text("Sign in to join the team"),

                SizedBox(height: 30), // Spacing

                // Password Authentication
                const PasswordAuthentication(),

                SizedBox(height: 20), // Spacing

                // Divider with image inside the "OR"
                const CustomDivider(),
                Center(
                  child: Image.asset(
                    'assets/images/locks.png',
                    height: 100,
                    width: 100,
                  ),
                ),

                SizedBox(height: 20), // Spacing

                // Social Sign-In Buttons (Google, Facebook, GitHub)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Google Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                        backgroundColor: Colors.red,
                        shadowColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        // Handle Google Sign-In
                        const GoogleAuthentication();
                      },
                      icon: Icon(Icons.g_mobiledata, color: Colors.white),
                      label: Text(""),
                    ),

                    // Facebook Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        shadowColor: Colors.blueAccent,
                      ),
                      onPressed: () {
                        // Handle Facebook Sign-In
                        const FacebookAuthentication();
                      },
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: const Text(""),
                    ),

                    // GitHub Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.black,
                        shadowColor: Colors.black45,
                      ),
                      onPressed: () {
                        // Handle GitHub Sign-In
                        const GithubAuthentication();
                      },
                      icon: Icon(Icons.code, color: Colors.white),
                      label: Text(""),
                    ),
                  ],
                ),

                SizedBox(height: 30), // Spacing

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
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            offset: Offset(-3, -3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            offset: Offset(3, 3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Use Biometric",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.fingerprint,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30), // Spacing

                // "Have an account? Login" or "Don't have an account? Sign Up"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? "),
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
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20), // Spacing

                // Sign In Button (Full Width)
                // SizedBox(
                //   width: MediaQuery.of(context).size.width * 0.8,
                //   height: 50,
                //   child: ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.blueAccent,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(30),
                //       ),
                //     ),
                //     onPressed: () {
                //       // Handle Sign In
                //     },
                //     child: const Text(
                //       "Sign In",
                //       style: TextStyle(
                //         color: Colors.white,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
