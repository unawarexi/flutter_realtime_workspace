import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MilestonesDashboard extends StatelessWidget {
  const MilestonesDashboard({super.key, required String title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestones Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildCarousel(),
              const SizedBox(height: 20),
              _buildMilestonesList(),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Carousel for milestone highlights
  Widget _buildCarousel() {
    final List<String> images = [
      'assets/milestone1.png', // Replace with your asset paths
      'assets/milestone2.png',
      'assets/milestone3.png',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        height: 200,
        enlargeCenterPage: true,
      ),
      items: images.map((image) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }

  // List of milestones
  Widget _buildMilestonesList() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Upcoming Milestones",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
          ),
          ..._buildMilestoneCards(),
        ],
      ),
    );
  }

  // Individual milestone cards
  List<Widget> _buildMilestoneCards() {
    final List<Map<String, String>> milestones = [
      {"title": "Project Alpha Launch", "date": "2024-09-30"},
      {"title": "Beta Testing", "date": "2024-10-15"},
      {"title": "Final Release", "date": "2024-11-01"},
    ];

    return milestones.map((milestone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 4,
            intensity: 0.4,
            color: Colors.white,
          ),
          child: ListTile(
            title: Text(milestone['title']!),
            subtitle: Text(milestone['date']!),
            trailing: IconButton(
              icon: const Icon(Icons.info, color: Colors.blueAccent),
              onPressed: () {
                _showMilestoneDetails(milestone['title']!);
              },
            ),
          ),
        ),
      );
    }).toList();
  }

  // Action buttons at the bottom
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () {
            _showPopup(context, "New Milestone", "Create a new milestone");
          },
          child: const Text("Add Milestone"),
        ),
        ElevatedButton(
          onPressed: () {
            _showPopup(context, "Export", "Export milestones");
          },
          child: const Text("Export"),
        ),
      ],
    );
  }

  // Function to show milestone details
  void _showMilestoneDetails(String title) {
    // Show a popup or a dialog with details
    print("Details for $title");
  }

  // Function to show a custom popup
  void _showPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
