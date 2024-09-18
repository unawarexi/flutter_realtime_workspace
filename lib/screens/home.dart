import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Hello, User', // Adjust to use dynamic data if needed
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 20),
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
          const Text(
            'Personalize this space',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: const Text('Collaboration'),
            subtitle: const Text('Modified: 12 Sept 2024'),
            trailing: const Icon(Icons.more_vert),
          ),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: const Text('My Open Issues'),
            subtitle: const Text('Modified: 10 Sept 2024'),
            trailing: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}
