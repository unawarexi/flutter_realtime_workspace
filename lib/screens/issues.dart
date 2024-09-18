import 'package:flutter/material.dart';
// import 'package:flutter_animated_icons/flutter_animated_icons.dart';
// import 'package:lottie/lottie.dart'; // For animated GIFs or icons

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  bool _isDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search logic
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.open_in_new, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'My Open Issues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isDropdownOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down),
                  onPressed: () {
                    setState(() {
                      _isDropdownOpen = !_isDropdownOpen;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isDropdownOpen) _buildDropdownContent(),
            if (!_isDropdownOpen) _buildAnimatedContent(),
            const SizedBox(height: 16),
            _buildCategorySection('Reported by Me'),
            _buildCategorySection('Viewed Recently'),
            _buildCategorySection('All Issues'),
            _buildCategorySection('Open Issues'),
            _buildCategorySection('Created Recently'),
            _buildCategorySection('Resolved Recently'),
            _buildCategorySection('Updated Recently'),
            _buildCategorySection('Done Issues'),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 16)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateIssueScreen()),
                );
              },
              child: const Text('Create',
                  style: TextStyle(fontSize: 16, color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Add more dropdown options here if needed
      ],
    );
  }

  Widget _buildAnimatedContent() {
    return Expanded(
      child: Center(
        child: Image.asset(
          'assets/lotties/projectGif.gif',
          fit: BoxFit.cover,
          width: 50,
          height: 50,
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_getCategoryIcon(title), size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: () {
              // Star category logic
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String title) {
    switch (title) {
      case 'Reported by Me':
        return Icons.person;
      case 'Viewed Recently':
        return Icons.visibility;
      case 'All Issues':
        return Icons.list;
      case 'Open Issues':
        return Icons.open_in_browser;
      case 'Created Recently':
        return Icons.add_box;
      case 'Resolved Recently':
        return Icons.check_circle;
      case 'Updated Recently':
        return Icons.update;
      case 'Done Issues':
        return Icons.done;
      default:
        return Icons.help;
    }
  }
}

class CreateIssueScreen extends StatelessWidget {
  const CreateIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Issue'),
      ),
      body: Center(
        child: const Text('Create Issue Form Goes Here'),
      ),
    );
  }
}
