import 'package:flutter/material.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>
    with SingleTickerProviderStateMixin {
  bool _isDropdownOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String selectedCategory = 'My Open Issues';

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define the animation (0 means collapsed, 1 means expanded)
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // Dispose of the animation controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _animationController.forward(); // Expand dropdown
      } else {
        _animationController.reverse(); // Collapse dropdown
      }
    });
  }

  void _navigateToPage(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceholderScreen(
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        backgroundColor: Colors.blue.shade700,
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
            // Filters and Create buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, color: Colors.blue.shade700),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateIssueScreen()),
                    );
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // My Open Issues with dropdown
            Row(
              children: [
                const Icon(Icons.open_in_new, size: 24),
                const SizedBox(width: 8),
                Text(
                  selectedCategory,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isDropdownOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                  onPressed: _toggleDropdown,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // The animated dropdown
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0, // Align animation to the top
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownOption('Reported by Me'),
                  _buildDropdownOption('Viewed Recently'),
                  _buildDropdownOption('All Issues'),
                  _buildDropdownOption('Open Issues'),
                  _buildDropdownOption('Created Recently'),
                  _buildDropdownOption('Resolved Recently'),
                  _buildDropdownOption('Updated Recently'),
                  _buildDropdownOption('Done Issues'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Enlarged Animated Content (when dropdown is not open)
            if (!_isDropdownOpen) _buildAnimatedContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownOption(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
        _navigateToPage(title);
      },
      child: Padding(
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
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/space.png', // Add your placeholder image here
              fit: BoxFit.cover,
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 10),
            const Text(
              'No work assigned... Nice!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "When you're assigned new issues, they'll appear here",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateIssueScreen(),
                  ),
                );
              },
              child: const Text(
                'Create Issues',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
          ],
        ),
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

// Create Issue Screen
class CreateIssueScreen extends StatelessWidget {
  const CreateIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Issue'),
      ),
      body: const Center(
        child: Text('Create Issue Form Goes Here'),
      ),
    );
  }
}

// Placeholder Screen for categories with no data
class PlaceholderScreen extends StatelessWidget {
  final String category;
  const PlaceholderScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/data.png', // Add your placeholder image here
              fit: BoxFit.cover,
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 10),
            const Text(
              'No data found for this category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
