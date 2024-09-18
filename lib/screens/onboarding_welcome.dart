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

class _WelcomeState extends State<Welcome> {
  // List<Widget> screens
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Home(),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              backgroundImage: (widget.photoURL.isNotEmpty)
                  ? NetworkImage(widget.photoURL)
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
              radius: 25,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  // Action when + icon is tapped
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
