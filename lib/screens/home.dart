import 'dart:async';
import 'dart:convert';
import 'package:barvin/screens/basket.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'single_item.dart';
import 'seeMore.dart';

const Color primaryColor = Color(0xFF567765);
const String apiBase = 'http://localhost:4000/api';

class Ad {
  final int id;
  final String filePath;
  final String link;
  final String mediaType;

  Ad(
      {required this.id,
      required this.filePath,
      required this.link,
      required this.mediaType});

  factory Ad.fromJson(Map<String, dynamic> j) => Ad(
        id: j['id'],
        filePath: j['file_path'],
        link: j['link'],
        mediaType: j['media_type'],
      );
}

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

  Item(
      {required this.id,
      required this.name,
      required this.imageUrl,
      required this.price});

  factory Item.fromJson(Map<String, dynamic> j) {
    final rawPrice = j['price'];
    double price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice) ?? 0.0;
    return Item(
      id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
      name: j['name'],
      imageUrl: j['image_url'] ?? '',
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
  List<Ad> _ads = [];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  bool _loading = true;
  List<_SectionData> _sections = [];
  Map<int, VideoPlayerController> _videoControllers = {};
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _loadAds();
    _startCarousel();
    _loadSections();
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('cart') ?? [];
    setState(() => _cartCount = items.length);
  }

  Future<void> _loadAds() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/ads'));
      final List list = jsonDecode(res.body);
      final ads = list.map((j) => Ad.fromJson(j)).toList();
      for (var ad in ads) {
        if (ad.mediaType == 'video') {
          final url = apiBase.replaceAll('/api', '') + ad.filePath;
          final vc = VideoPlayerController.network(url);
          await vc.initialize();
          _videoControllers[ad.id] = vc;
        }
      }
      setState(() {
        _ads = ads;
        _loading = false;
      });
    } catch (e) {
      print('Failed loading ads: $e');
      setState(() => _loading = false);
    }
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _currentPage = (_currentPage + 1) % (_ads.isNotEmpty ? _ads.length : 1);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadSections() async {
    try {
      final catRes = await http.get(Uri.parse('$apiBase/categories'));
      final List catsJson = jsonDecode(catRes.body);
      final cats = catsJson.map((j) => Category.fromJson(j)).toList();
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
      });
    } catch (e) {
      print('Failed loading sections: $e');
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    for (var vc in _videoControllers.values) {
      vc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.grey[100],
          title: const Text('Welcome Back'),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_basket),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BasketPage()),
                    );
                    _loadCartCount();
                  },
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _ads.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final ad = _ads[i];
                  return GestureDetector(
                    onTap: () async {
                      final url = ad.link;
                      final open = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Open Link?'),
                          content: Text('Go to: $url'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes')),
                          ],
                        ),
                      );
                      if (open == true && await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ad.mediaType == 'image'
                          ? Image.network(
                              apiBase.replaceAll('/api', '') + ad.filePath,
                              fit: BoxFit.cover,
                            )
                          : VideoPlayer(_videoControllers[ad.id]!),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _ads.length,
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
            for (var sec in _sections) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sec.category.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeeMoreScreen(
                            title: sec.category.name,
                            items: sec.items
                                .map((it) =>
                                    {'icon': Icons.fastfood, 'name': it.name})
                                .toList(),
                          ),
                        ),
                      );
                    },
                    child:
                        Text('See More', style: TextStyle(color: primaryColor)),
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
                      onTap: () async {
                        // add to cart
                        final prefs = await SharedPreferences.getInstance();
                        final cart = prefs.getStringList('cart') ?? [];
                        cart.add(jsonEncode(
                            {'id': it.id, 'name': it.name, 'price': it.price}));
                        await prefs.setStringList('cart', cart);
                        _loadCartCount();
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
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fastfood, size: 40, color: primaryColor),
                            const SizedBox(height: 8),
                            Text(it.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14)),
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
