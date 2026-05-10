import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/onboarding_email_password.dart';
import 'package:flutter_realtime_workspace/app/components/common/auth_confirmation_screen.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class PasswordAuthentication extends StatefulWidget {
  const PasswordAuthentication({super.key});

  @override
  State<PasswordAuthentication> createState() => _PasswordAuthenticationState();
}

class _PasswordAuthenticationState extends State<PasswordAuthentication> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
        
    return Consumer(
      builder: (context, ref, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                TextFormField(
                  controller: emailController,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1E40AF),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                  validator: ValidationBuilder().email().required().build(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscureText,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1E40AF),
                        width: 1.2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: isDarkMode ? Colors.white54 : Colors.grey[600],
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                  validator: ValidationBuilder().minLength(6).required().build(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final UserCredential userCredential =
                              await signInWithEmailAndPassword(
                                  emailController.text, passwordController.text);

                          // Use navigateToHome to ensure userProvider and storage are set
                          await navigateToHome(context, userCredential.user!, ref);
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'user-not-found') {
                            await showAuthConfirmation(
                              context,
                              status: AuthConfirmationStatus.failure,
                              message: 'No user found for that email',
                              actionLabel: "Try Again",
                            );
                          } else if (e.code == 'wrong-password') {
                            await showAuthConfirmation(
                              context,
                              status: AuthConfirmationStatus.failure,
                              message: 'Wrong password provided for that user',
                              actionLabel: "Try Again",
                            );
                          }
                        } catch (e) {
                          await showAuthConfirmation(
                            context,
                            status: AuthConfirmationStatus.failure,
                            message: e.toString(),
                            actionLabel: "Try Again",
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
