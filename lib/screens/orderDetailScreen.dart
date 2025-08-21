import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF567765);
const String apiBase = 'http://';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        _error = 'Not authenticated';
        _isLoading = false;
      });
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$apiBase/orders/${widget.orderId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _order = jsonDecode(res.body);
        });
      } else {
        setState(() {
          _error = 'Failed to load order (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: primaryColor),
        title:
            const Text('Order Details', style: TextStyle(color: primaryColor)),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order info
                      Text(
                        'Order #${_order!['id']} - ${_order!['placed_at']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Items list
                      Expanded(
                        child: ListView.builder(
                          itemCount: (_order!['orderItems'] as List).length,
                          itemBuilder: (context, index) {
                            final oi = (_order!['orderItems'] as List)[index];
                            final item = oi['item'];
                            final rawQty = oi['quantity'];
                            final qty = rawQty is num
                                ? rawQty.toInt()
                                : int.tryParse(rawQty.toString()) ?? 0;
                            final rawPrice = oi['unit_price'];
                            final price = rawPrice is num
                                ? rawPrice.toDouble()
                                : double.tryParse(rawPrice.toString()) ?? 0.0;
                            final lineTotal = qty * price;
                            return ListTile(
                              title: Text(item['name']),
                              subtitle: Text(
                                '$qty × \$${price.toStringAsFixed(2)}',
                              ),
                              trailing: Text(
                                '\$${lineTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),

                      // Total amount
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '\$${(_order!['total_amount'] as num).toDouble().toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor),
                            ),
                          ],
                        ),
                      ),

                      // Status if exists
                      if (_order!.containsKey('status')) ...[
                        const SizedBox(height: 8),
                        Text('Status: ${_order!['status']}'),
                      ],
                    ],
                  ),
                ),
    );
  }
}
