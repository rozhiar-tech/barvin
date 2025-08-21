import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart' show apiBase;

const Color primaryColor = Color(0xFF567765);

class SingleItem extends StatefulWidget {
  final int id;
  final IconData icon;
  final String name;
  final String description;
  final double unitPrice;
  final double discount; // % off
  final String imageUrl;

  /// NEW: optional supplier (map your API `supplier_name` to this)
  final String? supplierName;

  const SingleItem({
    Key? key,
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.discount,
    required this.imageUrl,
    this.supplierName, // NEW
  }) : super(key: key);

  @override
  State<SingleItem> createState() => _SingleItemState();
}

class _SingleItemState extends State<SingleItem> {
  int _quantity = 1;

  double get _effectiveUnitPrice => widget.discount > 0
      ? widget.unitPrice * (1 - widget.discount / 100)
      : widget.unitPrice;

  double get _totalPrice => _effectiveUnitPrice * _quantity;

  void _increment() => setState(() => _quantity++);
  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Future<void> _addToBasket() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList('cart') ?? [];
    final cart =
        cartList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    final itemId = widget.id.toString();
    final idx = cart.indexWhere((e) => e['id'].toString() == itemId);

    if (idx >= 0) {
      final existing = cart[idx];
      final existingQty = int.tryParse(existing['quantity'].toString()) ?? 0;
      existing['quantity'] = (existingQty + _quantity).toString();
      cart[idx] = existing;
    } else {
      cart.add({
        'id': itemId,
        'name': widget.name,
        'price': widget.unitPrice.toString(),
        'discount': widget.discount.toString(),
        'quantity': _quantity.toString(),
        // (optional) keep for basket UI later:
        'imageUrl': widget.imageUrl,
        'supplierName': widget.supplierName ?? '',
      });
    }

    final newCartList = cart.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList('cart', newCartList);

    final newQty = idx >= 0
        ? int.tryParse(cart[idx]['quantity'].toString()) ?? _quantity
        : _quantity;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.name} added to basket (x$newQty)')),
    );
  }

  String? _supplier; // runtime supplier

  @override
  void initState() {
    super.initState();
    _supplier = (widget.supplierName ?? '').trim();
    if (_supplier!.isEmpty) _loadSupplierFromServer(); // fallback
  }

  Future<void> _loadSupplierFromServer() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/items/${widget.id}'));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        final name =
            (m['supplier_name'] ?? m['supplier'] ?? m['supplierName'] ?? '')
                .toString()
                .trim();
        if (name.isNotEmpty && mounted) setState(() => _supplier = name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'itemImage_${widget.id}';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ───────────── IMAGE (tap to open full screen) ─────────────
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.imageUrl.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _FullscreenImagePage(
                                imageUrl: widget.imageUrl,
                                fallbackIcon: widget.icon,
                                heroTag: heroTag,
                              ),
                            ),
                          );
                        },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: heroTag,
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              fit: BoxFit.fitHeight,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(widget.icon,
                                    size: 80, color: primaryColor),
                              ),
                            )
                          : Center(
                              child: Icon(widget.icon,
                                  size: 80, color: primaryColor),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ───────────── Supplier (if available) ─────────────
            if ((_supplier ?? '').isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, color: primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _supplier!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            // ───────────── PRICE & DISCOUNT ─────────────
            if (widget.discount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.unitPrice.toStringAsFixed(0)} IQD',
                    style: const TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_effectiveUnitPrice.toStringAsFixed(0)} IQD',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${widget.discount.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                '${widget.unitPrice.toStringAsFixed(0)} IQD',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ─────────── DESCRIPTION ───────────
            if (widget.description.trim().isNotEmpty) ...[
              Text(
                widget.description,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],

            // ───────── QUANTITY & LINE TOTAL ─────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: primaryColor,
                        onPressed: _decrement,
                      ),
                      Text('$_quantity',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: primaryColor,
                        onPressed: _increment,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_totalPrice.toStringAsFixed(0)} IQD',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ───────── ADD TO BASKET ─────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addToBasket,
                child: const Text(
                  'Add to Basket',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable image viewer with Hero transition.
class _FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final String heroTag;

  const _FullscreenImagePage({
    Key? key,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 120, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
