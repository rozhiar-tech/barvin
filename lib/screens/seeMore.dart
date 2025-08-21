// lib/screens/seeMore.dart
// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'package:barvin/screens/home.dart'
    show Item, primaryColor, secondaryColor, textColor;
import 'package:barvin/screens/single_item.dart' hide primaryColor;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

class SeeMoreScreen extends StatefulWidget {
  final String title;
  final List<Item> items; // initial items (optional)
  final String host; // e.g. http://95.111.224.58:4000
  final int categoryId;

  const SeeMoreScreen({
    super.key,
    required this.title,
    required this.items,
    required this.host,
    required this.categoryId,
  });

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

/// Lightweight category + subcategory for this screen
class _CatLite {
  final int id;
  final String nameEn, nameKu, nameAr;
  _CatLite(
      {required this.id,
      required this.nameEn,
      required this.nameKu,
      required this.nameAr});
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
  _SubLite(
      {required this.id,
      required this.nameEn,
      required this.nameKu,
      required this.nameAr});
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
  List<_SubLite> _subs = [];
  int? _selectedSubId; // no "All" chip → always null or some id

  // search + supplier filter
  String _query = '';
  String? _selectedSupplier; // null => all suppliers
  Timer? _debounce;

  // data
  List<Item> _items = [];
  final Map<int, String> _supplierByItemId = {}; // itemId -> supplierName
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.categoryId;
    _items = List.of(widget.items);
    _buildSupplierIndex(_items, const []);
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadCategories(); // also sets up TabController
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

        // ensure selected cat exists
        if (!_cats.any((c) => c.id == _selectedCatId) && _cats.isNotEmpty) {
          _selectedCatId = _cats.first.id;
        }

        // (re)create TabController with selected index
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
              _loading = true;
            });
            _loadSubcategories()
                .then((_) => _loadItems())
                .whenComplete(() => setState(() => _loading = false));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSubcategories() async {
    _subs = [];
    _selectedSubId = null;
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
          // no "All" → preselect first if exists
          if (_subs.isNotEmpty) {
            _selectedSubId ??= _subs.first.id;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadItems() async {
    try {
      final params = <String, String>{
        'categoryId': _selectedCatId.toString(),
        'shown': 'true',
      };
      if (_selectedSubId != null) {
        params['subcategoryId'] = _selectedSubId.toString();
      }
      if (_query.trim().isNotEmpty) {
        params['q'] = _query.trim();
      }
      // optional server-side supplier filter if your API supports it:
      if (_selectedSupplier != null && _selectedSupplier!.isNotEmpty) {
        params['supplierName'] = _selectedSupplier!;
      }

      final uri = Uri.parse('$_apiBase/items').replace(queryParameters: params);
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rows = body is List ? body : (body['rows'] ?? []);
        // build Item list + supplier index
        final items = <Item>[];
        final suppliers = <String>[];
        for (final m in rows.cast<Map<String, dynamic>>()) {
          items.add(Item.fromJson(m));
          final s = (m['supplier_name'] ?? '').toString();
          _supplierByItemId[m['id'] as int] = s;
          if (s.isNotEmpty) suppliers.add(s);
        }
        setState(() {
          _items = items;
          if (_selectedSupplier != null &&
              !_supplierSet.contains(_selectedSupplier)) {
            _selectedSupplier = null;
          }
        });
      }
    } catch (_) {}
  }

  void _buildSupplierIndex(List<Item> items, List<String> maybeSuppliers) {
    // when coming from Home, supplier_name isn't in Item → leave unknown
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

  void _onSearchChanged(String v) {
    _query = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadItems);
    setState(() {}); // update clear button visibility
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // App bar like screenshot (“Products”), keep our colors
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: const Text(
          'Products',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 1) Category tabs (scrollable)
                  if (_cats.isNotEmpty)
                    Container(
                      height: 44,
                      alignment: Alignment.centerLeft,
                      child: TabBar(
                        controller: _tabc,
                        isScrollable: true,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        labelColor: textColor,
                        unselectedLabelColor: textColor.withOpacity(0.6),
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        tabs: [
                          for (final c in _cats)
                            Tab(child: Text(c.name(context))),
                        ],
                      ),
                    ),

                  // 2) Subcategory pills (no “All”)
                  if (_subs.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, i) {
                          final s = _subs[i];
                          final selected = _selectedSubId == s.id;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(s.name(context)),
                            onSelected: (sel) {
                              if (!sel) return;
                              setState(() => _selectedSubId = s.id);
                              _loadItems();
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
                                    : const Color(0xFFE7E7E7)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: _subs.length,
                      ),
                    ),

                  // 3) Search + Supplier filter row
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        // search
                        Expanded(
                          child: TextField(
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText:
                                  'Search in ${_currentCatName(context)}…',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              prefixIcon:
                                  const Icon(Icons.search, color: primaryColor),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: secondaryColor),
                                      onPressed: () {
                                        setState(() => _query = '');
                                        _loadItems();
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // supplier dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE7E7E7)),
                          ),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                            value: _selectedSupplier, // can be null
                            hint: const Text('Supplier',
                                style: TextStyle(color: textColor)),
                            onChanged: (val) {
                              setState(() => _selectedSupplier = val);
                              _loadItems(); // if server-side; else just setState()
                            },
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All suppliers'),
                              ),
                              ..._supplierSet.map(
                                (s) => DropdownMenuItem<String?>(
                                  value: s,
                                  child: Text(s),
                                ),
                              ),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 4) Products grid (3 columns like the screenshot)
                  Expanded(
                    child: GridView.builder(
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
                        final supplier = _supplierByItemId[it.id] ?? '';

                        return InkWell(
                          onTap: () async {
                            await Navigator.push(
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
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFEFEFEF)),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // product image
                                Expanded(
                                  flex: 6,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: it.imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: imgUrl,
                                            fit: BoxFit.contain,
                                            placeholder: (_, __) => const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.error),
                                          )
                                        : Container(color: Colors.grey[300]),
                                  ),
                                ),
                                // name + supplier + price
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          it.localizedName(context),
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: textColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        if (supplier.isNotEmpty)
                                          Text(
                                            supplier,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textColor.withOpacity(0.6),
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
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
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
                  ),
                ],
              ),
      ),
    );
  }

  String _currentCatName(BuildContext ctx) {
    final c = _cats.firstWhere(
      (e) => e.id == _selectedCatId,
      orElse: () => _CatLite(
          id: -1,
          nameEn: widget.title,
          nameKu: widget.title,
          nameAr: widget.title),
    );
    return c.name(ctx);
  }
}
