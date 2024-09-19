import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/features/authentication/data/onboarding_functions.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp>
    with SingleTickerProviderStateMixin, Func {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize TextEditingControllers
    emailController = TextEditingController();
    passwordController = TextEditingController();

    // Initialize AnimationController for the wobble effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Duration of each wobble
    )..repeat(reverse: true); // Repeat the animation, reversing direction

    // Define a Tween to shake the image slightly (between -0.03 to 0.03 radians)
    _animation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed
    emailController.dispose();
    passwordController.dispose();
    _controller
        .dispose(); // Ensure controller is disposed to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Sign Up",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Wobbly Image at the Top
              AnimatedBuilder(
                animation: _animation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Image.asset(
                    'assets/images/user.png',
                    height: 100, // Adjust height as needed
                  ),
                ),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value, // Apply the wobble effect
                    child: child,
                  );
                },
              ),

              // Title
              const Text(
                "Create Your Account",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87),
              ),

              const SizedBox(height: 20),

              // Email Input
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: "Enter email address",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password Input
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: "Enter password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Sign Up Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await signUpWithEmailAndPassword(
                          emailController.text, passwordController.text);
                      if (context.mounted) {
                        callCustomStatusAlert(context,
                            "Now sign in with your new credentials", true);
                      }
                    } on FirebaseException catch (e) {
                      if (e.code == 'weak-password') {
                        callCustomStatusAlert(context,
                            'The password provided is too weak', false);
                      } else if (e.code == 'email-already-in-use') {
                        callCustomStatusAlert(context,
                            'The account already exists for that email', false);
                      }
                    } catch (e) {
                      callCustomStatusAlert(context, e.toString(), false);
                    }
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Static Image at the Bottom
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Image.asset(
                  'assets/images/signup.png',
                  height: 300, // Adjust size if needed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
