import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/services/google_geo_location.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        // Wrap the entire content inside SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Welcome Text
              const Text(
                'Hello, User', // Adjust to use dynamic data if needed
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Search Bar with fully rounded edges
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Quick Access Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Action for 'Add items' link
                    },
                    child: const Text(
                      'Add items',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Personalized Space with Image from Assets
              Row(
                children: [
                  // Placeholder Image (From Assets)
                  Container(
                    width: screenWidth * 0.4,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: Image.asset(
                      'assets/images/personalized.png', // Replace with your asset image path
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Personalized Text
                  Container(
                    width:
                        screenWidth * 0.4, // Adjust the width to fit properly
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalize this space',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Add your most important stuff here for fast access',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // List Tiles for Sections
              const ListTile(
                leading: Icon(Icons.folder, color: Colors.blue),
                title: Text('Collaboration'),
                subtitle: Text('Modified: 12 Sept 2024'),
                trailing: Icon(Icons.more_vert),
              ),
              const ListTile(
                leading: Icon(Icons.folder, color: Colors.blue),
                title: Text('My Open Issues'),
                subtitle: Text('Modified: 10 Sept 2024'),
                trailing: Icon(Icons.more_vert),
              ),

              const SizedBox(height: 50),

              // Collaborator Tools Section
              Text(
                'Collaborator Tools',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),

              // Build Collaboration Options
              _buildCollabOptions(context),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build Collab Section with clickable icons
  Widget _buildCollabOptions(BuildContext context) {
    return Column(
      children: [
        _buildCollabOption(
            context, Icons.translate, 'Translator', '/translator'),
        _buildCollabOption(context, Icons.chat, 'Chats', '/chats'),
        _buildCollabOption(
            context, Icons.settings, 'Preferences', '/preferences'),
        _buildCollabOption(context, Icons.call, 'Calls', '/calls'),
        _buildCollabOption(context, Icons.history, 'History', '/history'),
        _buildCollabOption(
            context, Icons.meeting_room, 'Meetings', '/meetings'),
        const SizedBox(height: 20),

        // Chill Spots Button
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GoogleMapScreen()),
            );
          },
          child: const Text('Chill Spots Nearby'),
        ),
      ],
    );
  }

  // Function to build individual collab options
  Widget _buildCollabOption(
      BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
