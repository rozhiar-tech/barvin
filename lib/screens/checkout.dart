// lib/screens/checkout.dart
import 'dart:convert';

import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/basket.dart';
import 'package:barvin/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const Color primaryColor = Color(0xFF567765);

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _address;
  String? _lat;
  String? _lng;
  bool _cashOnDelivery = true;
  List<_CartEntry> _cart = [];
  final double _deliveryFee = 2000;
  final double _taxRate = 0.02;
  bool _isLoadingOrder = false;
  bool _isLoggedIn = false;
  String token = '';
  List<CartEntry> _entries = [];
  String apiBase = 'http://95.111.224.58:4000/api';
  bool _freeDelivery = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _checkLoginAndLoadCart();
  }

  Future<void> _checkLoginAndLoadCart() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('loggedIn') ?? false;
    token = prefs.getString('token') ?? '';
    await _loadCart(); // your existing cart loader

    print(token);
    setState(() {});
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
        description: m['description'] ?? '',
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

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _address = prefs.getString('userAddress') ?? '(no address)';
      _lat = prefs.getString('latitude') ?? '';
      _lng = prefs.getString('longitude') ?? '';
    });
    final raw = prefs.getStringList('cart') ?? [];
    final list = raw.map((e) => jsonDecode(e) as Map<String, dynamic>);
    setState(() {
      _cart = list.map((m) {
        final price = double.tryParse(m['price'].toString()) ?? 0;
        final qty = int.tryParse(m['quantity'].toString()) ?? 1;
        return _CartEntry(
          id: m['id'],
          name: m['name'],
          price: price,
          quantity: qty,
        );
      }).toList();
    });
  }

  double get _subtotal => _cart.fold(0, (sum, e) => sum + e.price * e.quantity);

  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _deliveryFee + _tax;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('s.checkout'),
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ───────── Delivery Information ─────────
          Text('s.deliveryInformation',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              // push to add-new screen
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddAddressPage()),
              );
              if (ok == true) _loadAll();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE8F4E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _address != null && _address!.isNotEmpty
                          ? '$_address\n($_lat, $_lng)'
                          : 's.addNewAddress',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ───────── Payment Method ─────────
          Text('s.paymentMethod',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            groupValue: _cashOnDelivery,
            onChanged: (_) => setState(() => _cashOnDelivery = true),
            title: Text('s.cashOnDelivery'),
            secondary: const Icon(Icons.money),
          ),
          const SizedBox(height: 24),

          // ───────── Review Basket ─────────
          Text('s.reviewBasket',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._cart.map((e) => _buildLineItem(e)).toList(),

          const SizedBox(height: 16),
          // ───────── Order Summary ─────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _summaryRow(
                      s.subtotal, '${_subtotal.toStringAsFixed(0)} IQD'),
                  const SizedBox(height: 4),
                  _summaryRow(' s.deliveryFee',
                      '${_deliveryFee.toStringAsFixed(0)} IQD'),
                  const SizedBox(height: 4),
                  const Divider(height: 20),
                  _summaryRow(s.total, '${_total.toStringAsFixed(0)} IQD',
                      isTotal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ───────── Place Order ─────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _cart.isEmpty
                  ? null
                  : () {
                      // TODO: actually place order...
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('s.orderPlaced')),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                '${'s.placeOrder'} – ${_total.toStringAsFixed(0)} IQD',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(_CartEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // placeholder icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fastfood, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${e.quantity} x ${e.price.toStringAsFixed(0)} IQD',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${(e.price * e.quantity).toStringAsFixed(0)} IQD'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      );
}

class _CartEntry {
  final dynamic id;
  final String name;
  final double price;
  final int quantity;
  _CartEntry(
      {required this.id,
      required this.name,
      required this.price,
      required this.quantity});
}

// -----------------------------------------------------------------------------
// lib/screens/add_address.dart
// -----------------------------------------------------------------------------
class AddAddressPage extends StatefulWidget {
  const AddAddressPage({Key? key}) : super(key: key);
  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addrCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAddress', _addrCtrl.text.trim());
    await prefs.setString('latitude', _latCtrl.text.trim());
    await prefs.setString('longitude', _lngCtrl.text.trim());
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('s.addNewAddress'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _addrCtrl,
                decoration: InputDecoration(labelText: 's.address'),
                validator: (v) =>
                    v == null || v.isEmpty ? 's.requiredField' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _latCtrl,
                decoration: InputDecoration(labelText: 's.latitude'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 's.requiredField' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lngCtrl,
                decoration: InputDecoration(labelText: 's.longitude'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 's.requiredField' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('s.save',
                          style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
