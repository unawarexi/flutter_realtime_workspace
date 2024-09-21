import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'onboarding_functions.dart';
import '../../../screens/onboarding_welcome.dart';

class PasswordAuthentication extends StatefulWidget {
  const PasswordAuthentication({super.key});

  @override
  State<PasswordAuthentication> createState() => _PasswordAuthenticationState();
}

class _PasswordAuthenticationState extends State<PasswordAuthentication>
    with Func {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Text(
          //   "Password Authentication",
          //   style: TextStyle(
          //     fontWeight: FontWeight.bold,
          //     fontSize: 16,
          //     color: Colors.black87,
          //   ),
          // ),
          const SizedBox(height: 1),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: "User email ID",
              hintStyle: TextStyle(color: Colors.grey[600]),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: "*******",
              hintStyle: TextStyle(color: Colors.grey[600]),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final UserCredential userCredential =
                      await signInWithEmailAndPassword(
                          emailController.text, passwordController.text);

                  if (context.mounted) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Welcome(
                                  displayName:
                                      userCredential.user!.displayName ?? "",
                                  photoURL: userCredential.user!.photoURL ?? "",
                                  email: userCredential.user!.email!,
                                )));
                  }
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'user-not-found') {
                    callCustomStatusAlert(
                        context, 'No user found for that email', false);
                  } else if (e.code == 'wrong-password') {
                    callCustomStatusAlert(context,
                        'Wrong password provided for that user', false);
                  }
                } catch (e) {
                  callCustomStatusAlert(context, e.toString(), false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 5,
              ),
              child: const Text(
                "Sign In",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
