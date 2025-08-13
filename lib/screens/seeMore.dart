// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'package:barvin/screens/home.dart';
import 'package:barvin/screens/single_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ← add
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF567765);

class SeeMoreScreen extends StatefulWidget {
  final String title;
  final List<Item> items; // initial items (optional)
  final String host; // e.g. http://95.111.224.58:4000
  final int categoryId; // ← NEW

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

// simple subcategory model here to keep file self-contained
class Subcategory {
  final int id;
  final String nameEn, nameKu, nameAr;
  Subcategory({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
  });
  factory Subcategory.fromJson(Map<String, dynamic> j) => Subcategory(
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

// ignore: unused_element
int _cartCount = 0;

class _SeeMoreScreenState extends State<SeeMoreScreen> {
  // API base computed from host
  String get _apiBase => '${widget.host}/api';

  // subcategory filter state
  List<Subcategory> _subs = [];
  int? _selectedSubId; // null => All
  String _query = '';
  Timer? _debounce;

  // items to render (we'll start with the passed items, then replace with fetched)
  List<Item> _items = [];
  bool _loading = true;

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('cart') ?? [];
    setState(() => _cartCount = items.length);
  }

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    _initLoad();
  }

  Future<void> _initLoad() async {
    setState(() => _loading = true);
    await Future.wait([_loadSubcategories(), _loadItems()]);
    setState(() => _loading = false);
  }

  Future<void> _loadSubcategories() async {
    try {
      // Prefer categories/:id/subcategories (shown only by default)
      final uri1 =
          Uri.parse('$_apiBase/categories/${widget.categoryId}/subcategories');

      http.Response res;
      try {
        res = await http.get(uri1);
      } catch (_) {
        // Fallback: /subcategories?categoryId=... (if you implemented this)
        final uri2 = Uri.parse(
            '$_apiBase/subcategories?categoryId=${widget.categoryId}');
        res = await http.get(uri2);
      }

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((m) => Subcategory.fromJson(m))
            .toList();
        setState(() => _subs = list);
      } else {
        setState(() => _subs = []);
      }
    } catch (e) {
      setState(() => _subs = []);
    }
  }

  Future<void> _loadItems() async {
    try {
      final params = <String, String>{
        'categoryId': widget.categoryId.toString(),
        'shown': 'true', // mobile shows only visible items
      };
      if (_selectedSubId != null) {
        params['subcategoryId'] = _selectedSubId.toString();
      }
      if (_query.trim().isNotEmpty) {
        params['q'] = _query.trim();
      }

      final uri = Uri.parse('$_apiBase/items').replace(queryParameters: params);
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rows = body is List ? body : (body['rows'] ?? []);
        final parsed = rows
            .map<Item>((m) => Item.fromJson(m as Map<String, dynamic>))
            .toList();
        setState(() => _items = parsed);
      }
    } catch (e) {
      // keep previous _items if request fails
    }
  }

  void _onSearchChanged(String v) {
    _query = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadItems);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ChoiceChip(
        label: const Text('All'),
        selected: _selectedSubId == null,
        onSelected: (sel) {
          if (!sel) return;
          setState(() => _selectedSubId = null);
          _loadItems();
        },
      ),
      ..._subs.map((s) => ChoiceChip(
            label: Text(s.localizedName(context)),
            selected: _selectedSubId == s.id,
            onSelected: (sel) {
              if (!sel) return;
              setState(() => _selectedSubId = s.id);
              _loadItems();
            },
          )),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Search within this category
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search in ${widget.title}…',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: primaryColor),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 10),

                    // Subcategory chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chips,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items grid
                    Expanded(
                      child: GridView.builder(
                        itemCount: _items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.55,
                        ),
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          final rawPath = it.imageUrl.startsWith('/')
                              ? it.imageUrl.substring(1)
                              : it.imageUrl;
                          final imgUrl = '${widget.host}/$rawPath';

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
                              _loadCartCount();
                            },
                            child: Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: AspectRatio(
                                aspectRatio: 0.6,
                                child: Column(
                                  children: [
                                    // image
                                    Expanded(
                                      flex: 6,
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        child: it.imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imgUrl,
                                                placeholder: (_, __) =>
                                                    const Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                errorWidget: (_, __, ___) =>
                                                    const Icon(Icons.error),
                                              )
                                            : Container(
                                                color: Colors.grey[300]),
                                      ),
                                    ),
                                    // text & price
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              it.localizedName(context),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                            if (it.description.isNotEmpty)
                                              Text(
                                                it.description,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
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
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          '${(it.price * (1 - it.discount / 100)).round()} IQD',
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      '${it.price.round()} IQD',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
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
                  ],
                ),
        ),
      ),
    );
  }
}
