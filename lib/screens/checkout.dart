// lib/screens/checkout.dart

// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/add_address.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/screens/home.dart' show apiBase;
import 'package:barvin/constants/app_constants.dart';
import 'package:barvin/services/api_client.dart';

const Color primaryColor = AppColors.primary;

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
  double _deliveryFee = 0; // ← from /settings

  final double _taxRate = 0.02;
  bool _isSending = false;
  bool _loggedIn = false;
// at top of _CheckoutPageState
  String _normalizeImageUrl(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith('http')) return raw;
    final base = apiBase.replaceAll('/api', ''); // http://95.111.224.58:4000
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$base/$path';
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient.instance.get(
        AppEndpoints.settings,
        requiresAuth: false,
      );
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = m['delivery_fee_iqd'];
      final fee = raw is num
          ? raw.toDouble()
          : double.tryParse(raw?.toString() ?? '');
      if (fee != null) {
        setState(() => _deliveryFee = fee);
      }
    } on ApiException catch (e) {
      debugPrint('Settings load failed: ${e.message}');
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedIn = prefs.getBool('loggedIn') ?? false;
      _address = prefs.getString('userAddress') ?? '';
      _lat = prefs.getString('latitude') ?? '';
      _lng = prefs.getString('longitude') ?? '';
    });

    // in _loadPrefs(), where you build _cart
    final raw = prefs.getStringList('cart') ?? [];
    final list = raw.map((e) => jsonDecode(e) as Map<String, dynamic>);
    setState(() {
      _cart = list.map((m) {
        final price = double.tryParse(m['price'].toString()) ?? 0;
        final qty = int.tryParse(m['quantity'].toString()) ?? 1;
        final img = (m['imageUrl'] ?? '').toString();
        final basketType = m['basket_type']?.toString();
        final basketId = m['basket_id'] == null
            ? null
            : int.tryParse(m['basket_id'].toString());
        return _CartEntry(
          id: m['id'],
          name: m['name'],
          price: price,
          quantity: qty,
          imageUrl: img,
          basketType: basketType,
          basketId: basketId,
        );
      }).toList();
    });
  }

  double get _subtotal => _cart.fold(0, (sum, e) => sum + e.price * e.quantity);
  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _deliveryFee + _tax;

  String? _deriveOrderType() {
    if (_cart.any((e) => e.basketType == 'custom_food_basket')) {
      return 'custom_food_basket';
    }
    if (_cart.any((e) => e.basketType == 'food_basket')) {
      return 'food_basket';
    }
    return null;
  }

  String? _basketBadge(String? type) {
    switch (type) {
      case 'custom_food_basket':
        return 'Custom basket';
      case 'food_basket':
        return 'Food basket';
      default:
        return null;
    }
  }

  Future<void> _placeOrder() async {
    if (!_loggedIn || _isSending || _cart.isEmpty) return;
    setState(() => _isSending = true);

    final Map<String, dynamic> payload = {
      'items': _cart
          .map((e) => {
                'item_id': e.id,
                'quantity': e.quantity,
              })
          .toList(),
    };

    final orderType = _deriveOrderType();
    if (orderType != null) {
      payload['order_type'] = orderType;
    }

    try {
      await ApiClient.instance.post(
        AppEndpoints.orders,
        body: jsonEncode(payload),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (Route<dynamic> route) => false,
      );
    } on ApiException catch (e) {
      final message = e.message ?? 'Failed to place order';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error – please try again')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final address =
        (_address?.isNotEmpty == true) ? _address : "no address yet";
    final lat = _lat ?? '';
    final lng = _lng ?? '';
    return Scaffold(
      backgroundColor: Color(0xffD3E4C4),
      appBar: AppBar(
        title: Text(s.checkout, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Delivery Info
          Text(s.deliveryInformation,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddAddressPage()),
              );
              if (updated == true) _loadPrefs();
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
                      address!.contains('\n')
                          ? '$address\n($lat, $lng)'
                          : address,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment
          Text(s.paymentMethod,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            groupValue: _cashOnDelivery,
            onChanged: (_) => setState(() => _cashOnDelivery = true),
            title: Text(s.cashOnDelivery),
            secondary: const Icon(Icons.money),
          ),
          const SizedBox(height: 24),

          // Review Basket
          Text(s.reviewBasket,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._cart.map(_buildLineItem),

          const SizedBox(height: 16),
          // Summary
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _summaryRow(s.subtotal, '${_subtotal.toStringAsFixed(0)} IQD'),
                const SizedBox(height: 4),
                _summaryRow(
                    s.deliveryFee, '${_deliveryFee.toStringAsFixed(0)} IQD'),
                const Divider(height: 20),
                _summaryRow(s.total, '${_total.toStringAsFixed(0)} IQD',
                    isTotal: true),
              ]),
            ),
          ),

          const SizedBox(height: 24),
          // Place Order
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_cart.isEmpty || _isSending) ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      '${s.placeOrder} — ${_total.toStringAsFixed(0)} IQD',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(_CartEntry e) {
    final thumb = _normalizeImageUrl(e.imageUrl); // 👈 normalize
    final badge = _basketBadge(e.basketType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: thumb.isNotEmpty
              ? Image.network(
                  thumb,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.green.shade50,
                    child: const Icon(Icons.fastfood, color: Colors.green),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: Colors.green.shade50,
                  child: const Icon(Icons.fastfood, color: Colors.green),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${e.quantity} x ${e.price.toStringAsFixed(0)} IQD',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text('${(e.price * e.quantity).toStringAsFixed(0)} IQD'),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
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
}

class _CartEntry {
  final dynamic id;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl; // 👈 new
  final String? basketType;
  final int? basketId;

  _CartEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.basketType,
    this.basketId,
  });
}
