// BasketPage to show items in cart
import 'dart:convert';

import 'package:barvin/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});
  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  List<Item> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cart = prefs.getStringList('cart') ?? [];
    setState(() {
      _cartItems = cart.map((e) {
        final m = jsonDecode(e);
        return Item(
          id: int.parse(m['id'].toString()), // parse the ID string
          name: m['name'] as String,
          imageUrl: m['imageUrl'] ?? '',
          price: double.parse(m['price'].toString()), // parse the price string
        );
      }).toList();
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
          backgroundColor: primaryColor),
      body: ListView.builder(
        itemCount: _cartItems.length,
        itemBuilder: (_, idx) {
          final it = _cartItems[idx];
          return ListTile(
            title: Text(it.name),
            subtitle: Text('\$${it.price.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}
