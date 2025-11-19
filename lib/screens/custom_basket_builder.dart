import 'dart:convert';

import 'package:barvin/services/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/screens/home.dart'
    show Item, mediaUrlFrom, primaryColor, textColor;

class CustomBasketBuilder extends StatefulWidget {
  const CustomBasketBuilder({Key? key}) : super(key: key);

  @override
  State<CustomBasketBuilder> createState() => _CustomBasketBuilderState();
}

class _CustomBasketBuilderState extends State<CustomBasketBuilder> {
  final Map<int, bool> _selected = {};
  final Map<int, int> _quantities = {};
  List<Item> _items = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = apiUrl('/items', {'all': 'true', 'pageSize': '1000'});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['rows'] is List) {
            data = decoded['rows'];
          } else if (decoded['data'] is List) {
            data = decoded['data'];
          } else {
            data = const [];
          }
        } else {
          data = const [];
        }
        final parsed =
            data.whereType<Map<String, dynamic>>().map(Item.fromJson).toList();
        if (!mounted) return;
        setState(() {
          _items = parsed;
          for (final item in parsed) {
            _quantities[item.id] = 1;
            _selected[item.id] = false;
          }
        });
      } else {
        setState(
            () => _error = 'Failed to load items (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'Unable to load inventory.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Item> get _filteredItems {
    if (_search.trim().isEmpty) return _items;
    final q = _search.trim().toLowerCase();
    return _items.where((item) {
      return item.nameEn.toLowerCase().contains(q) ||
          item.nameKu.toLowerCase().contains(q) ||
          item.nameAr.toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(Item item, bool? value) {
    setState(() {
      _selected[item.id] = value ?? false;
      if (value == true && (_quantities[item.id] ?? 0) == 0) {
        _quantities[item.id] = 1;
      }
    });
  }

  void _increment(Item item) {
    setState(() {
      _selected[item.id] = true;
      _quantities[item.id] = (_quantities[item.id] ?? 1) + 1;
    });
  }

  void _decrement(Item item) {
    setState(() {
      final current = _quantities[item.id] ?? 1;
      final next = (current - 1).clamp(0, current);
      _quantities[item.id] = next;
      if (next == 0) _selected[item.id] = false;
    });
  }

  Future<void> _saveSelection() async {
    final entries = _selected.entries
        .where((e) => e.value)
        .map((e) => (id: e.key, qty: _quantities[e.key] ?? 0))
        .where((pair) => pair.qty > 0)
        .toList();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one item.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartList = prefs.getStringList('cart') ?? [];
      final cart =
          cartList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      for (final entry in entries) {
        final item = _items.firstWhere((it) => it.id == entry.id);
        final idStr = item.id.toString();
        final idx = cart.indexWhere((m) => m['id']?.toString() == idStr);
        final record = {
          'id': idStr,
          'name': item.nameEn.isNotEmpty
              ? item.nameEn
              : (item.nameKu.isNotEmpty ? item.nameKu : item.nameAr),
          'price': item.price.toString(),
          'discount': item.discount.toString(),
          'quantity': entry.qty.toString(),
          'imageUrl': item.imageUrl,
          'supplierName': item.supplier_name,
          'basket_type': 'custom_food_basket',
        };
        if (idx >= 0) {
          final existingQty =
              int.tryParse(cart[idx]['quantity']?.toString() ?? '0') ?? 0;
          record['quantity'] = (existingQty + entry.qty).toString();
          cart[idx] = record;
        } else {
          cart.add(record);
        }
      }

      final updated = cart.map((m) => jsonEncode(m)).toList();
      await prefs.setStringList('cart', updated);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update your basket.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        iconTheme: const IconThemeData(color: primaryColor),
        title: const Text('Create Food Basket',
            style: TextStyle(color: textColor)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search items…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _fetchInventory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _filteredItems.length,
                          itemBuilder: (_, idx) {
                            final item = _filteredItems[idx];
                            final imageUrl = item.imageUrl.isEmpty
                                ? null
                                : mediaUrlFrom(item.imageUrl);
                            final selected = _selected[item.id] ?? false;
                            final qty = _quantities[item.id] ?? 1;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: (val) => _toggle(item, val),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl == null
                                          ? Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image),
                                            )
                                          : Image.network(
                                              imageUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nameEn.isNotEmpty
                                                ? item.nameEn
                                                : (item.nameKu.isNotEmpty
                                                    ? item.nameKu
                                                    : item.nameAr),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                              '${item.price.toStringAsFixed(0)} IQD'),
                                          if (selected)
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.remove_circle),
                                                  onPressed: () =>
                                                      _decrement(item),
                                                ),
                                                Text('$qty'),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.add_circle),
                                                  onPressed: () =>
                                                      _increment(item),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xffFEFAE0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : _saveSelection,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child:
                      Text(_saving ? 'Adding…' : 'Add selected items to cart'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
