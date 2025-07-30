import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'basket.dart';
import 'single_item.dart';
import 'seeMore.dart';

const Color primaryColor = Color(0xFFbed6be);
const Color secondaryColor = Color(0xFF6D8474);
const Color textColor = Color(0xFF212121);
const String apiBase = 'http://95.111.224.58:4000/api';

class Ad {
  final int id;
  final String filePath;
  final String link;
  final String mediaType;
  Ad({
    required this.id,
    required this.filePath,
    required this.link,
    required this.mediaType,
  });
  factory Ad.fromJson(Map<String, dynamic> j) => Ad(
        id: j['id'],
        filePath: j['file_path'],
        link: j['link'],
        mediaType: j['media_type'],
      );
}

class Category {
  final int id;
  final String nameEn, nameKu, nameAr;
  Category({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
  });
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'],
        nameEn: j['name_en'] ?? '',
        nameKu: j['name_ku'] ?? '',
        nameAr: j['name_ar'] ?? '',
      );

  String localizedName(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    switch (code) {
      case 'ku':
        return nameKu.isNotEmpty ? nameKu : nameEn;
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      default:
        return nameEn;
    }
  }
}

class Item {
  final int id;
  final String nameEn, nameKu, nameAr;
  final String imageUrl;
  final double price, discount;
  final String description;

  Item(
      {required this.id,
      required this.nameEn,
      required this.nameKu,
      required this.nameAr,
      required this.imageUrl,
      required this.price,
      required this.discount,
      required this.description});

  factory Item.fromJson(Map<String, dynamic> j) {
    double price = (j['price'] is num)
        ? (j['price'] as num).toDouble()
        : double.tryParse(j['price'].toString()) ?? 0;
    double discount = (j['discount'] is num)
        ? (j['discount'] as num).toDouble()
        : double.tryParse(j['discount'].toString()) ?? 0;
    return Item(
      id: j['id'],
      nameEn: j['name_en'] ?? '',
      nameKu: j['name_ku'] ?? '',
      nameAr: j['name_ar'] ?? '',
      imageUrl: j['image_url'] ?? '',
      price: price,
      discount: discount,
      description: j['description']?.toString().trim() ?? '',
    );
  }

  String localizedName(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    switch (code) {
      case 'ku':
        return nameKu.isNotEmpty ? nameKu : nameEn;
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      default:
        return nameEn;
    }
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
  // final PageController _pageController = PageController();
  Timer? _carouselTimer;
  bool _loading = true;
  List<_SectionData> _sections = [];
  Map<int, VideoPlayerController> _videoControllers = {};
  int _cartCount = 0;
  String? avatarUrl;
  final host = apiBase.replaceAll('/api', '');
  final _pageController = PageController(viewportFraction: 0.92);
  // inside _HomeScreenState
  List<Item> get _hotDeals {
    return _sections
        .expand((sec) => sec.items)
        .where((it) => it.discount > 0)
        .toList();
  }

  String? get rawPath {
    if (avatarUrl == null) return null;
    return avatarUrl!.startsWith('/') ? avatarUrl!.substring(1) : avatarUrl!;
  }

  String? get mediaUrl {
    if (rawPath == null) return null;
    // Make sure 'host' is defined somewhere in your code.
    return '$host/$rawPath';
  }

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _loadAds();
    _startCarousel();
    _loadSections();
    _loadUserAvatar();
    // get user avatar url from shared preferences
  }

  Future<void> _loadUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    avatarUrl = prefs.getString('userAvatar');
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
          // normalize URL
          final host = apiBase.replaceAll('/api', '');
          final rawPath = ad.filePath.startsWith('/')
              ? ad.filePath.substring(1)
              : ad.filePath;
          final url = '$host/$rawPath';
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
      final decoded = jsonDecode(catRes.body);

      // 1) Debug print so you can see what keys the API actually returns:
      // print('🟢 categories payload: $decoded');

      // 2) Try a few spots for the array, then default to []:
      List<dynamic> catsJson;
      if (decoded is List) {
        catsJson = decoded;
      } else if (decoded['data'] is List) {
        catsJson = decoded['data'];
      } else if (decoded['categories'] is List) {
        catsJson = decoded['categories'];
      } else {
        catsJson = [];
      }

      final cats = catsJson.map((j) => Category.fromJson(j)).toList();
      final List<_SectionData> secData = [];

      for (var cat in cats) {
        final itRes =
            await http.get(Uri.parse('$apiBase/items?categoryId=${cat.id}'));
        final itDecoded = jsonDecode(itRes.body);

        // Debug print your items response too
        // print('🟢 items for category ${cat.id}: $itDecoded');

        List<dynamic> itemsJson;
        if (itDecoded is List) {
          itemsJson = itDecoded;
        } else if (itDecoded['data'] is List) {
          itemsJson = itDecoded['data'];
        } else if (itDecoded['items'] is List) {
          itemsJson = itDecoded['items'];
        } else {
          itemsJson = [];
        }

        final items = itemsJson.map((j) => Item.fromJson(j)).toList();
        secData.add(_SectionData(cat, items));
      }

      setState(() => _sections = secData);
    } catch (e, st) {
      print('❌ Failed loading sections: $e\n$st');
      setState(() => _sections = []);
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    for (var vc in _videoControllers.values) vc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    // common host for all media
    final host = apiBase.replaceAll('/api', '');
    final s = S.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          margin: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 213, 236, 221),
                Color(0xFFF1FAF5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(mediaUrl!)
                        : const AssetImage('assets/logo.jpeg'),
                    backgroundColor: Colors.grey[300],
                  ),
                  // const SizedBox(width: 8),
                  // 2) your original title
                  Text(
                    s.welcomeBack,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                          ),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_basket,
                              color: secondaryColor),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BasketPage()),
                            );
                            _loadCartCount();
                          },
                        ),
                      ),
                      if (_cartCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              '$_cartCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              // ─── Ads Carousel ──────────────────────────────────────────────────────

              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _ads.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final ad = _ads[i];
                    final rawPath = ad.filePath.startsWith('/')
                        ? ad.filePath.substring(1)
                        : ad.filePath;
                    final mediaUrl = '$host/$rawPath';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () async {
                          final url = ad.link;
                          final open = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Open Link?'),
                              content: Text('Go to: $url'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes')),
                              ],
                            ),
                          );
                          if (open == true &&
                              await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ad.mediaType == 'image'
                              ? Image.network(
                                  mediaUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover, // ← fills the entire card
                                )
                              : FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoControllers[ad.id]!
                                        .value
                                        .size
                                        .width,
                                    height: _videoControllers[ad.id]!
                                        .value
                                        .size
                                        .height,
                                    child:
                                        VideoPlayer(_videoControllers[ad.id]!),
                                  ),
                                ),
                        ),
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
                          : secondaryColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_hotDeals.isNotEmpty) ...[
                Text(
                  "Today's Deals",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _hotDeals.length,
                    itemBuilder: (_, idx) {
                      final it = _hotDeals[idx];
                      final rawPath = it.imageUrl.startsWith('/')
                          ? it.imageUrl.substring(1)
                          : it.imageUrl;
                      final imgUrl = '$host/$rawPath';
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SingleItem(
                                      id: it.id, // ← the real integer ID

                                      icon: Icons.fastfood,
                                      name: it.localizedName(context),
                                      description: it.description,
                                      unitPrice: it.price,
                                      imageUrl: imgUrl,
                                      discount: it.discount,
                                    )),
                          );
                          _loadCartCount(); // ← now we reload the badge *after* you pop back
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Big percentage
                              Text(
                                '${it.discount.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              // “xx OFF” pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(it.discount * 0.8).round()}% OFF',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.redAccent),
                                ),
                              ),
                              // Item name
                              Text(
                                it.localizedName(context),
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 14, color: textColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Dynamic Category Sections ────────────────────────────────────────
                for (var sec in _sections) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sec.category.localizedName(context),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeeMoreScreen(
                                  title: sec.category.localizedName(context),
                                  items:
                                      sec.items, // ← pass the whole List<Item>
                                  host: apiBase.replaceAll('/api', ''),
                                ),
                              ));
                        },
                        child:
                            Text(s.seeMore, style: TextStyle(color: textColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sec.items.length,
                      itemBuilder: (_, idx) {
                        final it = sec.items[idx];
                        final rawPath = it.imageUrl.startsWith('/')
                            ? it.imageUrl.substring(1)
                            : it.imageUrl;
                        final imgUrl = '$host/$rawPath';

                        return InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SingleItem(
                                        id: it.id, // ← the real integer ID

                                        icon: Icons.fastfood,
                                        name: it.localizedName(context),
                                        description: it.description,
                                        unitPrice: it.price,
                                        imageUrl: imgUrl,
                                        discount: it.discount,
                                      )),
                            );
                            _loadCartCount(); // ← now we reload the badge *after* you pop back
                          },
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1) Image + discount badge
                                Stack(
                                  children: [
                                    Container(
                                      height: 120,
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                        child: it.imageUrl.isNotEmpty
                                            ? Image.network(
                                                imgUrl,
                                                width: double.infinity,
                                                height: 80,
                                                fit: BoxFit.fitWidth,
                                              )
                                            : Container(
                                                width: double.infinity,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  size: 40,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (it.discount > 0)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '-${it.discount.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 2) Name
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    it.localizedName(context),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // 3) Price / Discounted price
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: it.discount > 0
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${it.price.toStringAsFixed(0)} IQD',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 12,
                                            ),
                                            Text(
                                              '${(it.price * (1 - it.discount / 100)).toStringAsFixed(0)} IQD',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '${it.price.toStringAsFixed(0)} IQD',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '${it.description}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
