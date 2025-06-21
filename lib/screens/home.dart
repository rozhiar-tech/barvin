import 'dart:async';
import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF10B981);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentPage = 0;

  final List<String> _carouselImages = [
    'assets/ad.png',
    'assets/ad.png',
    'assets/ad.png',
  ];

  final List<Map<String, dynamic>> _sections = [
    {'title': 'Cheese', 'icon': Icons.emoji_food_beverage, 'items': 5},
    {'title': 'Finger Foods', 'icon': Icons.fastfood, 'items': 5},
    {'title': 'Oils', 'icon': Icons.local_drink, 'items': 5},
    {'title': 'Coffee & Tea', 'icon': Icons.local_cafe, 'items': 5},
    {'title': 'Rice & Sugar', 'icon': Icons.rice_bowl, 'items': 5},
    {'title': 'Canned Goods', 'icon': Icons.inbox, 'items': 5},
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentPage = (_currentPage + 1) % _carouselImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.person, size: 28),
                  onPressed: () {
                    // TODO: Navigate to profile
                  },
                ),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),

            // Carousel - auto scroll every 3 seconds
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _carouselImages.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      _carouselImages[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? primaryColor
                        : primaryColor.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sections
            for (final section in _sections) ...[
              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(section['icon'], color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        section['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to see more
                    },
                    child: Text(
                      'See More',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal item list
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: section['items'],
                  itemBuilder: (ctx, idx) {
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(section['icon'], size: 40, color: primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            '${section['title']} ${idx + 1}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
