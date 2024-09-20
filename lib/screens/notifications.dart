import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with sliding tabs
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var tab in [
                            'Direct',
                            'Unread',
                            'Starred',
                            'Important',
                            'Filter'
                          ])
                            _buildTab(tab),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showMoreOptions(context);
                    },
                  ),
                ],
              ),
            ),
            // Centered image and text
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/design.png', // Replace with your placeholder image
                      width: 300,
                      height: 300,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Nothing's happened yet",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "When there's activity on your work, this is where we'll let you know. Pull down to refresh anytime...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnoozeOptions(context);
        },
        child: const Icon(Icons.notifications),
        backgroundColor: Colors.blue[400],
      ),
    );
  }

  Widget _buildTab(String title) {
    return GestureDetector(
      onTap: () {
        // Handle tab click logic
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark all as read'),
                onTap: () {
                  // Mark all as read logic
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Clear all',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  // Clear all notifications logic
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnoozeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Snooze Push Notifications',
                  style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              ...['20 mins', '1 hr', '4 hrs', '24 hrs', '2 days', '1 week']
                  .map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    // Snooze logic
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
