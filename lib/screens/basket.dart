// BasketPage to show items in cart with grouping and order
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const Color primaryColor = Color(0xFF567765);

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});
  @override
  State<BasketPage> createState() => _BasketPageState();
}

class CartEntry {
  final Item item;
  int quantity;
  CartEntry({required this.item, required this.quantity});
}

class _BasketPageState extends State<BasketPage> {
  List<CartEntry> _entries = [];
  final double _deliveryFee = 2.0;
  bool _isLoggedIn = false;
  bool _freeDelivery = false;
  bool _isLoadingOrder = false;
  String apiBase = 'http://95.111.224.58:4000/api';

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadCart();
  }

  Future<void> _checkLoginAndLoadCart() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('loggedIn') ?? false;
    await _loadCart(); // your existing cart loader
    setState(() {});
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('cart') ?? [];
    final loggedIn = prefs.getBool('loggedIn') ?? false;
    final hasDebt = prefs.getBool('debt') ?? false;

    // Decode & ensure every entry has a quantity
    final raw = rawList.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      m['quantity'] = m.containsKey('quantity') ? m['quantity'] : '1';
      m['id'] = m['id'].toString();
      return m;
    }).toList();
    print(raw);

    // Group by name and sum quantities
    final Map<String, CartEntry> grouped = {};
    for (var m in raw) {
      final name = m['name'] as String;
      final price = double.tryParse(m['price'].toString()) ?? 0;
      final qty = int.tryParse(m['quantity'].toString()) ?? 1;
      final item = Item(
        id: int.parse(m['id']),
        nameEn: name,
        nameKu: name,
        nameAr: name,
        imageUrl: m['imageUrl'] ?? '',
        price: price,
        discount: 0.0,
      );
      if (grouped.containsKey(name)) {
        // grouped[name]!.quantity += qty;
      } else {
        grouped[name] = CartEntry(item: item, quantity: qty);
      }
    }

    // Persist the cleaned, grouped cart
    final cleaned = grouped.values
        .map((e) => jsonEncode({
              'id': e.item.id.toString(),
              'name': e.item.nameEn,
              'price': e.item.price.toString(),
              'quantity': e.quantity.toString(),
            }))
        .toList();
    await prefs.setStringList('cart', cleaned);

    setState(() {
      _entries = grouped.values.toList();
      _isLoggedIn = loggedIn;
      _freeDelivery = hasDebt;
    });
  }

  double get _subtotal =>
      _entries.fold(0.0, (sum, e) => sum + e.item.price * e.quantity);

  double get _total => _subtotal + (_freeDelivery ? 0.0 : _deliveryFee);

  void _updateQuantity(int index, int delta) async {
    setState(() {
      _entries[index].quantity += delta;
      if (_entries[index].quantity < 1) _entries[index].quantity = 1;
    });
    // Optionally persist back to prefs
  }

  Future<void> _sendOrder() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order.')),
      );
      return;
    }

    setState(() => _isLoadingOrder = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // build payload
    final payload = {
      'items': _entries
          .map((e) => {
                'item_id': e.item.id,
                'quantity': e.quantity,
              })
          .toList(),
    };

    try {
      final res = await http.post(
        Uri.parse('$apiBase/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 201) {
        // success!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        // clear cart
        await prefs.remove('cart');
        setState(() {
          _entries.clear();
        });
      } else {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['error'] ?? 'Failed to place order')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error — please try again')),
      );
      print(e);
    } finally {
      setState(() => _isLoadingOrder = false);
    }
  }

  Future<void> _clearBasket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    print('Basket cleared');
    setState(() {
      _entries.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canOrder = _isLoggedIn && !_isLoadingOrder && _entries.isNotEmpty;
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.basket,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await _clearBasket();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.clearBasket)),
              );
            },
            tooltip: 'Clear Basket',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (_, idx) {
                  final entry = _entries[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(entry.item.localizedName(context)),
                      subtitle: Text(
                          '\$${entry.item.price.toStringAsFixed(2)} x ${entry.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _updateQuantity(idx, -1),
                          ),
                          Text('${entry.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _updateQuantity(idx, 1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.delivery, style: TextStyle(fontSize: 16)),
                if (!_freeDelivery)
                  Text('\$${_deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.subtotal, style: TextStyle(fontSize: 16)),
                Text('\$${_subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.total,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // ─── sign-in prompt for guests ───────────────────────────────
            if (!_isLoggedIn)
              Text(
                s.pSignin,
                style: TextStyle(color: Colors.redAccent),
              ),

            const SizedBox(height: 8),
            // ─── send order button ───────────────────────────────────────
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: canOrder ? _sendOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoadingOrder
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    !_isLoggedIn
                        ? s.pSignin2
                        : (_entries.isEmpty ? s.basketEmpty : s.sendOrder),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
