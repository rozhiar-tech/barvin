import 'dart:async';
import 'dart:convert';

import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/home.dart';
import 'package:barvin/screens/seeMore.dart';
import 'package:barvin/screens/single_item.dart' hide primaryColor;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Category> _catResults = [];
  List<Item> _itemResults = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // listen to every change in the text field
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // cancel any pending timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // start a new one
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _controller.text.trim();
      if (query.isNotEmpty) {
        _doSearch(query);
      } else {
        // clear results if input is empty
        setState(() {
          _catResults = [];
          _itemResults = [];
        });
      }
    });
  }

  Future<void> _doSearch(String query) async {
    setState(() {
      _loading = true;
      _catResults = [];
      _itemResults = [];
    });
    try {
      final res = await http.get(
        Uri.parse('$apiBase/search?q=${Uri.encodeQueryComponent(query)}'),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final cats = (json['categories'] as List<dynamic>)
            .map((j) => Category.fromJson(j as Map<String, dynamic>))
            .toList();
        final items = (json['items'] as List<dynamic>)
            .map((j) => Item.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() {
          _catResults = cats;
          _itemResults = items;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration:
              InputDecoration(hintText: s.typeSearch, border: InputBorder.none),
          textInputAction: TextInputAction.search,
          // you can still trigger onSubmitted once if you like:
          onSubmitted: (_) => _doSearch(_controller.text.trim()),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
              color: primaryColor,
            ))
          : (_catResults.isEmpty && _itemResults.isEmpty)
              ? Center(
                  child: Text(s.newSearch,
                      style: TextStyle(color: Colors.grey.shade600)))
              : ListView(
                  children: [
                    if (_catResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Categories",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._catResults.map((c) => ListTile(
                            leading: const Icon(Icons.category),
                            title: Text(c.localizedName(context)),
                            subtitle: Text(c.items.isNotEmpty
                                ? "${c.items.length} items"
                                : ""),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeeMoreScreen(
                                  title: c.localizedName(context),
                                  items: c
                                      .items, // can be empty; SeeMore will refetch
                                  host: apiBase.replaceAll('/api', ''),
                                  categoryId:
                                      c.id, // ← FIX: was `sec.category.id`
                                ),
                              ),
                            ),
                          )),
                    ],
                    if (_itemResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Items",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._itemResults.map((it) => ListTile(
                            leading: Image.network(
                              "${apiBase.replaceAll('/api', '')}${it.imageUrl}",
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                            title: Text(it.localizedName(context)),
                            subtitle: Text("${it.price.round()} IQD"),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SingleItem(
                                  id: it.id,
                                  icon: Icons.fastfood,
                                  name: it.localizedName(context),
                                  description: it.description,
                                  unitPrice: it.price,
                                  imageUrl:
                                      "${apiBase.replaceAll('/api', '')}${it.imageUrl}",
                                  discount: it.discount,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}
