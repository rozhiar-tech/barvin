// BasketPage to show items in cart with grouping and order
import 'dart:convert';
import 'package:barvin/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _freeDelivery = false;
  final double _deliveryFee = 2.0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('cart') ?? [];

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
        name: name,
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
              'name': e.item.name,
              'price': e.item.price.toString(),
              'quantity': e.quantity.toString(),
            }))
        .toList();
    await prefs.setStringList('cart', cleaned);

    setState(() {
      _entries = grouped.values.toList();
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
    // TODO: integrate with API order endpoint
    // For now just clear cart
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Order sent!')));
    setState(() {
      _entries.clear();
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Basket',
          style: TextStyle(
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
                const SnackBar(content: Text('Basket cleared')),
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
                      title: Text(entry.item.name),
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
                const Text('Delivery', style: TextStyle(fontSize: 16)),
                // Switch(
                //   value: _freeDelivery,
                //   onChanged: (v) => setState(() => _freeDelivery = v),
                // ),
                if (!_freeDelivery)
                  Text('\$${_deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 16)),
                Text('\$${_subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _entries.isEmpty ? null : _sendOrder,
                child: const Text('Send Order',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
