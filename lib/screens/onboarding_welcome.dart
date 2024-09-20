import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_sheet.dart';
import 'home.dart';

class Welcome extends StatefulWidget {
  final String photoURL;
  final String displayName;
  final String email;

  const Welcome({
    required this.photoURL,
    required this.displayName,
    required this.email,
    super.key,
  });

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller and animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Slide in from the right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Ensure the widget is mounted before starting the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the controller to free up resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: SlideTransition(
          position: _slideAnimation, // Use slide animation here
          child: _buildWelcomeContent(),
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }

  // AppBar with '+' action button
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Welcome',
        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.blue[700]),
    );
  }

  // Welcome content with user info and profile picture on the left
  Widget _buildWelcomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: (widget.photoURL.isNotEmpty)
                    ? NetworkImage(widget.photoURL)
                    : const AssetImage('assets/default_profile.png')
                        as ImageProvider,
                radius: 40,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.displayName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Get started with your workspace!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the Home screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // More content can be added here
        ],
      ),
    );
  }
}
