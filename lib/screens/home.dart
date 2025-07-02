import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// your existing imports
import 'single_item.dart';
import 'seeMore.dart';

const Color primaryColor = Color(0xFF567765);
const String apiBase =
    'http://localhost:4000/api'; // adjust to your backend URL

// Simple models
class Category {
  final int id;
  final String name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'], name: j['name']);
}

class Item {
  final int id;
  final String name;
  final String imageUrl;
  final double price;

  Item({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory Item.fromJson(Map<String, dynamic> j) {
    // price comes back as a string from your API, e.g. "8.99"
    final rawPrice = j['price'];
    double price;
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice is String) {
      price = double.tryParse(rawPrice) ?? 0.0;
    } else {
      price = 0.0;
    }

    return Item(
      id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
      name: j['name'] as String,
      imageUrl: j['image_url'] as String? ?? '',
      price: price,
    );
  }
}

class _SectionData {
  final Category category;
  final List<Item> items;
  _SectionData(this.category, this.items);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _carouselImages = [
    'assets/ad.png',
    'assets/ad.png',
    'assets/ad.png',
  ];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _carouselTimer;

  bool _loading = true;
  List<_SectionData> _sections = [];

  @override
  void initState() {
    super.initState();
    _startCarousel();
    _loadSections();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _currentPage = (_currentPage + 1) % _carouselImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadSections() async {
    try {
      // 1. get categories
      final catRes = await http.get(Uri.parse('$apiBase/categories'));
      final List catsJson = jsonDecode(catRes.body);
      final cats = catsJson.map((j) => Category.fromJson(j)).toList();

      // 2. for each category, fetch items
      final List<_SectionData> secData = [];
      for (var cat in cats) {
        final itRes =
            await http.get(Uri.parse('$apiBase/items?categoryId=${cat.id}'));
        final List itemsJson = jsonDecode(itRes.body);
        final items = itemsJson.map((j) => Item.fromJson(j)).toList();
        secData.add(_SectionData(cat, items));
      }

      setState(() {
        _sections = secData;
        _loading = false;
      });
    } catch (e) {
      print('Failed loading sections: $e');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  onPressed: () {},
                ),
                const Text(
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

            // Carousel
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _carouselImages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _carouselImages[i],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselImages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 12 : 8,
                  height: _currentPage == i ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? primaryColor
                        : primaryColor.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic sections
            for (var sec in _sections) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sec.category.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeeMoreScreen(
                            title: sec.category.name,
                            items: sec.items
                                .map((it) => {
                                      'icon': Icons.fastfood,
                                      'name': it.name,
                                    })
                                .toList(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'See More',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sec.items.length,
                  itemBuilder: (_, idx) {
                    final it = sec.items[idx];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SingleItem(
                              icon: Icons.fastfood,
                              name: it.name,
                              description: 'Delicious ${it.name}',
                              unitPrice: it.price,
                            ),
                          ),
                        );
                      },
                      child: Container(
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
                            // if you have network images you can use Image.network
                            Icon(Icons.fastfood, size: 40, color: primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              it.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
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
