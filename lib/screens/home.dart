import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/ads_screen.dart';
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
// If you use a different host in dev/emulator, change here.
const String apiOrigin = 'http://95.111.224.58:4000'; // ← no trailing slash
const String apiBase = '$apiOrigin/api';

Uri apiUrl(String path, [Map<String, dynamic>? query]) {
  final p = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$apiBase$p').replace(queryParameters: query);
}

/// Backend often returns paths like "/uploads/…"
String mediaUrlFrom(String rawPath) {
  final path = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
  return '$apiOrigin/$path';
}

double _parseNum(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  // Clean strings like "20%", " 15 ", etc.
  final cleaned = v.toString().trim().replaceAll(RegExp(r'[^0-9\.\-]'), '');
  return double.tryParse(cleaned) ?? 0.0;
}

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
  final String imageUrl; // 👈 NEW

  final List<Item> items;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    this.imageUrl = "", // 👈 NEW

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
      imageUrl: j['image_url'] ?? '', // 👈 NEW

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
  final String supplier_name;

  Item({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    required this.imageUrl,
    required this.price,
    required this.discount,
    required this.description,
    required this.supplier_name,
  });

  factory Item.fromJson(Map<String, dynamic> j) {
    final price = _parseNum(j['price']);
    // try common alternative keys too, just in case
    final discount = _parseNum(
        j['discount'] ?? j['discount_percent'] ?? j['discountPercentage']);

    final supplier =
        (j['supplierName'] ?? j['supplier_name'] ?? j['vendor'] ?? '')
            .toString();

    return Item(
      id: j['id'],
      nameEn: j['name_en'] ?? '',
      nameKu: j['name_ku'] ?? '',
      nameAr: j['name_ar'] ?? '',
      imageUrl: j['image_url'] ?? '',
      price: price,
      discount: discount,
      description: j['description']?.toString().trim() ?? '',
      supplier_name: supplier,
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
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

/// Parse either a raw JSON list or a JSON object
/// with an array under one of the keys.
List<dynamic> parseSectionsPayload(String jsonStr) {
  // print(jsonStr);
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

class _RowFeed {
  final ScrollController controller = ScrollController();
  final List<Item> items;
  bool fetching = false;
  bool hasMore = true;
  final Set<int> _seen = {};

  _RowFeed({List<Item>? initial})
      : items = List<Item>.from(initial ?? const []) {
    for (final it in items) _seen.add(it.id);
  }

  void addAllDedup(Iterable<Item> more) {
    for (final it in more) {
      if (_seen.add(it.id)) items.add(it);
    }
  }

  void dispose() => controller.dispose();
}

class HomeScreenState extends State<HomeScreen> {
  List<Ad> _ads = [];

  int _currentPage = 0;
  // final PageController _pageController = PageController();
  Timer? _carouselTimer;
  bool _loading = true;
  List<_SectionData> _sections = [];
  Map<int, VideoPlayerController> _videoControllers = {};
  int _cartCount = 0;
  double _cartTotal = 0;
  bool _gridMode = true; // ← NEW
  final Map<int, _RowFeed> _feeds = {}; // catId -> feed
  final int _rowPageSize = 15; // tweak as you like
  String? avatarUrl;
  // Track current qty per item id (driven from SharedPreferences)
  final Map<int, int> _itemQty = {};
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
    // print("supplier name ${it.supplier_name}");
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
          supplierName: it.supplier_name,
        ),
      ),
    ).then((_) => _loadCartCount());
  }

  void showTopNotice(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: primaryColor,
        elevation: 2,
        content: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        leading: const Icon(Icons.check_circle, color: Colors.white),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // auto-hide after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (messenger.mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGridPref(); // ← NEW
    _loadCartCount();
    _loadAds();
    _startCarousel();
    _loadSections();
    _loadUserAvatar();
    // get user avatar url from shared preferences
  }

  Future<void> reload() async {
    // choose what you want refreshed:
    await _loadCartCount();

    if (mounted) setState(() {});
  }

  Future<void> _loadGridPref() async {
    final p = await SharedPreferences.getInstance();
    // was: _gridMode = p.getBool('gridMode') ?? false;
    setState(() => _gridMode = p.getBool('gridMode') ?? true); // ← default true
  }

  Future<void> _saveGridPref(bool v) async {
    // ← NEW
    final p = await SharedPreferences.getInstance();
    await p.setBool('gridMode', v);
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
    final byId = <int, int>{};

    for (final s in items) {
      final m = jsonDecode(s) as Map<String, dynamic>;

      final idStr = m['id']?.toString() ?? '';
      final id = int.tryParse(idStr);
      final rawQty = m['quantity'];
      final itemQty =
          rawQty is int ? rawQty : int.tryParse(rawQty.toString()) ?? 0;

      final rawPrice = m['price'];
      final unitPrice = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice.toString()) ?? 0.0;

      if (id != null) byId[id] = itemQty;

      qty += itemQty;
      total += itemQty * unitPrice;
    }

    setState(() {
      _cartCount = qty;
      _cartTotal = total;
      _itemQty
        ..clear()
        ..addAll(byId);
    });
  }

  Future<void> _setItemQty(Item it, int newQty) async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList('cart') ?? [];
    final cart = cartList
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList(growable: true);

    final idStr = it.id.toString();
    int idx = cart.indexWhere((m) => m['id']?.toString() == idStr);

    if (newQty <= 0) {
      if (idx >= 0) cart.removeAt(idx);
    } else {
      final record = {
        'id': idStr,
        'name': it.nameEn.isNotEmpty
            ? it.nameEn
            : (it.nameKu.isNotEmpty ? it.nameKu : it.nameAr),
        'price': it.price.toString(),
        'discount': it.discount.toString(),
        'quantity': newQty.toString(),
        'imageUrl': it.imageUrl,
        'supplierName': it.supplier_name,
      };

      if (idx >= 0) {
        cart[idx] = record;
      } else {
        cart.add(record);
      }
    }

    final newCartList = cart.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList('cart', newCartList);

    // refresh badge, totals, and per-item map
    await _loadCartCount();
  }

  Future<void> _incrementItem(Item it) async {
    final q = _itemQty[it.id] ?? 0;
    await _setItemQty(it, q + 1);
  }

  Future<void> _decrementItem(Item it) async {
    final q = _itemQty[it.id] ?? 0;
    if (q <= 0) return;
    await _setItemQty(it, q - 1);
  }

  Future<void> _loadAds() async {
    try {
      final res = await http.get(apiUrl('/ads'));
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
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _currentPage = (_currentPage + 1) % (_ads.isNotEmpty ? _ads.length : 1);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchMoreForRow(int catId) async {
    final feed = _feeds[catId];
    if (feed == null || feed.fetching || !feed.hasMore) return;

    setState(() => feed.fetching = true); // optional: show spinner immediately

    final nextPage = (feed.items.length ~/ _rowPageSize) + 1;

    try {
      final uri = apiUrl('/items', {
        'categoryId': '$catId',
        'shown': 'true',
        'page': '$nextPage',
        'pageSize': '$_rowPageSize',
      });

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rows = body is List ? body : (body['rows'] ?? []);
        final total = (body is Map && body['count'] is num)
            ? (body['count'] as num).toInt()
            : null;

        final more =
            rows.cast<Map<String, dynamic>>().map(Item.fromJson).toList();

        setState(() {
          feed.addAllDedup(more);

          // if API returns a total, use it; else infer from page size
          if (total != null) {
            feed.hasMore = feed.items.length < total;
          } else {
            feed.hasMore = more.length == _rowPageSize;
          }

          // hard stop if the page came back empty
          if (more.isEmpty) {
            feed.hasMore = false;
          }
        });
      } else {
        setState(() => feed.hasMore = false);
      }
    } catch (_) {
      setState(() => feed.hasMore = false);
    } finally {
      setState(
          () => feed.fetching = false); // <-- ensure rebuild to hide spinner
    }
  }

  Future<void> _loadSections() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(apiUrl('/categories/with-items'));
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
      final Map<int, _RowFeed> feeds = {};
      for (final sec in sections) {
        feeds[sec.category.id] = _RowFeed(initial: sec.items);
      }

// attach "near end" listeners once
      for (final entry in feeds.entries) {
        final catId = entry.key;
        final feed = entry.value;
        feed.controller.addListener(() {
          if (!feed.hasMore || feed.fetching) return;
          final pos = feed.controller.position;
          if (pos.pixels >= pos.maxScrollExtent - 200) {
            _fetchMoreForRow(catId);
          }
        });
      }

      setState(() {
        _sections = sections;
        _feeds.clear();
        _feeds.addAll(feeds);
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
    super.dispose();
    _carouselTimer?.cancel();
    _pageController.dispose();
    for (final vc in _videoControllers.values) vc.dispose();
    for (final f in _feeds.values)
      f.dispose(); // ← add this    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    // common host for all media
    final host = apiBase.replaceAll('/api', '');
    final s = S.of(context);

    return Scaffold(
      backgroundColor: Color(0xffD3E4C4),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_carousel,
                          color: secondaryColor, size: 18),
                      Switch(
                        value: _gridMode,
                        onChanged: (v) {
                          setState(() => _gridMode = v);
                          _saveGridPref(v);
                        },
                        activeColor: secondaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Icon(Icons.grid_view,
                          color: secondaryColor, size: 18),
                    ],
                  ),
                  // const SizedBox(width: 8),
                  // 2) your original title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        height: 36,
                        child: const SearchBar1(hint: 'Search items...'),
                      ),
                    ),
                  ),
                  // Stack(
                  //   alignment: Alignment.topRight,
                  //   children: [
                  //     Container(
                  //       width: 45,
                  //       height: 45,
                  //       decoration: BoxDecoration(
                  //         border: Border.all(
                  //           color: Colors.green,
                  //         ),
                  //         color: Colors.white,
                  //         borderRadius: BorderRadius.circular(16),
                  //       ),
                  //       child: IconButton(
                  //         icon: const Icon(Icons.shopping_basket,
                  //             color: secondaryColor),
                  //         onPressed: () async {
                  //           await Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //                 builder: (_) => const BasketPage()),
                  //           );
                  //           _loadCartCount();
                  //         },
                  //       ),
                  //     ),
                  //     if (_cartCount > 0)
                  //       Positioned(
                  //         right: 0,
                  //         top: 0,
                  //         child: Container(
                  //           padding: const EdgeInsets.all(2),
                  //           decoration: BoxDecoration(
                  //             color: Colors.red,
                  //             borderRadius: BorderRadius.circular(10),
                  //           ),
                  //           constraints: const BoxConstraints(
                  //               minWidth: 16, minHeight: 16),
                  //           child: Text(
                  //             '$_cartCount',
                  //             style: const TextStyle(
                  //                 color: Colors.white, fontSize: 10),
                  //             textAlign: TextAlign.center,
                  //           ),
                  //         ),
                  //       ),
                  //   ],
                  // ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Color(0xffD3E4C4)),
                child: ListView(
                  padding: const EdgeInsets.all(3),
                  children: [
                    // ─── Ads Carousel ──────────────────────────────────────────────────────
// below the row of dots, before the deals section
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.collections),
                        label: const Text('See all ads'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdsScreen(
                                  initialAds:
                                      _ads), // pass what you already loaded
                            ),
                          );
                        },
                      ),
                    ),
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
                    const SizedBox(height: 2),

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

                    if (_gridMode) ...[
                      // CATEGORY GRID MODE (like the screenshot)
                      _buildCategoryGrid(host),
                      const SizedBox(height: 10),
                    ] else ...[
                      // ─── Dynamic Category Sections ────────────────────────────────────────
                      for (var sec in _sections) ...<Widget>[
                        Builder(
                          builder: (context) {
                            final feed = _feeds[sec.category.id]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                title: sec.category
                                                    .localizedName(context),
                                                items: sec
                                                    .items, // ← pass the whole List<Item>
                                                host: apiBase.replaceAll(
                                                    '/api', ''),
                                                categoryId: sec
                                                    .category.id, // ← add this
                                                onExit:
                                                    reload, // 👈 refresh Home when user goes back
                                              ),
                                            ));
                                      },
                                      child: Text(s.seeMore,
                                          style: TextStyle(color: textColor)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 240,
                                  child: ListView.builder(
                                    controller: feed
                                        .controller, // <-- attach controller

                                    scrollDirection: Axis.horizontal,
                                    itemCount: feed.items.length +
                                        (feed.fetching
                                            ? 1
                                            : 0), // <-- only when fetching

                                    itemBuilder: (_, idx) {
                                      if (idx >= feed.items.length) {
                                        return const SizedBox(
                                          width: 80,
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }

                                      final it = feed.items[idx];
                                      final rawPath =
                                          it.imageUrl.startsWith('/')
                                              ? it.imageUrl.substring(1)
                                              : it.imageUrl;
                                      final imgUrl = '$host/$rawPath';

                                      return InkWell(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SingleItem(
                                                id: it.id,
                                                icon: Icons.fastfood,
                                                name: it.localizedName(context),
                                                description: it.description,
                                                unitPrice: it.price,
                                                imageUrl: imgUrl,
                                                discount: it.discount,
                                                supplierName: it.supplier_name,
                                              ),
                                            ),
                                          );
                                          _loadCartCount();
                                          if (result is String &&
                                              result.isNotEmpty) {
                                            showTopNotice(context, result);
                                          }
                                        },
                                        child: Container(
                                          width: 150,
                                          margin:
                                              const EdgeInsets.only(right: 4),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            color: const Color(0xffFEFAE0),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Image + discount badge
                                              Stack(
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.all(
                                                      8,
                                                    ),
                                                    height: 110,
                                                    width: 110,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          const BorderRadius
                                                              .vertical(
                                                        top:
                                                            Radius.circular(16),
                                                        bottom:
                                                            Radius.circular(16),
                                                      ),
                                                      child: it.imageUrl
                                                              .isNotEmpty
                                                          ? CachedNetworkImage(
                                                              imageUrl: imgUrl,
                                                              placeholder: (_,
                                                                      __) =>
                                                                  const Center(
                                                                child: CircularProgressIndicator(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              errorWidget: (_,
                                                                      __,
                                                                      ___) =>
                                                                  const Icon(Icons
                                                                      .error),
                                                            )
                                                          : Container(
                                                              width: double
                                                                  .infinity,
                                                              color: Colors
                                                                  .grey[300],
                                                              child: const Icon(
                                                                  Icons
                                                                      .fastfood,
                                                                  size: 40,
                                                                  color: Colors
                                                                      .black54),
                                                            ),
                                                    ),
                                                  ),
                                                  if (it.discount > 0)
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.redAccent,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          '-${it.discount.toStringAsFixed(0)}%',
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              const SizedBox(height: 8),

                                              // Name
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                child: Text(
                                                  it.localizedName(context),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    // fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),

                                              const SizedBox(height: 2),

                                              // Price / Discounted price
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                child: it.discount > 0
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '${it.price.toStringAsFixed(0)} IQD',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 9,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Text(
                                                            '${(it.price * (1 - it.discount / 100)).toStringAsFixed(0)} IQD',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        '${it.price.toStringAsFixed(0)} IQD',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: textColor,
                                                        ),
                                                      ),
                                              ),

                                              const SizedBox(height: 6),

                                              // --- Qty controls (add / remove) ---  ✅ now inside the itemBuilder scope
                                              Builder(
                                                builder: (_) {
                                                  final q =
                                                      _itemQty[it.id] ?? 0;
                                                  return Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    height: 34,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFFE6E6E6)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        // - button
                                                        SizedBox(
                                                          width: 28,
                                                          height: 28,
                                                          child: IconButton(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            iconSize: 18,
                                                            onPressed: q > 0
                                                                ? () =>
                                                                    _decrementItem(
                                                                        it)
                                                                : null,
                                                            icon: const Icon(
                                                                Icons.remove),
                                                            color: Colors
                                                                .redAccent,
                                                            disabledColor:
                                                                Colors.grey,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          '$q',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        // + button
                                                        SizedBox(
                                                          width: 28,
                                                          height: 28,
                                                          child: IconButton(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            iconSize: 18,
                                                            onPressed: () =>
                                                                _incrementItem(
                                                                    it),
                                                            icon: const Icon(
                                                                Icons.add),
                                                            color: Color(
                                                                0xFF5D8A4E),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),

                                              const SizedBox(height: 4),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
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
                  color: Color(0xff5D8A4E),
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

  Widget _buildCategoryGrid(String host) {
    final cats = _sections;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // fewer per row → bigger cards
        final cross = constraints.maxWidth >= 420 ? 4 : 3;

        // compute a comfortable aspect ratio for a taller tile
        final totalSpacing = (cross - 1) * 12;
        final tileW = (constraints.maxWidth - totalSpacing) / cross;
        const tileH = 160; // 72 image + 10 gap + ~3 text lines
        final ratio = tileW / tileH;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio, // <- taller than before
          ),
          itemBuilder: (_, i) {
            final sec = cats[i];
            final String? cover = sec.category.imageUrl.isNotEmpty
                ? mediaUrlFrom(sec.category.imageUrl)
                : null;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeeMoreScreen(
                      title: sec.category.localizedName(context),
                      items: sec.items,
                      host: apiBase.replaceAll('/api', ''),
                      categoryId: sec.category.id,
                      onExit: reload, // 👈 refresh Home when user goes back
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffFEFAE0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // bigger image bubble
                    Container(
                      width: 87,
                      height: 87,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: cover != null
                            ? CachedNetworkImage(
                                imageUrl: cover,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.category, size: 28),
                              )
                            : const Icon(Icons.category, size: 28),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // allow longer names
                    Text(
                      sec.category.localizedName(context),
                      textAlign: TextAlign.center,
                      maxLines: 1, // was 2
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.25, // tighter line-height
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
