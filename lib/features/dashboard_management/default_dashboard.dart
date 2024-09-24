import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DefaultDashboard extends StatelessWidget {
  final String option;
  final String title; // Add title as a class variable

  const DefaultDashboard(this.option,
      {super.key,
      required this.title}); // Constructor to accept 'option' and 'title'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE8E8),
      appBar: NeumorphicAppBar(
        title: title, // Use the 'title' passed to the constructor
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCarouselSlider(),
              const SizedBox(height: 20),
              _buildCard('Overview', Icons.dashboard, 'All Overview Data',
                  Colors.blue),
              const SizedBox(height: 20),
              _buildCard('Statistics', Icons.stacked_line_chart,
                  'Monthly Stats', Colors.green),
              const SizedBox(height: 20),
              _buildAnimatedCard(),
              const SizedBox(height: 20),
              _buildImageCard(),
              const SizedBox(height: 20),
              _buildPopupButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOut,
      ),
      items: [
        'https://via.placeholder.com/400x200?text=Slide+1',
        'https://via.placeholder.com/400x200?text=Slide+2',
        'https://via.placeholder.com/400x200?text=Slide+3',
      ].map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Neumorphic(
                  style: const NeumorphicStyle(
                    depth: 8,
                    intensity: 0.5,
                    color: Color(0xFFEBE8E8),
                  ),
                  child: const Center(
                    child: Text(
                      'Slide',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildCard(
      String title, IconData icon, String subtitle, Color iconColor) {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Color(0xFFEBE8E8),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 16)),
              ],
            ),
            Icon(icon, size: 40, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard() {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Color(0xFFEBE8E8),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: const [
            Text(
              'Animated Card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('This card has a smooth animation effect.'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Color(0xFFEBE8E8),
      ),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage(
                'https://via.placeholder.com/600x150?text=Image+Card'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Text(
            'Featured Image',
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return Neumorphic(
              style: const NeumorphicStyle(
                depth: 8,
                intensity: 0.5,
                color: Color(0xFFEBE8E8),
              ),
              child: AlertDialog(
                title: const Text('Popup Title'),
                content: const Text('This is a popup message.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Text('Show Popup'),
    );
  }
}

class NeumorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const NeumorphicAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Color(0xFFEBE8E8),
      ),
      child: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
