import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:carousel_slider/carousel_slider.dart';

class StarredDashboard extends StatelessWidget {
  const StarredDashboard({super.key, required String title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE8E8),
      appBar: const NeumorphicAppBar(
        title: 'Starred Dashboard',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCarouselSlider(),
              const SizedBox(height: 20),
              _buildCard('Starred Items', Icons.star, '5 Items', Colors.yellow),
              const SizedBox(height: 20),
              _buildCard('Recent Activity', Icons.history, '5 Activities',
                  Colors.blue),
              const SizedBox(height: 20),
              _buildCard(
                  'Favorites', Icons.favorite, '10 Favorites', Colors.red),
              const SizedBox(height: 20),
              _buildImageCard(),
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
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
                backgroundColor: Colors.black54),
          ),
        ),
      ),
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
