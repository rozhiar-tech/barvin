import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF567765);

class SingleItem extends StatefulWidget {
  final IconData icon;
  final String name;
  final String description;
  final double unitPrice;
  final double discount; // ← new field
  final String imageUrl;

  const SingleItem({
    Key? key,
    required this.icon,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.discount, // ← new
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<SingleItem> createState() => _SingleItemState();
}

class _SingleItemState extends State<SingleItem> {
  int _quantity = 1;

  // calculate the effective unit price after discount
  double get _effectiveUnitPrice {
    if (widget.discount > 0) {
      return widget.unitPrice * (1 - widget.discount / 100);
    }
    return widget.unitPrice;
  }

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

    final itemId = widget.name.hashCode.toString();
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
      });
    }

    final newCartList = cart.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList('cart', newCartList);

    final newQty = idx >= 0
        ? int.tryParse(cart[idx]['quantity'].toString()) ?? _quantity
        : _quantity;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} added to basket (x$newQty)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // ───────────── IMAGE ─────────────
            Container(
              height: 200,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                            child: Icon(widget.icon,
                                size: 80, color: primaryColor)),
                      )
                    : Center(
                        child:
                            Icon(widget.icon, size: 80, color: primaryColor)),
              ),
            ),
            const SizedBox(height: 24),

            // ───────────── PRICE & DISCOUNT ─────────────
            if (widget.discount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\$${widget.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${_effectiveUnitPrice.toStringAsFixed(2)}',
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
                '\$${widget.unitPrice.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ─────────── DESCRIPTION ───────────
            Text(widget.description,
                style: const TextStyle(fontSize: 16, height: 1.4)),
            const SizedBox(height: 24),

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
                          onPressed: _decrement),
                      Text('$_quantity',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.add),
                          color: primaryColor,
                          onPressed: _increment),
                    ],
                  ),
                ),
                Text('\$${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),

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
                child: const Text('Add to Basket',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
