// lib/screens/seeMore.dart
// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'package:barvin/models/item.dart';
import 'package:barvin/screens/home.dart' show primaryColor, textColor;
import 'package:barvin/screens/single_item.dart' hide primaryColor;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class SeeMoreScreen extends StatefulWidget {
  final String title;
  final List<Item> items; // initial items (optional)
  final String host; // e.g. http://62.84.176.8:4000
  final int categoryId;
  final VoidCallback? onExit;

  const SeeMoreScreen({
    super.key,
    required this.title,
    required this.items,
    required this.host,
    required this.categoryId,
    this.onExit,
  });

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

/// Lightweight category + subcategory for this screen
class _CatLite {
  final int id;
  final String nameEn, nameKu, nameAr;
  _CatLite({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
  });
  factory _CatLite.fromJson(Map<String, dynamic> j) => _CatLite(
        id: j['id'],
        nameEn: j['name_en'] ?? '',
        nameKu: j['name_ku'] ?? '',
        nameAr: j['name_ar'] ?? '',
      );
  String name(BuildContext ctx) {
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

class _SubLite {
  final int id;
  final String nameEn, nameKu, nameAr;
  _SubLite({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
  });
  factory _SubLite.fromJson(Map<String, dynamic> j) => _SubLite(
        id: j['id'],
        nameEn: j['name_en'] ?? '',
        nameKu: j['name_ku'] ?? '',
        nameAr: j['name_ar'] ?? '',
      );
  String name(BuildContext ctx) {
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

class _SeeMoreScreenState extends State<SeeMoreScreen>
    with TickerProviderStateMixin {
  String get _apiBase => '${widget.host}/api';

  // top categories
  List<_CatLite> _cats = [];
  int _selectedCatId = -1;
  TabController? _tabc;

  // subcategories
  final _subChipKeys = <int, GlobalKey>{};
  List<_SubLite> _subs = [];
  int? _selectedSubId;

  // search + supplier filter
  String _query = '';
  String? _selectedSupplier;
  Timer? _debounce;
  int _cartCount = 0;
  // ignore: unused_field
  double _cartTotal = 0.0;

  // grid + paging
  final ScrollController _gridScroll = ScrollController();
  int _page = 1;
  final int _pageSize = 30;
  bool _fetching = false;
  bool _hasMore = true;

  // data
  List<Item> _items = [];
  final Set<int> _seenIds = {};
  final Map<int, String> _supplierByItemId = {}; // itemId -> supplierName
  final Map<int, int> _itemQty = {};
  bool _loading = true;

  void _scrollSubIntoView(int subId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _subChipKeys[subId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    });
  }

  void showTopNotice(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: primaryColor,
        elevation: 2,
        content: Text(
          text,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: const Icon(Icons.check_circle, color: Colors.white),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (messenger.mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  void _handleBack() {
    widget.onExit?.call();
    Navigator.of(context).pop();
  }

  void _resetPaging() {
    _page = 1;
    _hasMore = true;
    _items = [];
    _seenIds.clear();
    _supplierByItemId.clear();
  }

  void _addItemsDedup(Iterable<Item> more) {
    for (final it in more) {
      if (_seenIds.add(it.id)) _items.add(it);
    }
  }

  Future<void> _resetAndFetch() async {
    setState(() => _loading = true);
    _resetPaging();
    await _loadItems(reset: true);
    if (!mounted) return;
    setState(() => _loading = false);
    if (_selectedSubId != null) _scrollSubIntoView(_selectedSubId!);
  }

  Future<void> _syncQtyFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('cart') ?? [];

    final qtyMap = <int, int>{};
    var total = 0.0;
    var count = 0;

    for (final s in list) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      final id = int.tryParse(m['id']?.toString() ?? '');
      final q = int.tryParse(m['quantity']?.toString() ?? '') ?? 0;
      final price = double.tryParse(m['price']?.toString() ?? '0') ?? 0.0;
      final disc = double.tryParse(m['discount']?.toString() ?? '0') ?? 0.0;
      final eff = price * (1 - (disc / 100.0));

      if (id != null) qtyMap[id] = q;
      count += q;
      total += eff * q;
    }

    if (!mounted) return;
    setState(() {
      _itemQty
        ..clear()
        ..addAll(qtyMap);
      _cartCount = count;
      _cartTotal = total;
    });
  }

  Future<void> _setItemQty(Item it, int newQty) async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList('cart') ?? [];
    final cart = cartList
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList(growable: true);

    final idStr = it.id.toString();
    final idx = cart.indexWhere((m) => m['id']?.toString() == idStr);

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
        'supplierName': _supplierByItemId[it.id] ?? '',
      };
      if (idx >= 0) {
        cart[idx] = record;
      } else {
        cart.add(record);
      }
    }

    await prefs.setStringList('cart', cart.map((m) => jsonEncode(m)).toList());
    await _syncQtyFromPrefs();
  }

  Future<void> _inc(Item it) => _setItemQty(it, (_itemQty[it.id] ?? 0) + 1);
  Future<void> _dec(Item it) => _setItemQty(it, (_itemQty[it.id] ?? 0) - 1);

  void _onGridScroll() {
    if (!_hasMore || _fetching) return;
    if (_gridScroll.position.pixels >=
        _gridScroll.position.maxScrollExtent - 300) {
      _loadItems(); // next page
    }
  }

  // ───────────────────────────── lifecycle / init ─────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.categoryId;
    _addItemsDedup(widget.items);
    _buildSupplierIndex(_items, const []);
    _gridScroll.addListener(_onGridScroll);
    _init();
    _syncQtyFromPrefs();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadCategories();
    await _loadSubcategories();
    await _loadItems();
    setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final uri = Uri.parse('$_apiBase/categories');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((m) => _CatLite.fromJson(m))
            .toList();
        setState(() {
          _cats = list;
        });

        if (!_cats.any((c) => c.id == _selectedCatId) && _cats.isNotEmpty) {
          _selectedCatId = _cats.first.id;
        }

        final idx = _cats.indexWhere((c) => c.id == _selectedCatId);
        _tabc?.dispose();
        _tabc = TabController(
          length: _cats.length,
          initialIndex: idx >= 0 ? idx : 0,
          vsync: this,
        );
        _tabc!.addListener(() {
          if (_tabc!.indexIsChanging) return;
          final newCat = _cats[_tabc!.index].id;
          if (newCat != _selectedCatId) {
            setState(() {
              _selectedCatId = newCat;
              _selectedSubId = null;
              _selectedSupplier = null;
              _query = '';
            });
            _loadSubcategories().then((_) => _resetAndFetch());
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSubcategories() async {
    try {
      final uri =
          Uri.parse('$_apiBase/categories/${_selectedCatId}/subcategories');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((m) => _SubLite.fromJson(m))
            .toList();

        setState(() {
          _subs = list;

          // Keep previous sub if it still exists, otherwise pick first
          final prev = _selectedSubId;
          if (prev != null && _subs.any((s) => s.id == prev)) {
            _selectedSubId = prev;
          } else {
            _selectedSubId = _subs.isNotEmpty ? _subs.first.id : null;
          }

          if (_selectedSubId != null) _scrollSubIntoView(_selectedSubId!);
          _resetPaging();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadItems({bool reset = false}) async {
    if (_fetching) return;
    _fetching = true;
    try {
      final params = <String, String>{
        'categoryId': _selectedCatId.toString(),
        'shown': 'true',
        'page': _page.toString(),
        'pageSize': _pageSize.toString(),
      };
      if (_selectedSubId != null) {
        params['subcategoryId'] = _selectedSubId.toString();
      }
      if (_query.trim().isNotEmpty) params['q'] = _query.trim();
      if (_selectedSupplier != null && _selectedSupplier!.isNotEmpty) {
        params['supplierName'] = _selectedSupplier!;
      }

      final uri = Uri.parse('$_apiBase/items').replace(queryParameters: params);
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rows = (body is List) ? body : (body['rows'] ?? []);
        final totalCount = (body is Map && body['count'] is num)
            ? (body['count'] as num).toInt()
            : null;

        final newItems = <Item>[];
        for (final m in rows.cast<Map<String, dynamic>>()) {
          newItems.add(Item.fromJson(m));
          _supplierByItemId[m['id'] as int] =
              (m['supplier_name'] ?? '').toString();
        }

        setState(() {
          _addItemsDedup(newItems);
          if (totalCount != null) {
            _hasMore = _items.length < totalCount;
          } else {
            _hasMore = newItems.length == _pageSize;
          }
          if (_hasMore) _page += 1;

          if (_selectedSupplier != null &&
              !_supplierSet.contains(_selectedSupplier)) {
            _selectedSupplier = null;
          }
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (_) {
      setState(() => _hasMore = false);
    } finally {
      _fetching = false;
    }
  }

  void _buildSupplierIndex(List<Item> items, List<String> maybeSuppliers) {
    for (final it in items) {
      _supplierByItemId.putIfAbsent(it.id, () => '');
    }
  }

  Set<String> get _supplierSet {
    final set = <String>{};
    for (final it in _items) {
      final s = _supplierByItemId[it.id] ?? '';
      if (s.isNotEmpty) set.add(s);
    }
    return set;
  }

  List<Item> get _visibleItems {
    if (_selectedSupplier == null || _selectedSupplier!.isEmpty) return _items;
    return _items
        .where((it) => _supplierByItemId[it.id] == _selectedSupplier)
        .toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabc?.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  // ────────────────────────────────── UI ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop) {
          widget.onExit?.call();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: const Text(
            'Products',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: primaryColor),
                  onPressed: () => Navigator.pushNamed(context, '/basket'),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _cartCount > 99 ? '99+' : '$_cartCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 213, 236, 221),
                Color(0xFFF1FAF5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // 1) Category tabs (scrollable)
              if (_cats.isNotEmpty)
                Container(
                  height: 44,
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: _tabc,
                    isScrollable: true,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    labelColor: textColor,
                    unselectedLabelColor: textColor.withValues(alpha: 0.6),
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    tabs: [
                      for (final c in _cats) Tab(child: Text(c.name(context))),
                    ],
                  ),
                ),

              // 2) Subcategory chips (no “All”)
              if (_subs.isNotEmpty)
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final s = _subs[i];
                      final selected = _selectedSubId == s.id;
                      final key =
                          _subChipKeys.putIfAbsent(s.id, () => GlobalKey());

                      return SizedBox(
                        height: 40,
                        child: ChoiceChip(
                          key: key,
                          selected: selected,
                          label: Text(s.name(context)),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: -2),
                          onSelected: (sel) {
                            if (!sel) return;
                            setState(() => _selectedSubId = s.id);
                            _scrollSubIntoView(s.id);
                            _resetAndFetch();
                          },
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : textColor,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected
                                ? Colors.transparent
                                : const Color(0xFFE7E7E7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _subs.length,
                  ),
                ),

              const SizedBox(height: 4),

              // 3) Products grid with loader overlay
              Expanded(
                child: Stack(
                  children: [
                    if (_loading && _visibleItems.isEmpty)
                      _buildGridShimmer()
                    else
                      GridView.builder(
                        controller: _gridScroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _visibleItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.58,
                        ),
                        itemBuilder: (context, index) {
                          final it = _visibleItems[index];
                          final rawPath = it.imageUrl.startsWith('/')
                              ? it.imageUrl.substring(1)
                              : it.imageUrl;
                          final imgUrl = '${widget.host}/$rawPath';

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
                              if (result is String && result.isNotEmpty) {
                                showTopNotice(context, result);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xffFEFAE0),
                                border:
                                    Border.all(color: const Color(0xFFEFEFEF)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 4),
                                  Expanded(
                                    flex: 4,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                      child: it.imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imgUrl,
                                              fit: BoxFit.contain,
                                              placeholder: (_, __) =>
                                                  _gridImageShimmer(),
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(Icons.error),
                                            )
                                          : _gridImageShimmer(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Column(
                                        children: [
                                          Text(
                                            it.localizedName(context),
                                            style: const TextStyle(
                                                fontSize: 11.5,
                                                color: textColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          if (it.description.isNotEmpty)
                                            Text(
                                              it.description,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textColor.withValues(
                                                    alpha: 0.6),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            Text(
                                              it.description,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textColor.withValues(
                                                    alpha: 0.6),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          FittedBox(
                                            child: it.discount > 0
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '${it.price.round()} IQD',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${(it.price * (1 - it.discount / 100)).round()} IQD',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    '${it.price.round()} IQD',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColor,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(height: 6),
                                          // quantity controls
                                          Container(
                                            height: 30,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Color(0xFFE7E7E7)),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _miniQtyBtn(
                                                  icon: Icons.remove,
                                                  onTap:
                                                      (_itemQty[it.id] ?? 0) > 0
                                                          ? () => _dec(it)
                                                          : null,
                                                  color: Colors.redAccent,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 6),
                                                  child: Text(
                                                    '${_itemQty[it.id] ?? 0}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                _miniQtyBtn(
                                                  icon: Icons.add,
                                                  onTap: () => _inc(it),
                                                  color: primaryColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if (_loading && _visibleItems.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _buildGridOverlayShimmer(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildGridOverlayShimmer() {
    return Container(
      color: Colors.white.withValues(alpha: 0.7),
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniQtyBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
