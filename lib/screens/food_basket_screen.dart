import 'dart:convert';

import 'package:barvin/generated/l10n.dart';
import 'package:barvin/models/collections.dart';
import 'package:barvin/screens/custom_basket_builder.dart';
import 'package:barvin/services/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodBasketsScreen extends StatefulWidget {
  final List<FoodBasket> initialBaskets;
  const FoodBasketsScreen({Key? key, this.initialBaskets = const []})
      : super(key: key);

  @override
  State<FoodBasketsScreen> createState() => _FoodBasketsScreenState();
}

class _FoodBasketsScreenState extends State<FoodBasketsScreen> {
  late List<FoodBasket> _baskets;
  bool _loading = false;
  String? _error;
  bool _cartChanged = false;

  @override
  void initState() {
    super.initState();
    _baskets = widget.initialBaskets;
    _fetchBaskets();
  }

  Future<void> _fetchBaskets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(apiUrl('/foodbaskets'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final baskets = data
            .whereType<Map<String, dynamic>>()
            .map(FoodBasket.fromJson)
            .toList();
        setState(() => _baskets = baskets);
      } else {
        setState(
            () => _error = 'Failed to load baskets (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load baskets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _cartChanged);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xffD3E4C4),
        appBar: AppBar(
          backgroundColor: const Color(0xffFEFAE0),
          iconTheme: const IconThemeData(color: Color(0xFF567765)),
          title: Text(s.foodBasketSectionTitle,
              style: const TextStyle(color: Colors.black87)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _cartChanged),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchBaskets,
          child: _loading && _baskets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _baskets.length + 1 + (_error != null ? 1 : 0),
                  itemBuilder: (_, idx) {
                    if (idx == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomBasketBuilder(),
                                ),
                              );
                              if (changed == true) {
                                setState(() => _cartChanged = true);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Added custom basket items to cart.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(s.createBasketCardTitle),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF567765),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    final dataIndex = idx - 1;

                    if (_error != null && dataIndex == _baskets.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final basket = _baskets[dataIndex];
                    final imageUrl = basket.primaryImage == null
                        ? null
                        : mediaUrlFrom(basket.primaryImage!);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: const Color(0xffFEFAE0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl == null
                                      ? Container(
                                          width: 90,
                                          height: 90,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            width: 90,
                                            height: 90,
                                            alignment: Alignment.center,
                                            child:
                                                const CircularProgressIndicator(),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey.shade200,
                                            child:
                                                const Icon(Icons.broken_image),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        basket.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        basket.description.isNotEmpty
                                            ? basket.description
                                            : s.presetBasketDescription,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${basket.price.toStringAsFixed(0)} IQD',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Includes ${basket.items.length} items'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FoodBasketDetailPage(
                                      basket: basket,
                                    ),
                                  ),
                                );
                                if (changed == true) {
                                  setState(() => _cartChanged = true);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Basket items added to your cart.'),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF567765),
                              ),
                              child: Text(s.foodBasketCustomizeCta),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class FoodBasketDetailPage extends StatefulWidget {
  final FoodBasket basket;
  const FoodBasketDetailPage({Key? key, required this.basket})
      : super(key: key);

  @override
  State<FoodBasketDetailPage> createState() => _FoodBasketDetailPageState();
}

class _FoodBasketDetailPageState extends State<FoodBasketDetailPage> {
  late Map<int, int> _quantities;
  late Map<int, bool> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantities = {
      for (final item in widget.basket.items)
        item.itemId: item.defaultQuantity > 0 ? item.defaultQuantity : 1
    };
    _selected = {
      for (final item in widget.basket.items)
        item.itemId: (item.defaultQuantity > 0)
    };
  }

  double get _estimatedTotal {
    double total = 0;
    for (final item in widget.basket.items) {
      final qty =
          _selected[item.itemId] == true ? _quantities[item.itemId]! : 0;
      total += qty * item.price;
    }
    return total;
  }

  void _increment(FoodBasketProduct item) {
    setState(() {
      _selected[item.itemId] = true;
      _quantities[item.itemId] = (_quantities[item.itemId] ?? 1) + 1;
    });
  }

  void _decrement(FoodBasketProduct item) {
    setState(() {
      final current = _quantities[item.itemId] ?? 1;
      final next = (current - 1).clamp(0, current);
      _quantities[item.itemId] = next;
      if (next == 0) _selected[item.itemId] = false;
    });
  }

  Future<void> _saveSelection() async {
    final entries = _quantities.entries
        .where((entry) => _selected[entry.key] == true && entry.value > 0)
        .toList();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item.')),
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
        final product = widget.basket.items
            .firstWhere((element) => element.itemId == entry.key);
        final idStr = product.itemId.toString();
        final idx = cart.indexWhere((m) => m['id']?.toString() == idStr);
        final baseRecord = {
          'id': idStr,
          'name': product.nameEn.isNotEmpty
              ? product.nameEn
              : (product.nameKu.isNotEmpty ? product.nameKu : product.nameAr),
          'price': product.price.toString(),
          'discount': '0',
          'quantity': entry.value.toString(),
          'imageUrl': product.imageUrl,
          'supplierName': '',
          'basket_type': 'food_basket',
          'basket_id': widget.basket.id,
        };

        if (idx >= 0) {
          final existing = cart[idx];
          final existingQty =
              int.tryParse(existing['quantity'].toString()) ?? 0;
          baseRecord['quantity'] = (existingQty + entry.value).toString();
          cart[idx] = baseRecord;
        } else {
          cart.add(baseRecord);
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
        iconTheme: const IconThemeData(color: Color(0xFF567765)),
        title: Text(widget.basket.name,
            style: const TextStyle(color: Colors.black87)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: widget.basket.items.length,
              itemBuilder: (_, idx) {
                final item = widget.basket.items[idx];
                final selected = _selected[item.itemId] ?? false;
                final qty = _quantities[item.itemId] ?? 0;
                final imageUrl =
                    item.imageUrl.isEmpty ? null : mediaUrlFrom(item.imageUrl);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (val) {
                            setState(() {
                              _selected[item.itemId] = val ?? false;
                              if (val == true && qty == 0) {
                                _quantities[item.itemId] = 1;
                              }
                            });
                          },
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl == null
                              ? Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image),
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.localizedName(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${item.price.toStringAsFixed(0)} IQD'),
                              if (selected)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle),
                                      onPressed: () => _decrement(item),
                                    ),
                                    Text('$qty'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      onPressed: () => _increment(item),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xffFEFAE0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Estimated total: ${_estimatedTotal.toStringAsFixed(0)} IQD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF567765),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_saving ? 'Adding…' : 'Add items to basket'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
