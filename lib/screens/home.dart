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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Welcome Text
              const Text(
                'Hello, User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Search Bar
              _buildSearchBar(),

              const SizedBox(height: 50),

              // Quick Access Section
              _buildQuickAccessSection(),

              const SizedBox(height: 10),

              // Personalized Space
              _buildPersonalizedSpace(screenWidth),

              const SizedBox(height: 50),

              // List Tiles for Sections
              _buildSectionListTile(
                  Icons.folder, 'Collaboration', 'Modified: 12 Sept 2024'),
              _buildSectionListTile(
                  Icons.folder, 'My Open Issues', 'Modified: 10 Sept 2024'),

              const SizedBox(height: 50),

              // Collaborator Tools Section
              Text(
                'Collaborator Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),

              // Collaboration Options
              _buildCollabOptions(context),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build the Search Bar with neomorphism
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // Function to build Quick Access Section
  Widget _buildQuickAccessSection() {
    return Row(
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
    );
  }

  // Function to build Personalized Space
  Widget _buildPersonalizedSpace(double screenWidth) {
    return Row(
      children: [
        // Placeholder Image (From Assets)
        Container(
          width: screenWidth * 0.4,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.5),
            //     spreadRadius: 5,
            //     blurRadius: 10,
            //     offset: const Offset(0, 5),
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/personalized.png', // Replace with your asset image path
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Personalized Text
        SizedBox(
          width: screenWidth * 0.4,
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
    );
  }

  // Function to build section list tiles
  Widget _buildSectionListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.more_vert),
    );
  }

  // Function to build Collaborator Tools Section
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
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 30), // Increased padding for a neater look
            backgroundColor: Colors.blue,
            elevation: 5, // Adds shadow for a modern feel
          ),
          child: const Text(
            'Chill Spots Nearby',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16, // Increased font size for better readability
              fontWeight: FontWeight.bold, // Bold text for emphasis
            ),
          ),
        ),
      ],
    );
  }

  // Function to build individual collab options with neomorphic effect
  Widget _buildCollabOption(
      BuildContext context, IconData icon, String label, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withOpacity(0.3),
        //     spreadRadius: 5,
        //     blurRadius: 15,
        //     offset: const Offset(0, 5),
        //   ),
        // ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
