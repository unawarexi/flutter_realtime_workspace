import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // For page indicators

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/images/communicate.png',
      'text': 'Collaborate with your team in real-time',
    },
    {
      'image': 'assets/images/tasks.png',
      'text': 'Manage tasks efficiently with integrated tools',
    },
    {
      'image': 'assets/images/social.png',
      'text': 'Communicate seamlessly with team members',
    },
    {
      'image': 'assets/images/deadline.png',
      'text': 'Track your project timelines and deadlines',
    },
    {
      'image': 'assets/images/stats.png',
      'text': 'Achieve productivity with our workspace solutions',
    },
  ];

  @override
  void initState() {
    super.initState();
    autoSlider();
  }

  // Auto slider function to switch pages every 3 seconds
  void autoSlider() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentPage < onboardingData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      autoSlider();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PageView for onboarding content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) => OnboardingContent(
                  image: onboardingData[index]['image']!,
                  text: onboardingData[index]['text']!,
                ),
              ),
            ),
            // SmoothPageIndicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: SmoothPageIndicator(
                controller: _controller,
                count: onboardingData.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: Colors.blueAccent,
                  dotColor: Colors.grey[400]!,
                  dotHeight: 10,
                  dotWidth: 10,
                  expansionFactor: 4,
                  spacing: 10,
                ),
              ),
            ),
            // Skip and Next Buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage < onboardingData.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacementNamed(context, '/signup');
                      }
                    },
                    child: Text(
                      _currentPage == onboardingData.length - 1
                          ? 'Finish'
                          : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String image;
  final String text;

  const OnboardingContent({
    required this.image,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          image,
          height: 300,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
