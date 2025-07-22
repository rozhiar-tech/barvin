import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

extension StringCap on String {
  String capitalize() => isEmpty ? '' : this[0].toUpperCase() + substring(1);
}

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
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoggedIn = true);
      await _fetchOrders(token);
    }
  }

  Future<void> _fetchOrders(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/orders/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;

        final orders = data
            .map<Map<String, dynamic>>((raw) {
              // pull out the order ID
              final idNum = raw['id'];
              final int id = idNum is int
                  ? idNum
                  : idNum is String
                      ? int.tryParse(idNum) ?? 0
                      : 0;

              // placed_at might be a string
              final date = raw['placed_at']?.toString() ?? '—';
              final status = raw['status'].toString();

              // count up quantities
              final itemsList = raw['orderItems'] as List<dynamic>? ?? [];
              final int itemCount = itemsList.fold<int>(0, (sum, itm) {
                final q = itm['quantity'];
                if (q is int) return sum + q;
                if (q is String) return sum + (int.tryParse(q) ?? 0);
                return sum;
              });

              // total_amount
              final amtRaw = raw['total_amount'];
              final double amount = amtRaw is num
                  ? amtRaw.toDouble()
                  : double.tryParse(amtRaw?.toString() ?? '') ?? 0.0;

              return {
                'id': id,
                'date': date,
                'items': itemCount,
                'amount': amount,
                'status': status,
              };
            })
            .where((o) => o['id'] != 0)
            .toList(); // drop any invalid

        setState(() {
          _orders = orders;
        });
      } else {
        // you could show an error SnackBar here
      }
    } catch (e) {
      // network or JSON error
      print('Fetch orders failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _totalSpent =>
      _orders.fold(0.0, (sum, o) => sum + (o['amount'] as double));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 234, 236, 234),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 234, 236, 234),
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          s.yourOrders,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
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
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      s.singInOrder,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Total Spent ─────────────────────
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.totalSpent,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              Text('\$${_totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Order List ──────────────────────
                      Expanded(
                        child: _orders.isEmpty
                            ? Center(child: Text(s.noOrder))
                            : ListView.separated(
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final order = _orders[idx];
                                  final statusRaw =
                                      (order['status'] as String).toLowerCase();

                                  // helper to pick a colour based on status
                                  final statusColor = {
                                        'pending': Colors.orange,
                                        'shipped': Colors.blue,
                                        'delivered': Colors.green,
                                      }[statusRaw] ??
                                      Colors.grey;

                                  // Inside your itemBuilder:
                                  final raw = order['date'] as String;
                                  DateTime dt = DateTime.parse(raw);

                                  String pretty =
                                      DateFormat.yMMMMd('en').format(dt);
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
                                        child: Icon(Icons.receipt_long,
                                            color: primaryColor),
                                      ),
                                      title: Text(
                                        '${s.orderOn} $pretty',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                          '${order['items']} items — \$${(order['amount'] as double).toStringAsFixed(2)}'),
                                      trailing: Chip(
                                        label: Text(
                                          statusRaw.capitalize(),
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor:
                                            statusColor.withOpacity(0.15),
                                      ),
                                      onTap: () {
                                        // now order['id'] is guaranteed non-null
                                        // Navigator.pushNamed(
                                        //   context,
                                        //   '/orderDetail',
                                        //   arguments: order['id'] as int,
                                        // );
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
