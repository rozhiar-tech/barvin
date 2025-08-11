// BasketPage to show items in cart with grouping and order
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/checkout.dart';
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
  double _deliveryFee = 0; // ← was const 2000
  bool _isLoggedIn = false;
  bool _freeDelivery = false;
  bool _isLoadingOrder = false;
  String token = '';
  String apiBase = 'http://95.111.224.58:4000/api';

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadCart();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/settings'));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = m['delivery_fee_iqd'];
        final fee = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '');
        if (fee != null) {
          setState(() => _deliveryFee = fee);
        }
      } else {
        // optional: keep previous _deliveryFee or set a default
        print('Settings load failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('Settings load error: $e');
    }
  }

  Future<void> _checkLoginAndLoadCart() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('loggedIn') ?? false;
    token = prefs.getString('token') ?? '';
    print(token);
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
      final idStr = m['id'].toString();
      final name = m['name'] as String;
      final price = double.tryParse(m['price'].toString()) ?? 0;
      final qty = int.tryParse(m['quantity'].toString()) ?? 1;

      final item = Item(
        id: int.parse(idStr),
        nameEn: name,
        nameKu: name,
        nameAr: name,
        imageUrl: m['imageUrl'] ?? '',
        price: price,
        discount: 0.0,
        description: m['description'] ?? '',
      );

      if (grouped.containsKey(idStr)) {
        // if it’s already in the map, bump the quantity
        grouped[idStr]!.quantity += qty;
      } else {
        grouped[idStr] = CartEntry(item: item, quantity: qty);
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

  Future<void> _updateQuantity(int index, int delta) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      final newQty = _entries[index].quantity + delta;

      if (newQty < 1) {
        // remove the entry entirely
        _entries.removeAt(index);
      } else {
        _entries[index].quantity = newQty;
      }
    });

    // persist back to prefs:
    final cleaned = _entries
        .map((e) => jsonEncode({
              'id': e.item.id.toString(),
              'name': e.item.nameEn,
              'price': e.item.price.toString(),
              'quantity': e.quantity.toString(),
            }))
        .toList();
    await prefs.setStringList('cart', cleaned);
  }

  // ignore: unused_element
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
      print('token is $token');
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
        print(err);
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

  // ignore: unused_element
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
      backgroundColor: Color(0xFFE8F4E8), // soft green
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text('Your Basket', style: TextStyle(color: textColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ─── Item List ────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, idx) {
                  final entry = _entries[idx];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: entry.item.imageUrl.isNotEmpty
                              ? Image.network(entry.item.imageUrl,
                                  width: 64, height: 64, fit: BoxFit.cover)
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[200],
                                  child:
                                      Icon(Icons.fastfood, color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),

                        // title + subtitle + quantity buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.item.localizedName(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 4),
                              Text(entry.item.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 8),

                              // quantity controls
                              Row(
                                children: [
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onTap: () => _updateQuantity(idx, -1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${entry.quantity}',
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    onTap: () => _updateQuantity(idx, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // price + delete
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '${(entry.item.price * entry.quantity).toStringAsFixed(2)} IQD',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () =>
                                  _updateQuantity(idx, -entry.quantity),
                              child: Icon(Icons.delete_forever,
                                  color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ─── Order Summary ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(label: s.subtotal, value: _subtotal),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: s.delivery,
                    value: _freeDelivery ? 0 : _deliveryFee,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: s.total,
                    value: _total,
                    isBold: true,
                    fontSize: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Checkout Button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: canOrder
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CheckoutPage()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round button for “–” and “+”
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Icon(icon, size: 20, color: primaryColor),
      ),
    );
  }
}

/// A single row in the order summary
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final double fontSize;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            )),
        Text('${value.toStringAsFixed(0)} IQD',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            )),
      ],
    );
  }
}
