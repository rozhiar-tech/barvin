import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/discounts_screen.dart';
import 'package:barvin/widgets/search_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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
  final List<Item> items;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    this.items = const [],
  });

  factory Category.fromJson(Map<String, dynamic> j) {
    // if the server embedded an "items" array, decode it
    final rawItems = j['items'] as List<dynamic>?;
    final parsedItems = rawItems
            ?.map((m) => Item.fromJson(m as Map<String, dynamic>))
            .toList() ??
        <Item>[];

    return Category(
      id: j['id'],
      nameEn: j['name_en'] ?? '',
      nameKu: j['name_ku'] ?? '',
      nameAr: j['name_ar'] ?? '',
      items: parsedItems, // ← shove it in here
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

/// Parse either a raw JSON list or a JSON object
/// with an array under one of the keys.
List<dynamic> parseSectionsPayload(String jsonStr) {
  print(jsonStr);
  final decoded = jsonDecode(jsonStr);
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    if (decoded['categories'] is List) return decoded['categories'];
    if (decoded['data'] is List) return decoded['data'];
    if (decoded['items'] is List) return decoded['items'];
  }
  throw Exception("Unexpected JSON format for sections:\n$jsonStr");
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
  double _cartTotal = 0;

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

// Normalize URLs just like you do elsewhere:
  String _formatImageUrl(String raw) {
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$host/$path';
  }

// Navigate into your SingleItem detail screen:
  void _openDeal(BuildContext ctx, Item it) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => SingleItem(
          id: it.id,
          icon: Icons.fastfood,
          name: it.localizedName(ctx),
          description: it.description,
          unitPrice: it.price,
          imageUrl: _formatImageUrl(it.imageUrl),
          discount: it.discount,
        ),
      ),
    ).then((_) => _loadCartCount());
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

    double total = 0;
    int qty = 0;

    for (var s in items) {
      final m = jsonDecode(s) as Map<String, dynamic>;

      // parse quantity whether it's an int or a string
      final rawQty = m['quantity'];
      final itemQty =
          rawQty is int ? rawQty : int.tryParse(rawQty.toString()) ?? 0;

      // parse unit price whether it's num or string
      final rawPrice = m['price'];
      final unitPrice = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice.toString()) ?? 0.0;

      qty += itemQty;
      total += itemQty * unitPrice;
    }

    setState(() {
      _cartCount = qty;
      _cartTotal = total;
    });
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
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$apiBase/categories/with-items'));
      print("response is ${res.body}");
      // offload the peeling‐and‐casting to the isolate:
      final rawList = await compute(parseSectionsPayload, res.body);
      final sections = rawList.map((entry) {
        final map = entry as Map<String, dynamic>;
        final cat = Category.fromJson(map);
        final items = (map['items'] as List)
            .cast<Map<String, dynamic>>()
            .map((j) => Item.fromJson(j))
            .toList();
        return _SectionData(cat, items);
      }).toList();
      setState(() {
        _sections = sections;
        _loading = false;
      });
    } catch (e, st) {
      print("❌ Failed loading sections: $e\n$st");
      setState(() {
        _sections = [];
        _loading = false;
      });
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(mediaUrl!)
                        : const AssetImage('assets/logo.png'),
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
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
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
                  padding: const EdgeInsets.all(8),
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    const SearchBar1(hint: 'Search items...'),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
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
                                    ? CachedNetworkImage(
                                        imageUrl: mediaUrl,
                                        placeholder: (_, __) => Center(
                                            child: CircularProgressIndicator()),
                                        errorWidget: (_, __, ___) =>
                                            Icon(Icons.error),
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
                                          child: VideoPlayer(
                                              _videoControllers[ad.id]!),
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
                      // Section title
                      Text(
                        s.tDeals,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ─── Single vs. Multiple ──────────────────────────────────────────────
                      if (_hotDeals.length == 1)
                        // Single large card
                        GestureDetector(
                          onTap: () => _openDeal(context, _hotDeals.first),
                          child: Container(
                            height: 200,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Background image
                                  CachedNetworkImage(
                                    imageUrl: _formatImageUrl(
                                        _hotDeals.first.imageUrl),
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.error, size: 40),
                                  ),

                                  // Gradient overlay at bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black54,
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Item name
                                          Text(
                                            _hotDeals.first
                                                .localizedName(context),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Price row
                                          Row(
                                            children: [
                                              Text(
                                                '${_hotDeals.first.price.toStringAsFixed(0)} IQD',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${(_hotDeals.first.price * (1 - _hotDeals.first.discount / 100)).toStringAsFixed(0)} IQD',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Discount badge
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4)
                                        ],
                                      ),
                                      child: Text(
                                        '-${_hotDeals.first.discount.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        // Original small-card carousel
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _hotDeals.length,
                            itemBuilder: (_, idx) {
                              final it = _hotDeals[idx];
                              return GestureDetector(
                                onTap: () => _openDeal(context, it),
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 4)
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${it.discount.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.redAccent.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${(it.discount * 0.8).round()}% OFF',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                      Text(
                                        it.localizedName(context),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 14, color: textColor),
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

                      const SizedBox(height: 16),
                      // “All Discounts” button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(primaryColor),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DiscountsScreen(),
                              ),
                            );
                          },
                          child: Text(s.allDiscount,
                              style: TextStyle(
                                color: Colors.white,
                              )),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
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
                                      title:
                                          sec.category.localizedName(context),
                                      items: sec
                                          .items, // ← pass the whole List<Item>
                                      host: apiBase.replaceAll('/api', ''),
                                    ),
                                  ));
                            },
                            child: Text(s.seeMore,
                                style: TextStyle(color: textColor)),
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
                                width: 150,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  boxShadow: [],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                                ? CachedNetworkImage(
                                                    imageUrl: imgUrl,
                                                    placeholder: (_, __) => Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                    errorWidget: (_, __, ___) =>
                                                        Icon(Icons.error),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: it.discount > 0
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${it.price.toStringAsFixed(0)} IQD',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 12,
                                                ),
                                                Text(
                                                  '${(it.price * (1 - it.discount / 100)).toStringAsFixed(0)} IQD',
                                                  style: const TextStyle(
                                                    fontSize: 12,
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Text(
                                        '${it.description}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
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
                ),
              ),
            ),
            if (_cartCount > 0)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BasketPage()),
                  );
                  _loadCartCount(); // refresh when you come back
                },
                child: Container(
                  color: primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_basket, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        '$_cartCount items • ${_cartTotal.toStringAsFixed(0)} IQD',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Text(
                        'View Basket',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
