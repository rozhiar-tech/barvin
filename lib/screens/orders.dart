import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF567765);
const String apiBase = 'http://95.111.224.58:4000/api';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
  }

  Future<void> _checkLoginAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoggedIn = true);
      await _fetchOrders(userId);
    }
  }

  Future<void> _fetchOrders(int userId) async {
    try {
      final res = await http.get(Uri.parse('$apiBase/orders?userId=$userId'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _orders = data
              .map((o) => {
                    'date': o['date'],
                    'items': o['items_count'],
                    'amount': o['total_amount'],
                  })
              .toList();
        });
      } else {
        // handle API error
      }
    } catch (e) {
      // handle network error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _totalSpent =>
      _orders.fold(0.0, (sum, order) => sum + (order['amount'] as double));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: const Text(
          'Your Orders',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isLoggedIn
              ? Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'Sign In to View Orders',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total spent summary
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Spent',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '\$${_totalSpent.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Past orders list
                      Expanded(
                        child: _orders.isEmpty
                            ? const Center(child: Text('No orders found.'))
                            : ListView.separated(
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            primaryColor.withOpacity(0.1),
                                        child: Icon(
                                          Icons.receipt_long,
                                          color: primaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        'Order on ${order['date']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                          '${order['items']} items — \$${(order['amount'] as double).toStringAsFixed(2)}'),
                                      trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16),
                                      onTap: () {
                                        // TODO: Navigate to order detail
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
