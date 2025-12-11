// ignore_for_file: unused_field, unused_element

import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/ads_screen.dart';
import 'package:barvin/screens/discounts_screen.dart';
import 'package:barvin/screens/food_basket_screen.dart';
import 'package:barvin/screens/handworks_screen.dart';
import 'package:barvin/widgets/search_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/services/api_config.dart';
import 'package:barvin/models/collections.dart';
import 'package:barvin/models/ad.dart';
import 'package:barvin/models/category.dart';
import 'package:barvin/models/item.dart';
import 'package:barvin/models/discount.dart';

import 'basket.dart';
import 'seeMore.dart';
import 'single_item.dart';

export 'package:barvin/services/api_config.dart';
export 'package:barvin/models/ad.dart';
export 'package:barvin/models/category.dart';
export 'package:barvin/models/item.dart';
export 'package:barvin/models/discount.dart';
export 'package:barvin/constants/app_constants.dart'
    show AppColors, AppSizes, AppEndpoints;

// Legacy exports for backward compatibility
import 'package:barvin/constants/app_constants.dart' show AppColors;

const Color primaryColor = AppColors.primaryLight;
const Color secondaryColor = AppColors.secondary;
const Color textColor = AppColors.textPrimary;

class _CachedResult {
  final String? body;
  final bool fromCache;
  final DateTime? ts;
  final String? error;

  const _CachedResult({
    this.body,
    this.fromCache = false,
    this.ts,
    this.error,
  });

  bool get hasData => (body != null && body!.isNotEmpty);
}

class _Cache {
  static Future<void> _save(String key, String body) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('${key}_data', body);
    await p.setInt('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<_CachedResult> _read(String key, {String? error}) async {
    final p = await SharedPreferences.getInstance();
    final data = p.getString('${key}_data');
    final tsMs = p.getInt('${key}_ts');
    final ts = tsMs == null ? null : DateTime.fromMillisecondsSinceEpoch(tsMs);
    return _CachedResult(body: data, fromCache: true, ts: ts, error: error);
  }

  /// Try network; on success, cache; on failure, load cache.
  static Future<_CachedResult> fetch(
    String cacheKey,
    Future<http.Response> Function() request,
  ) async {
    try {
      final res = await request();
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        await _save(cacheKey, res.body);
        return _CachedResult(body: res.body, fromCache: false);
      }
      // HTTP error -> fall back
      return _read(cacheKey, error: 'HTTP ${res.statusCode}');
    } catch (e) {
      // Network error -> fall back
      return _read(cacheKey, error: e.toString());
    }
  }
}

class _SectionData {
  final Category category;
  final List<Item> items;
  _SectionData(this.category, this.items);
}

class _HandworkThumb {
  final int id;
  final int handworkId;
  final String imageUrl;
  final DateTime? createdAt;

  _HandworkThumb({
    required this.id,
    required this.handworkId,
    required this.imageUrl,
    this.createdAt,
  });

  factory _HandworkThumb.fromJson(Map<String, dynamic> j) {
    DateTime? ts;
    final rawTs = j['created_at'] ?? j['createdAt'];
    if (rawTs != null) ts = DateTime.tryParse(rawTs.toString());
    return _HandworkThumb(
      id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
      handworkId: int.tryParse(j['handwork_id']?.toString() ?? '') ?? 0,
      imageUrl: (j['image_url'] ?? '').toString(),
      createdAt: ts,
    );
  }
}

class _LayoutBlock {
  // Deprecated: kept only to avoid breaking older cached code paths.
  final String type;
  final bool visible;
  final int order;
  final String slot;
  _LayoutBlock({
    required this.type,
    required this.visible,
    required this.order,
    // ignore: unused_element_parameter
    this.slot = "",
  });
}

class _LayoutSection {
  final String type;
  final String slot;
  final List<int> featuredSetIds;
  final List<int> adIds;
  final String? title;
  final String? description;

  const _LayoutSection({
    required this.type,
    this.slot = '',
    this.featuredSetIds = const [],
    this.adIds = const [],
    this.title,
    this.description,
  });

  String get typeLower => type.toLowerCase();
}

class _FeaturedSet {
  final int id;
  final String title;
  final String slot;
  final List<int> categoryIds;
  _FeaturedSet({
    required this.id,
    required this.title,
    required this.slot,
    required this.categoryIds,
  });
}

/// New Featured Category model from /api/featured-categories/with-items
class _FeaturedCategory {
  final int id;
  final String nameEn;
  final String nameKu;
  final String nameAr;
  final String? description;
  final String? imageUrl;
  final String layoutType; // 'banner', 'grid_2', 'grid_4'
  final int displayOrder;
  final bool isActive;
  final List<_FeaturedSubcategory> subcategories;
  final List<_FeaturedCategoryItem> categoryItems;

  _FeaturedCategory({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    this.description,
    this.imageUrl,
    required this.layoutType,
    required this.displayOrder,
    required this.isActive,
    required this.subcategories,
    required this.categoryItems,
  });

  factory _FeaturedCategory.fromJson(Map<String, dynamic> j) {
    final subsRaw = j['subcategories'] as List? ?? [];
    final itemsRaw = j['categoryItems'] as List? ?? [];
    return _FeaturedCategory(
      id: j['id'] ?? 0,
      nameEn: (j['name_en'] ?? '').toString(),
      nameKu: (j['name_ku'] ?? '').toString(),
      nameAr: (j['name_ar'] ?? '').toString(),
      description: j['description']?.toString(),
      imageUrl: j['image_url']?.toString(),
      layoutType: (j['layout_type'] ?? 'banner').toString(),
      displayOrder: j['display_order'] ?? 0,
      isActive: j['is_active'] == true,
      subcategories: subsRaw
          .whereType<Map<String, dynamic>>()
          .map(_FeaturedSubcategory.fromJson)
          .toList(),
      categoryItems: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(_FeaturedCategoryItem.fromJson)
          .toList(),
    );
  }

  String localizedName(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'ku':
        return nameKu.isNotEmpty ? nameKu : nameEn;
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      default:
        return nameEn;
    }
  }

  /// Get all items from both direct items and subcategory items
  List<Item> getAllItems() {
    final items = <Item>[];
    for (final ci in categoryItems) {
      if (ci.item != null) items.add(ci.item!);
    }
    for (final sub in subcategories) {
      for (final si in sub.subcategoryItems) {
        if (si.item != null) items.add(si.item!);
      }
    }
    return items;
  }
}

class _FeaturedSubcategory {
  final int id;
  final String nameEn;
  final String nameKu;
  final String nameAr;
  final int displayOrder;
  final bool isActive;
  final List<_FeaturedCategoryItem> subcategoryItems;

  _FeaturedSubcategory({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    required this.displayOrder,
    required this.isActive,
    required this.subcategoryItems,
  });

  factory _FeaturedSubcategory.fromJson(Map<String, dynamic> j) {
    final itemsRaw = j['subcategoryItems'] as List? ?? [];
    return _FeaturedSubcategory(
      id: j['id'] ?? 0,
      nameEn: (j['name_en'] ?? '').toString(),
      nameKu: (j['name_ku'] ?? '').toString(),
      nameAr: (j['name_ar'] ?? '').toString(),
      displayOrder: j['display_order'] ?? 0,
      isActive: j['is_active'] == true,
      subcategoryItems: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(_FeaturedCategoryItem.fromJson)
          .toList(),
    );
  }

  String localizedName(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
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

class _FeaturedCategoryItem {
  final int id;
  final int itemId;
  final int displayOrder;
  final Item? item;

  _FeaturedCategoryItem({
    required this.id,
    required this.itemId,
    required this.displayOrder,
    this.item,
  });

  factory _FeaturedCategoryItem.fromJson(Map<String, dynamic> j) {
    final itemRaw = j['item'];
    return _FeaturedCategoryItem(
      id: j['id'] ?? 0,
      itemId: j['item_id'] ?? 0,
      displayOrder: j['display_order'] ?? 0,
      item: itemRaw is Map<String, dynamic> ? Item.fromJson(itemRaw) : null,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

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
  bool _usingCachedData = false;
  String? _backendIssue;
  DateTime? _cacheTimestamp;

  String _describeSections(List<_LayoutSection> sections) {
    return sections.map((s) {
      final extras = <String>[];
      if (s.slot.isNotEmpty) extras.add('slot:${s.slot}');
      if (s.featuredSetIds.isNotEmpty) {
        extras.add('sets:${s.featuredSetIds.length}');
      }
      if (s.adIds.isNotEmpty) extras.add('ads:${s.adIds.length}');
      final extra = extras.isEmpty ? '' : '(${extras.join('/')})';
      return '${s.type}$extra';
    }).join(', ');
  }

  void _logLayout(String message, {List<_LayoutSection>? sections}) {
    final list = sections ?? _effectiveSections;
    debugPrint('[HOME_LAYOUT] $message -> ${_describeSections(list)}');
  }

// convenience
  void _markFallback(_CachedResult r) {
    if (r.fromCache) {
      setState(() {
        _usingCachedData = true;
        _backendIssue = r.error ?? 'Server unreachable';
        _cacheTimestamp = r.ts;
      });
    } else {
      // fresh data came in
      setState(() {
        _usingCachedData = false;
        _backendIssue = null;
        _cacheTimestamp = null;
      });
    }
  }

  int _currentDealPage = 0;
  final PageController _dealsPageController =
      PageController(viewportFraction: 0.92);
  Timer? _dealsTimer;

  void _startDealsCarousel() {
    _dealsTimer?.cancel();
    if (_activeDiscounts.length <= 1) return; // no auto-scroll for single
    _dealsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _activeDiscounts.isEmpty) return;
      _currentDealPage = (_currentDealPage + 1) % _activeDiscounts.length;
      _dealsPageController.animateToPage(
        _currentDealPage,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  List<Discount> _discounts = [];

  List<Discount> get _activeDiscounts =>
      _discounts.where((d) => d.isLive).toList(growable: false);

  List<Ad> _ads = [];
  List<_LayoutSection> _layoutSections = [];
  List<_FeaturedSet> _featuredSets = [];
  List<_FeaturedCategory> _newFeaturedCategories = [];
  bool _featuredCategoriesLoading = false;

  List<_LayoutSection> get _defaultSections => const [
        _LayoutSection(type: 'deals'),
        _LayoutSection(type: 'categories'),
        _LayoutSection(type: 'featured_category', slot: 'feature-1'),
        _LayoutSection(type: 'food_basket'),
        _LayoutSection(type: 'handwork'),
      ];

  List<_LayoutSection> get _effectiveSections {
    final list = _layoutSections.isNotEmpty
        ? [..._layoutSections]
        : [..._defaultSections];

    // Ensure required anchors exist at least once.
    final types = list.map((s) => s.typeLower).toList();
    if (!types.contains('categories')) {
      list.insert(0, const _LayoutSection(type: 'categories'));
      debugPrint('[HOME_LAYOUT] injected missing "categories" anchor');
    }
    if (!types.contains('food_basket')) {
      list.add(const _LayoutSection(type: 'food_basket'));
      debugPrint('[HOME_LAYOUT] injected missing "food_basket" anchor');
    }
    if (!types.contains('handwork')) {
      list.add(const _LayoutSection(type: 'handwork'));
      debugPrint('[HOME_LAYOUT] injected missing "handwork" anchor');
    }

    return list;
  }

  int _currentPage = 0;
  // final PageController _pageController = PageController();
  Timer? _carouselTimer;
  bool _loading = true;
  List<_SectionData> _sections = [];
  List<HandWork> _handworks = [];
  List<_HandworkThumb> _handworkThumbs = [];
  List<FoodBasket> _foodBaskets = [];
  bool _handworksLoading = false;
  bool _handworkThumbsLoading = false;
  bool _foodBasketsLoading = false;
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
  final PageController _handworkCardController =
      PageController(viewportFraction: 0.95);
  final PageController _basketCardController =
      PageController(viewportFraction: 0.9);
  Timer? _foodAutoTimer;
  Timer? _foodAutoResumeTimer;
  int _foodAutoIndex = 0;
  // inside _HomeScreenState

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
  // String _formatImageUrl(String raw) {
  //   final path = raw.startsWith('/') ? raw.substring(1) : raw;
  //   return '$host/$path';
  // }

// Navigate into your SingleItem detail screen:

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
    print("called discounts");
    _loadDiscounts(); // 👈 new
    print("end discounts");

    _loadGridPref();
    _loadCartCount();
    _loadAds();
    _startCarousel();
    _loadLayoutConfig();
    _loadFeaturedSets();
    _loadNewFeaturedCategories(); // New featured categories API
    _loadHandworkThumbnails();
    _loadSections();
    _loadHandworks();
    _loadFoodBaskets();
    _loadUserAvatar();

    // get user avatar url from shared preferences
  }

  Future<void> _loadDiscounts() async {
    final res = await _Cache.fetch('discounts_public', () {
      return http.get(apiUrl('/discounts/public'));
    });

    if (!res.hasData) {
      // Nothing cached either — keep list empty but mark fallback
      _markFallback(res);
      return;
    }

    try {
      final List list = jsonDecode(res.body!) as List;
      final discounts = list
          .map((j) => Discount.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() => _discounts = discounts);
      _markFallback(res);
      _startDealsCarousel();
    } catch (e) {
      // If decode fails, still mark fallback (we might be looking at stale/corrupt cache)
      _markFallback(res);
    }
  }

  Future<void> _loadLayoutConfig() async {
    try {
      final res = await http.get(apiUrl('/ui-layouts/home', {
        'clientId': 'default',
        'includeDefault': 'true',
        'activeOnly': 'true',
      }));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final layoutField = data['layout'];
        final sectionsRaw = layoutField is Map<String, dynamic>
            ? (layoutField['sections'] as List?) ?? const []
            : (layoutField is List ? layoutField : const []);
        final sections = _parseLayoutSections(List<dynamic>.from(sectionsRaw));
        final source = data['source'] ?? 'unknown';
        final active = data['is_active'];
        _logLayout(
          'API layout fetched source=$source active=$active (${sections.length} section(s))',
          sections: sections,
        );
        if (mounted) setState(() => _layoutSections = sections);
      } else if (res.statusCode == 404) {
        debugPrint(
            '[HOME_LAYOUT] /ui-layouts/home returned 404, using defaults');
        if (mounted) setState(() => _layoutSections = []);
      }
    } catch (_) {
      // ignore network/layout errors; fallback will be used
      debugPrint(
          '[HOME_LAYOUT] Failed to load layout config, falling back to defaults');
    }
  }

  List<_LayoutSection> _parseLayoutSections(List<dynamic> raw) {
    List<int> _parseIds(dynamic value) {
      final list = (value is List) ? value : const [];
      return list
          .whereType<dynamic>()
          .map((e) => int.tryParse(e.toString()) ?? -1)
          .where((id) => id > 0)
          .toList();
    }

    final sections = <_LayoutSection>[];
    for (final entry in raw) {
      if (entry is String) {
        sections.add(_LayoutSection(type: entry));
        continue;
      }
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        if (map['visible'] == false) continue; // legacy support
        final payload = map['payload'];
        final type = (map['type'] ?? '').toString();
        if (type.isEmpty) continue;
        var slot = (map['slot'] ?? '').toString();
        if (slot.isEmpty &&
            payload is Map &&
            payload['slot'] != null &&
            payload['slot'].toString().isNotEmpty) {
          slot = payload['slot'].toString();
        }
        final featuredSetIds = _parseIds(map['featured_set_ids'] ??
            (payload is Map ? payload['featured_set_ids'] : null));
        final adIds = _parseIds(
            map['ad_ids'] ?? (payload is Map ? payload['ad_ids'] : null));
        String? title;
        final rawTitle =
            map['title'] ?? (payload is Map ? payload['title'] : null);
        if (rawTitle != null && rawTitle.toString().trim().isNotEmpty) {
          title = rawTitle.toString().trim();
        }
        String? description;
        final rawDesc = map['description'] ??
            (payload is Map ? payload['description'] : null);
        if (rawDesc != null && rawDesc.toString().trim().isNotEmpty) {
          description = rawDesc.toString().trim();
        }
        sections.add(_LayoutSection(
          type: type,
          slot: slot,
          featuredSetIds: featuredSetIds,
          adIds: adIds,
          title: title,
          description: description,
        ));
      }
    }
    return sections;
  }

  Future<void> _loadFeaturedSets() async {
    try {
      final res = await http.get(apiUrl('/featured-category-sets/resolve', {
        'clientId': 'default',
        'page': 'home',
        'includeDefault': 'true',
        'activeOnly': 'true',
      }));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final sets = list
            .whereType<Map<String, dynamic>>()
            .map((m) => _FeaturedSet(
                  id: m['id'] ?? 0,
                  title: (m['title'] ?? '').toString(),
                  slot: (m['slot'] ?? '').toString(),
                  categoryIds: ((m['category_ids'] as List?) ?? const [])
                      .whereType<dynamic>()
                      .map((e) => int.tryParse(e.toString()) ?? -1)
                      .where((id) => id > 0)
                      .toList(),
                ))
            .toList();
        debugPrint(
            '[HOME_FEATURED] fetched ${sets.length} set(s): ${sets.map((s) => '${s.slot}:${s.categoryIds.length}').join(', ')}');
        if (mounted) setState(() => _featuredSets = sets);
      }
    } catch (_) {
      // ignore errors; fallback to defaults
      debugPrint('[HOME_FEATURED] failed to load featured category sets');
    }
  }

  /// Load new featured categories from /api/featured-categories/with-items
  Future<void> _loadNewFeaturedCategories() async {
    if (mounted) setState(() => _featuredCategoriesLoading = true);

    final res = await _Cache.fetch('new_featured_categories', () {
      return http.get(apiUrl('/featured-categories/with-items'));
    });

    if (!res.hasData) {
      _markFallback(res);
      if (mounted) setState(() => _featuredCategoriesLoading = false);
      return;
    }

    try {
      final List list = jsonDecode(res.body!) as List;
      final categories = list
          .whereType<Map<String, dynamic>>()
          .map(_FeaturedCategory.fromJson)
          .where((c) => c.isActive)
          .toList();

      // Sort by display_order
      categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      debugPrint(
          '[HOME_FEATURED_NEW] Loaded ${categories.length} featured categories');

      if (mounted) {
        setState(() => _newFeaturedCategories = categories);
      }
      _markFallback(res);
    } catch (e) {
      debugPrint('[HOME_FEATURED_NEW] Error parsing featured categories: $e');
      _markFallback(res);
    } finally {
      if (mounted) setState(() => _featuredCategoriesLoading = false);
    }
  }

  Future<void> reload() async {
    // choose what you want refreshed:
    await Future.wait([
      _loadCartCount(),
      _loadHandworks(),
      _loadFoodBaskets(),
    ]);

    if (mounted) setState(() {});
  }

  Future<void> _loadGridPref() async {
    final p = await SharedPreferences.getInstance();
    // was: _gridMode = p.getBool('gridMode') ?? false;
    setState(() => _gridMode = p.getBool('gridMode') ?? true); // ← default true
  }

  Widget _shimmerBox({
    double height = 120,
    double width = double.infinity,
    BorderRadius? radius,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius ?? BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildHomeShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shimmerBox(height: 180, radius: BorderRadius.circular(28)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 140)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(height: 140)),
            ],
          ),
          const SizedBox(height: 16),
          _shimmerBox(height: 200),
          const SizedBox(height: 16),
          _shimmerBox(height: 200),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 120)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _handworkShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _shimmerBox(height: 160, radius: BorderRadius.circular(20)),
    );
  }

  Widget _foodShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _shimmerBox(height: 210, radius: BorderRadius.circular(20)),
    );
  }

  int get _foodCarouselItemCount => _foodBaskets.length;

  void _restartFoodAutoScroll() {
    _foodAutoTimer?.cancel();
    if (!mounted || _foodCarouselItemCount <= 1) return;
    _foodAutoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_basketCardController.hasClients) return;
      _foodAutoIndex = (_foodAutoIndex + 1) % _foodCarouselItemCount;
      _basketCardController.animateToPage(
        _foodAutoIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseFoodAutoScroll() {
    _foodAutoTimer?.cancel();
    _foodAutoResumeTimer?.cancel();
  }

  void _scheduleFoodAutoResume() {
    _foodAutoResumeTimer?.cancel();
    _foodAutoResumeTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _restartFoodAutoScroll();
    });
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
        final existing = cart[idx];
        if (existing['basket_type'] != null) {
          record['basket_type'] = existing['basket_type'];
        }
        if (existing['basket_id'] != null) {
          record['basket_id'] = existing['basket_id'];
        }
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
    final res = await _Cache.fetch('ads', () => http.get(apiUrl('/ads')));

    if (!res.hasData) {
      _markFallback(res);
      setState(() => _loading = false);
      return;
    }

    try {
      final List list = jsonDecode(res.body!) as List;
      final ads = list.map((j) => Ad.fromJson(j)).toList();

      // Initialize video controllers only if we’re not in fallback
      // (optional: videos still work in fallback if URLs are reachable)
      if (!res.fromCache) {
        for (var ad in ads) {
          if (ad.mediaType == 'video') {
            final host = apiBase.replaceAll('/api', '');
            final rawPath = ad.filePath.startsWith('/')
                ? ad.filePath.substring(1)
                : ad.filePath;
            final url = Uri.parse('$host/$rawPath');
            final vc = VideoPlayerController.networkUrl(url);
            await vc.initialize();
            _videoControllers[ad.id] = vc;
          }
        }
      }

      setState(() {
        _ads = ads;
        _loading = false;
      });
      _markFallback(res);
    } catch (e) {
      _markFallback(res);
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
    if (_usingCachedData) return; // don’t try to paginate when offline/fallback

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

  List<Item> _flattenCategoryItems(Map<String, dynamic> map) {
    final subs = (map['subcategories'] as List?) ?? const [];
    final out = <Item>[];
    final catId = map['id'];
    final catNameEn = (map['name_en'] ?? '').toString();
    final catNameKu = (map['name_ku'] ?? '').toString();
    final catNameAr = (map['name_ar'] ?? '').toString();
    for (final s in subs) {
      final m = s as Map<String, dynamic>;
      int? _int(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString());
      }

      final subId = _int(m['id']);
      final nameEn = (m['name_en'] ?? '').toString();
      final nameKu = (m['name_ku'] ?? '').toString();
      final nameAr = (m['name_ar'] ?? '').toString();

      final rows = (m['items'] as List?) ?? const [];
      for (final raw in rows) {
        final mapItem = Map<String, dynamic>.from(
            raw as Map<String, dynamic>); // keep original intact
        mapItem['category_id'] = catId;
        mapItem['category_name_en'] = catNameEn;
        mapItem['category_name_ku'] = catNameKu;
        mapItem['category_name_ar'] = catNameAr;
        if (subId != null) mapItem['subcategory_id'] = subId;
        if (nameEn.isNotEmpty) mapItem['subcategory_name_en'] = nameEn;
        if (nameKu.isNotEmpty) mapItem['subcategory_name_ku'] = nameKu;
        if (nameAr.isNotEmpty) mapItem['subcategory_name_ar'] = nameAr;
        out.add(Item.fromJson(mapItem));
      }
    }
    return out;
  }

  Future<void> _loadSections() async {
    setState(() => _loading = true);

    final res = await _Cache.fetch(
      'categories_with_items',
      () => http.get(apiUrl('/categories/with-items')),
    );

    if (!res.hasData) {
      _markFallback(res);
      setState(() {
        _sections = [];
        _loading = false;
      });
      return;
    }

    try {
      final rawList = await compute(parseSectionsPayload, res.body!);

      final sections = rawList.map((entry) {
        final map = entry as Map<String, dynamic>;
        final cat = Category.fromJson(map);
        final items = _flattenCategoryItems(map); // ✅ use subcategories[].items
        return _SectionData(cat, items);
      }).toList();

      final Map<int, _RowFeed> feeds = {};
      for (final sec in sections) {
        feeds[sec.category.id] = _RowFeed(initial: sec.items);
      }
      // re-attach scroll listeners
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
        _feeds
          ..clear()
          ..addAll(feeds);
        _loading = false;
      });
      _markFallback(res);
      // ignore: unused_catch_stack
    } catch (e, st) {
      _markFallback(res);
      setState(() {
        _sections = [];
        _loading = false;
      });
    }
  }

  Map<int, _SectionData> get _categoryById {
    final map = <int, _SectionData>{};
    for (final sec in _sections) {
      map[sec.category.id] = sec;
    }
    return map;
  }

  Future<void> _loadHandworks() async {
    if (mounted) setState(() => _handworksLoading = true);
    final res = await _Cache.fetch('handworks', () {
      return http.get(apiUrl('/handworks'));
    });

    if (!res.hasData) {
      _markFallback(res);
      if (mounted) setState(() => _handworksLoading = false);
      return;
    }

    try {
      final List data = jsonDecode(res.body!) as List;
      final works = data
          .whereType<Map<String, dynamic>>()
          .map(HandWork.fromJson)
          .toList();
      if (mounted) {
        setState(() => _handworks = works);
      }
      _markFallback(res);
    } catch (_) {
      _markFallback(res);
    } finally {
      if (mounted) setState(() => _handworksLoading = false);
    }
  }

  Future<void> _loadHandworkThumbnails() async {
    if (mounted) setState(() => _handworkThumbsLoading = true);
    final res = await _Cache.fetch('handwork_thumbnails', () {
      return http.get(apiUrl('/handwork-thumbnails'));
    });

    if (!res.hasData) {
      _markFallback(res);
      if (mounted) setState(() => _handworkThumbsLoading = false);
      return;
    }

    try {
      final List data = jsonDecode(res.body!) as List;
      final thumbs = data
          .whereType<Map<String, dynamic>>()
          .map(_HandworkThumb.fromJson)
          .where((t) => t.imageUrl.isNotEmpty)
          .toList();
      thumbs.sort((a, b) {
        final aTs = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTs = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTs.compareTo(aTs);
      });
      if (mounted) setState(() => _handworkThumbs = thumbs);
      _markFallback(res);
    } catch (_) {
      _markFallback(res);
    } finally {
      if (mounted) setState(() => _handworkThumbsLoading = false);
    }
  }

  Future<void> _loadFoodBaskets() async {
    if (mounted) setState(() => _foodBasketsLoading = true);
    final res = await _Cache.fetch('food_baskets', () {
      return http.get(apiUrl('/foodbaskets'));
    });

    if (!res.hasData) {
      _markFallback(res);
      if (mounted) setState(() => _foodBasketsLoading = false);
      return;
    }

    try {
      final List data = jsonDecode(res.body!) as List;
      final baskets = data
          .whereType<Map<String, dynamic>>()
          .map(FoodBasket.fromJson)
          .toList();
      if (mounted) {
        setState(() => _foodBaskets = baskets);
        _foodAutoIndex = 0;
        _restartFoodAutoScroll();
      }
      _markFallback(res);
    } catch (_) {
      _markFallback(res);
    } finally {
      if (mounted) setState(() => _foodBasketsLoading = false);
    }
  }

  Future<void> _retryAll() async {
    setState(() {
      _backendIssue = null;
      _usingCachedData = false;
      _cacheTimestamp = null;
    });
    await Future.wait([
      _loadDiscounts(),
      _loadAds(),
      _loadSections(),
      _loadHandworks(),
      _loadFoodBaskets(),
    ]);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _dealsTimer?.cancel();
    _foodAutoTimer?.cancel();
    _foodAutoResumeTimer?.cancel();
    _pageController.dispose();
    _dealsPageController.dispose();
    _handworkCardController.dispose();
    _basketCardController.dispose();
    for (final vc in _videoControllers.values) {
      vc.dispose();
    }
    for (final f in _feeds.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildHomeShimmer();
// If everything is empty and we’re in fallback, show a friendly screen
    if (_usingCachedData &&
        _sections.isEmpty &&
        _ads.isEmpty &&
        _discounts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffD3E4C4),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong on our side.\nWe’ll be back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retryAll,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
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
                        activeThumbColor: secondaryColor,
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
            if (_usingCachedData)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We’re having trouble reaching our servers. '
                        'Showing saved data${_cacheTimestamp != null ? ' from ${_cacheTimestamp!.toLocal()}' : ''}.',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    TextButton(
                        onPressed: _retryAll, child: const Text('Retry')),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Color(0xffD3E4C4)),
                child: ListView(
                  padding: const EdgeInsets.all(3),
                  children: _buildHomeBlocks(host, s),
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

  // Wraps multi-widget sections so we only insert one divider between sections.
  Widget? _wrapSection(List<Widget> children) {
    if (children.isEmpty) return null;
    if (children.length == 1) return children.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _buildHomeBlocks(String host, S s) {
    final widgets = <Widget>[];
    final sections = _effectiveSections;
    var categoriesRendered = false;
    var foodRendered = false;
    var handworkRendered = false;
    var dealsRendered = false;
    _logLayout(
      'building home blocks; gridMode=$_gridMode; sections=${_sections.length}; source=${_layoutSections.isEmpty ? 'default' : 'remote'}',
      sections: sections,
    );

    // Always show the full ads carousel first.
    if (_ads.isNotEmpty) {
      widgets.add(_buildAdsBlock(host));
    }

    // Show discounts near the top by default.
    if (_activeDiscounts.isNotEmpty) {
      widgets.add(_buildDealsBlock(s));
      dealsRendered = true;
    }

    for (final section in sections) {
      switch (section.typeLower) {
        case 'deals':
          if (dealsRendered) {
            debugPrint('[HOME_LAYOUT] skipping duplicate deals section');
            break;
          }
          if (_activeDiscounts.isNotEmpty) {
            widgets.add(_buildDealsBlock(s));
            dealsRendered = true;
          } else {
            debugPrint(
                '[HOME_LAYOUT] deals section present but no active discounts');
          }
          break;
        case 'categories':
          if (categoriesRendered) {
            debugPrint('[HOME_LAYOUT] skipping duplicate categories section');
            break;
          }
          debugPrint('[HOME_LAYOUT] rendering categories gridMode=$_gridMode');
          if (_gridMode) {
            widgets.add(_wrapSection([
              _buildCategoryGrid(host),
              const SizedBox(height: 10),
            ])!);
          } else {
            final content = _wrapSection(_buildCategoryRows(host, s));
            if (content != null) widgets.add(content);
          }
          categoriesRendered = true;

          // Add new featured categories right after our categories
          if (_newFeaturedCategories.isNotEmpty || _featuredCategoriesLoading) {
            final featuredContent =
                _wrapSection(_buildNewFeaturedCategoriesWidgets());
            if (featuredContent != null) widgets.add(featuredContent);
          }
          break;
        case 'featured_category':
        case 'featured_categories': // legacy
          final w = _buildFeaturedCategoriesBlock(section, host);
          if (w != null) widgets.add(w);
          break;
        case 'custom_ad':
        case 'banner': // legacy
          final w = _buildCustomAdBlock(section, host);
          if (w != null) widgets.add(w);
          break;
        case 'food_basket':
          if (foodRendered) {
            debugPrint('[HOME_LAYOUT] skipping duplicate food_basket section');
            break;
          }
          final content = _wrapSection(_buildFoodBasketWidgets());
          if (content != null) widgets.add(content);
          foodRendered = true;
          break;
        case 'handwork':
          if (handworkRendered) {
            debugPrint('[HOME_LAYOUT] skipping duplicate handwork section');
            break;
          }
          final content = _wrapSection(_buildHandworkWidgets());
          if (content != null) widgets.add(content);
          handworkRendered = true;
          break;
        case 'product_carousel': // legacy
          if (section.slot.toLowerCase() == 'deals') {
            if (!dealsRendered && _activeDiscounts.isNotEmpty) {
              widgets.add(_buildDealsBlock(s));
              dealsRendered = true;
            }
          } else {
            if (categoriesRendered) {
              debugPrint(
                  '[HOME_LAYOUT] skipping legacy product_carousel slot=${section.slot} because categories already rendered');
              break;
            }
            debugPrint(
                '[HOME_LAYOUT] legacy category render via product_carousel slot=${section.slot} gridMode=$_gridMode');
            if (_gridMode) {
              widgets.add(_wrapSection([
                _buildCategoryGrid(host),
                const SizedBox(height: 10),
              ])!);
            } else {
              final content = _wrapSection(_buildCategoryRows(host, s));
              if (content != null) widgets.add(content);
            }
            categoriesRendered = true;
          }
          break;
        case 'brands': // legacy fallback to categories
          if (!categoriesRendered) {
            debugPrint(
                '[HOME_LAYOUT] legacy brands block triggering categories render');
            widgets.add(_wrapSection([
              _buildCategoryGrid(host),
              const SizedBox(height: 10),
            ])!);
            categoriesRendered = true;
          }
          break;
        default:
          debugPrint('[HOME_LAYOUT] unknown section type "${section.type}"');
          break;
      }
    }

    // Insert a divider between every section.
    if (widgets.isEmpty) return widgets;
    final interleaved = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (i > 0) interleaved.add(_sectionDivider(Icons.more_horiz));
      interleaved.add(widgets[i]);
    }
    return interleaved;
  }

  Widget? _buildCustomAdBlock(_LayoutSection section, String host) {
    List<Ad> adsToShow = [];
    if (section.adIds.isNotEmpty) {
      final idSet = section.adIds.toSet();
      adsToShow = _ads.where((a) => idSet.contains(a.id)).toList();
    } else {
      adsToShow = List<Ad>.from(_ads);
    }
    debugPrint(
        '[HOME_AD] slot="${section.slot}" adIds=${section.adIds} matched ${adsToShow.length} ads');
    if (adsToShow.isEmpty) return null;
    return _buildAdsBlock(
      host,
      ads: adsToShow,
      title: section.title,
      description: section.description,
    );
  }

  Widget _buildAdsBlock(String host,
      {List<Ad>? ads, String? title, String? description}) {
    final list = ads ?? _ads;
    if (list.isEmpty) return const SizedBox.shrink();
    final showSeeAll = ads == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSeeAll)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.collections),
              label: const Text('See all ads'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdsScreen(initialAds: _ads),
                  ),
                );
              },
            ),
          ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final ad = list[i];
              final rawPath = ad.filePath.startsWith('/')
                  ? ad.filePath.substring(1)
                  : ad.filePath;
              final mediaUrl = '$host/$rawPath';
              final vc = _videoControllers[ad.id];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes')),
                        ],
                      ),
                    );
                    if (open == true && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ad.mediaType == 'image'
                          ? CachedNetworkImage(
                              imageUrl: mediaUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.error, size: 40),
                              ),
                            )
                          : (vc != null
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: vc.value.size.width,
                                    height: vc.value.size.height,
                                    child: VideoPlayer(vc),
                                  ),
                                )
                              : Container(
                                  color: Colors.black12,
                                  child: const Center(
                                    child: Icon(Icons.play_arrow, size: 48),
                                  ),
                                )),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            list.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? primaryColor
                    : secondaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDealsBlock(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _dealsPageController,
            itemCount: _activeDiscounts.length,
            onPageChanged: (i) => setState(() => _currentDealPage = i),
            itemBuilder: (_, i) {
              final d = _activeDiscounts[i];
              final cover =
                  d.imageUrl.isNotEmpty ? mediaUrlFrom(d.imageUrl) : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiscountDetailScreen(discount: d),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (cover != null)
                          CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.error, size: 40),
                          )
                        else
                          Container(color: Colors.grey[300]),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4)
                              ],
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                d.badge,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.title.isNotEmpty ? d.title : s.tDeals,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black54,
                                            blurRadius: 4)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  d.items.isNotEmpty
                                      ? '${d.items.length} ${'items'}'
                                      : '',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
            _activeDiscounts.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentDealPage == index ? 12 : 8,
              height: _currentDealPage == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentDealPage == index
                    ? primaryColor
                    : secondaryColor.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildCategoryRows(String host, S s) {
    final widgets = <Widget>[];
    for (var sec in _sections) {
      final feed = _feeds[sec.category.id]!;
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeeMoreScreen(
                              title: sec.category.localizedName(context),
                              items: sec.items,
                              host: apiBase.replaceAll('/api', ''),
                              categoryId: sec.category.id,
                              onExit: reload,
                            ),
                          ));
                    },
                    child: Text(sec.category.localizedName(context),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 240,
              child: ListView.builder(
                controller: feed.controller,
                scrollDirection: Axis.horizontal,
                itemCount: feed.items.length + (feed.fetching ? 1 : 0),
                itemBuilder: (_, idx) {
                  if (idx >= feed.items.length) {
                    return const SizedBox(
                      width: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final it = feed.items[idx];
                  final rawPath = it.imageUrl.startsWith('/')
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
                            categoryId: it.categoryId,
                            categoryNameEn: it.categoryNameEn,
                            categoryNameKu: it.categoryNameKu,
                            categoryNameAr: it.categoryNameAr,
                            subcategoryId: it.subcategoryId,
                            subcategoryNameEn: it.subcategoryNameEn,
                            subcategoryNameKu: it.subcategoryNameKu,
                            subcategoryNameAr: it.subcategoryNameAr,
                            packSize: it.packSize,
                            unit: it.unit,
                            packPrice: it.packPrice,
                          ),
                        ),
                      );
                      _loadCartCount();
                      if (result is String && result.isNotEmpty) {
                        showTopNotice(context, result);
                      }
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xffFEFAE0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.all(8),
                                height: 110,
                                width: 110,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                    bottom: Radius.circular(16),
                                  ),
                                  child: it.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imgUrl,
                                          placeholder: (_, __) => const Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.white),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.error),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.fastfood,
                                              size: 40, color: Colors.black54),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-${it.discount.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              it.localizedName(context),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: it.discount > 0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${it.price.toStringAsFixed(0)} IQD',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${(it.price * (1 - it.discount / 100)).toStringAsFixed(0)} IQD',
                                        style: const TextStyle(
                                          fontSize: 9,
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
                          const SizedBox(height: 6),
                          Builder(
                            builder: (_) {
                              final q = _itemQty[it.id] ?? 0;
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFE6E6E6)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize: 18,
                                        onPressed: q > 0
                                            ? () => _decrementItem(it)
                                            : null,
                                        icon: const Icon(Icons.remove),
                                        color: Colors.redAccent,
                                        disabledColor: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$q',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize: 18,
                                        onPressed: () => _incrementItem(it),
                                        icon: const Icon(Icons.add),
                                        color: const Color(0xFF5D8A4E),
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
            const SizedBox(height: 4),
          ],
        ),
      );
    }
    return widgets;
  }

  Widget? _buildFeaturedCategoriesBlock(_LayoutSection section, String host) {
    final normalizedSlot = section.slot.toLowerCase().trim();
    List<_FeaturedSet> sets;
    if (section.featuredSetIds.isNotEmpty) {
      final idSet = section.featuredSetIds.toSet();
      sets = _featuredSets.where((s) => idSet.contains(s.id)).toList();
      debugPrint(
          '[HOME_FEATURED] ids=${section.featuredSetIds} matched ${sets.length} set(s)');
    } else if (normalizedSlot.isNotEmpty) {
      sets = _featuredSets
          .where((s) => s.slot.toLowerCase() == normalizedSlot)
          .toList();
      if (sets.isEmpty && _featuredSets.length == 1) {
        // fallback: if only one set exists, show it regardless of slot mismatch
        sets = _featuredSets;
        debugPrint(
            '[HOME_FEATURED] slot="${section.slot}" matched 0 set(s); falling back to the only available set "${sets.first.slot}"');
      } else {
        debugPrint(
            '[HOME_FEATURED] slot="${section.slot}" matched ${sets.length} set(s)');
      }
    } else {
      sets = List<_FeaturedSet>.from(_featuredSets);
      debugPrint(
          '[HOME_FEATURED] no slot provided; using ${sets.length} set(s)');
    }
    if (sets.isEmpty) return null;
    final catMap = _categoryById;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.description != null && section.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              section.description!,
              style: const TextStyle(color: textColor),
            ),
          ),
        for (final set in sets)
          Builder(
            builder: (_) {
              final cats = set.categoryIds
                  .map((id) => catMap[id]?.category)
                  .whereType<Category>()
                  .toList();
              if (cats.isEmpty) {
                debugPrint(
                    '[HOME_FEATURED] set "${set.title}" slot=${set.slot} resolved 0 categories from ids ${set.categoryIds}');
              }
              if (cats.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = cats[i];
                        final cover = cat.imageUrl.isNotEmpty
                            ? mediaUrlFrom(cat.imageUrl)
                            : null;
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeeMoreScreen(
                                  title: cat.localizedName(context),
                                  items: catMap[cat.id]?.items ?? [],
                                  host: apiBase.replaceAll('/api', ''),
                                  categoryId: cat.id,
                                  onExit: reload,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xffFEFAE0),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFEFEFEF)),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: cover != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: CachedNetworkImage(
                                            imageUrl: cover,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.error),
                                          ),
                                        )
                                      : const Icon(Icons.category,
                                          color: secondaryColor, size: 32),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.localizedName(context),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
      ],
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                        fontSize: 11.5,
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

  Widget _sectionDivider(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: secondaryColor.withValues(alpha: 0.35),
              thickness: 1,
            ),
          ),
          Expanded(
            child: Divider(
              color: secondaryColor.withValues(alpha: 0.35),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the new featured categories section - grouped by layout type
  List<Widget> _buildNewFeaturedCategoriesWidgets() {
    if (_featuredCategoriesLoading && _newFeaturedCategories.isEmpty) {
      return [
        _shimmerBox(height: 140, radius: BorderRadius.circular(20)),
        const SizedBox(height: 16),
      ];
    }

    if (_newFeaturedCategories.isEmpty) return const [];

    final widgets = <Widget>[];

    // Group categories by layout type
    final banners =
        _newFeaturedCategories.where((c) => c.layoutType == 'banner').toList();
    final grid2Categories =
        _newFeaturedCategories.where((c) => c.layoutType == 'grid_2').toList();
    final grid4Categories =
        _newFeaturedCategories.where((c) => c.layoutType == 'grid_4').toList();

    // Show banners first (full-width, clean image cards)
    for (final category in banners) {
      widgets.add(_buildFeaturedBannerCard(category));
      widgets.add(const SizedBox(height: 12));
    }

    // Show grid_2 categories grouped in a 2-column grid
    if (grid2Categories.isNotEmpty) {
      widgets.add(_buildFeaturedCategoryGrid(grid2Categories, 2));
      widgets.add(const SizedBox(height: 16));
    }

    // Show grid_4 categories grouped in a 4-column grid
    if (grid4Categories.isNotEmpty) {
      widgets.add(_buildFeaturedCategoryGrid(grid4Categories, 4));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  /// Clean banner card - just image, no shadow/text overlay
  Widget _buildFeaturedBannerCard(_FeaturedCategory category) {
    final imageUrl = category.imageUrl != null && category.imageUrl!.isNotEmpty
        ? mediaUrlFrom(category.imageUrl!)
        : null;

    return GestureDetector(
      onTap: () => _openFeaturedCategoryScreen(category),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFE8F4E8),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category,
                                size: 48, color: primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              category.localizedName(context),
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFE8F4E8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category,
                              size: 48, color: primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            category.localizedName(context),
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Build a grid of featured category cards
  Widget _buildFeaturedCategoryGrid(
      List<_FeaturedCategory> categories, int columns) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: columns == 2 ? 12 : 8,
          mainAxisSpacing: columns == 2 ? 12 : 8,
          childAspectRatio: columns == 2 ? 1.0 : 0.85,
        ),
        itemBuilder: (_, i) =>
            _buildFeaturedCategoryCard(categories[i], columns),
      ),
    );
  }

  /// Clean category card for grids - just image, no overlay
  Widget _buildFeaturedCategoryCard(_FeaturedCategory category, int columns) {
    final imageUrl = category.imageUrl != null && category.imageUrl!.isNotEmpty
        ? mediaUrlFrom(category.imageUrl!)
        : null;

    final isCompact = columns == 4;

    return GestureDetector(
      onTap: () => _openFeaturedCategoryScreen(category),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffFEFAE0),
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade100),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFE8F4E8),
                          child: Icon(
                            Icons.category,
                            size: isCompact ? 24 : 40,
                            color: primaryColor,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE8F4E8),
                        child: Icon(
                          Icons.category,
                          size: isCompact ? 24 : 40,
                          color: primaryColor,
                        ),
                      ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 4 : 8,
                    vertical: isCompact ? 2 : 4,
                  ),
                  child: Center(
                    child: Text(
                      category.localizedName(context),
                      style: TextStyle(
                        fontSize: isCompact ? 9 : 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: isCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open the dedicated featured category screen
  void _openFeaturedCategoryScreen(_FeaturedCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FeaturedCategoryDetailScreen(
          category: category,
          onCartUpdated: _loadCartCount,
        ),
      ),
    );
  }

  void _openItemDetail(Item item) async {
    final imgUrl = item.imageUrl.isNotEmpty ? mediaUrlFrom(item.imageUrl) : '';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleItem(
          id: item.id,
          icon: Icons.fastfood,
          name: item.localizedName(context),
          description: item.description,
          unitPrice: item.price,
          imageUrl: imgUrl,
          discount: item.discount,
          supplierName: item.supplier_name,
          categoryId: item.categoryId,
          categoryNameEn: item.categoryNameEn,
          categoryNameKu: item.categoryNameKu,
          categoryNameAr: item.categoryNameAr,
          subcategoryId: item.subcategoryId,
          subcategoryNameEn: item.subcategoryNameEn,
          subcategoryNameKu: item.subcategoryNameKu,
          subcategoryNameAr: item.subcategoryNameAr,
          packSize: item.packSize,
          unit: item.unit,
          packPrice: item.packPrice,
        ),
      ),
    );
    _loadCartCount();
    if (result is String && result.isNotEmpty) {
      showTopNotice(context, result);
    }
  }

  List<Widget> _buildHandworkWidgets() {
    final s = S.of(context);
    final thumb = _handworkThumbs.isNotEmpty ? _handworkThumbs.first : null;
    if (_handworkThumbsLoading && thumb == null) {
      return [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _handworkCardController,
            padEnds: false,
            itemCount: 3,
            itemBuilder: (_, __) => _handworkShimmerCard(),
          ),
        ),
        const SizedBox(height: 12),
      ];
    }
    if (thumb == null) return const [];

    final imageUrl =
        thumb.imageUrl.isNotEmpty ? mediaUrlFrom(thumb.imageUrl) : null;

    return [
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _openHandworkScreen,
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl == null
                    ? Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image,
                            size: 48, color: Colors.grey),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 14,
                  child: Text(
                    s.tapToViewMore,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildFoodBasketWidgets() {
    if (_foodBasketsLoading && _foodBaskets.isEmpty) {
      return [
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _basketCardController,
            padEnds: false,
            itemCount: 3,
            itemBuilder: (_, __) => _foodShimmerCard(),
          ),
        ),
        const SizedBox(height: 8),
      ];
    }
    if (_foodBaskets.isEmpty) return const [];
    final cards = _foodBaskets;

    return [
      const SizedBox(height: 8),
      SizedBox(
        height: 210,
        child: Listener(
          onPointerDown: (_) => _pauseFoodAutoScroll(),
          onPointerUp: (_) => _scheduleFoodAutoResume(),
          onPointerCancel: (_) => _scheduleFoodAutoResume(),
          child: PageView.builder(
            controller: _basketCardController,
            padEnds: false,
            itemCount: cards.length,
            onPageChanged: (index) {
              _foodAutoIndex = index;
            },
            itemBuilder: (_, idx) {
              final basket = cards[idx];
              final imageUrl = basket.primaryImage == null
                  ? null
                  : mediaUrlFrom(basket.primaryImage!);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => _openFoodBasketDetail(basket),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffFEFAE0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 16 / 7,
                            child: imageUrl == null
                                ? Container(
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          basket.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${basket.price.toStringAsFixed(0)} IQD',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF567765),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      // const SizedBox(height: 16),
    ];
  }

  Future<void> _openHandworkScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HandWorksScreen(initialHandworks: _handworks),
      ),
    );
  }

  Future<void> _openFoodBasketsScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodBasketsScreen(initialBaskets: _foodBaskets),
      ),
    );
    if (changed == true) {
      await _loadCartCount();
    }
  }

  Future<void> _openFoodBasketDetail(FoodBasket basket) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodBasketDetailPage(basket: basket),
      ),
    );
    if (changed == true) {
      await _loadCartCount();
    }
  }
}

/// Dedicated screen for featured category - shows items and subcategories
/// Orders from this screen are sent to WhatsApp, not backend
class _FeaturedCategoryDetailScreen extends StatefulWidget {
  final _FeaturedCategory category;
  final VoidCallback? onCartUpdated;

  const _FeaturedCategoryDetailScreen({
    required this.category,
    this.onCartUpdated,
  });

  @override
  State<_FeaturedCategoryDetailScreen> createState() =>
      _FeaturedCategoryDetailScreenState();
}

class _FeaturedCategoryDetailScreenState
    extends State<_FeaturedCategoryDetailScreen> {
  // -1 means "All Items", 0+ means specific subcategory index
  int _selectedSubcategoryIndex = -1;

  // Track quantities for each item by item ID
  final Map<int, int> _itemQuantities = {};

  int _getQuantity(int itemId) => _itemQuantities[itemId] ?? 0;

  void _incrementQuantity(int itemId) {
    setState(() {
      _itemQuantities[itemId] = (_itemQuantities[itemId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(int itemId) {
    setState(() {
      final current = _itemQuantities[itemId] ?? 0;
      if (current > 0) {
        _itemQuantities[itemId] = current - 1;
      }
    });
  }

  int get _totalItemsInCart {
    return _itemQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  double get _totalPrice {
    double total = 0;
    final allItems = widget.category.getAllItems();
    for (final item in allItems) {
      final qty = _itemQuantities[item.id] ?? 0;
      if (qty > 0) {
        final hasDiscount = item.discount > 0;
        final effectivePrice =
            hasDiscount ? item.price * (1 - item.discount / 100) : item.price;
        total += effectivePrice * qty;
      }
    }
    return total;
  }

  List<Item> get _displayedItems {
    // -1 = show ALL items (category level + all subcategories)
    if (_selectedSubcategoryIndex < 0 ||
        widget.category.subcategories.isEmpty) {
      return widget.category.getAllItems();
    }

    // Show items from specific subcategory
    final index = _selectedSubcategoryIndex.clamp(
        0, widget.category.subcategories.length - 1);
    final sub = widget.category.subcategories[index];
    return sub.subcategoryItems.map((si) => si.item).whereType<Item>().toList();
  }

  String _getAllText(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ku' ? 'هەموو' : (locale == 'ar' ? 'الكل' : 'All');
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, color: Colors.white, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSubcategories = widget.category.subcategories.isNotEmpty;
    final hasCategoryItems = widget.category.categoryItems.isNotEmpty;
    const bgColor = Color(0xFFD4E8D4); // Softer green background

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: primaryColor, size: 18),
            ),
          ),
        ),
        title: Text(
          widget.category.localizedName(context),
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _totalItemsInCart > 0 ? _sendToWhatsApp : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: _totalItemsInCart > 0
                          ? Colors.redAccent
                          : Colors.grey,
                      size: 24,
                    ),
                    if (_totalItemsInCart > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '$_totalItemsInCart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subcategory chips - always show if there are subcategories OR category-level items
          if (hasSubcategories || hasCategoryItems)
            Container(
              height: 48,
              margin: const EdgeInsets.only(top: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // "All" chip - shows all items
                  _buildFilterChip(
                    label: _getAllText(context),
                    isSelected: _selectedSubcategoryIndex == -1,
                    onTap: () => setState(() => _selectedSubcategoryIndex = -1),
                  ),
                  // Subcategory chips
                  ...widget.category.subcategories.asMap().entries.map((entry) {
                    final i = entry.key;
                    final sub = entry.value;
                    return _buildFilterChip(
                      label: sub.localizedName(context),
                      isSelected: _selectedSubcategoryIndex == i,
                      onTap: () =>
                          setState(() => _selectedSubcategoryIndex = i),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Items grid with nicer animation
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _displayedItems.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      key: ValueKey(_selectedSubcategoryIndex),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.60,
                      ),
                      itemCount: _displayedItems.length,
                      itemBuilder: (_, i) => _buildItemCard(_displayedItems[i]),
                    ),
            ),
          ),
        ],
      ),
      // Bottom order button
      bottomSheet: _totalItemsInCart > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_totalItemsInCart ${S.of(context).item}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_totalPrice.toStringAsFixed(0)} IQD',
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _sendToWhatsApp,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        S.of(context).sendOrder,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF25D366), // WhatsApp green
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).basketEmpty,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final imageUrl =
        item.imageUrl.isNotEmpty ? mediaUrlFrom(item.imageUrl) : null;
    final hasDiscount = item.discount > 0;
    final effectivePrice =
        hasDiscount ? item.price * (1 - item.discount / 100) : item.price;
    final quantity = _getQuantity(item.id);
    final isInCart = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInCart ? primaryColor.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isInCart
                ? primaryColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isInCart ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image with discount badge
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.fastfood,
                                  color: Colors.grey, size: 40),
                            ),
                    ),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${item.discount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Quantity badge when item is in cart
                if (isInCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              item.localizedName(context),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

          // Unit/Size
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.unit.isNotEmpty ? item.unit : 'Pcs',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),

          // Price
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasDiscount) ...[
                  Text(
                    '${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${effectivePrice.toStringAsFixed(0)} IQD',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffFEFAE0),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isInCart
                      ? primaryColor.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Minus button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: quantity > 0
                          ? () => _decrementQuantity(item.id)
                          : null,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(25)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: quantity > 0
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  // Quantity
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Text(
                      '$quantity',
                      key: ValueKey(quantity),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isInCart ? primaryColor : textColor,
                      ),
                    ),
                  ),
                  // Plus button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _incrementQuantity(item.id),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(25)),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToWhatsApp() async {
    // Build order message
    final s = S.of(context);
    final allItems = widget.category.getAllItems();
    final orderItems = <String>[];

    for (final item in allItems) {
      final qty = _itemQuantities[item.id] ?? 0;
      if (qty > 0) {
        final hasDiscount = item.discount > 0;
        final effectivePrice =
            hasDiscount ? item.price * (1 - item.discount / 100) : item.price;
        final lineTotal = effectivePrice * qty;
        orderItems.add(
            '• ${item.localizedName(context)} x$qty = ${lineTotal.toStringAsFixed(0)} IQD');
      }
    }

    if (orderItems.isEmpty) return;

    final message = '''
🛒 *${widget.category.localizedName(context)}*

${orderItems.join('\n')}

━━━━━━━━━━━━━━━
*${s.total}:* ${_totalPrice.toStringAsFixed(0)} IQD
''';

    // WhatsApp number - you may want to make this configurable
    const whatsappNumber =
        '9647507779779'; // Replace with your actual WhatsApp number

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.snackWhatsAppOpenFail),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
