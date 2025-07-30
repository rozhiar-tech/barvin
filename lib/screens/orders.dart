import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFF567765);
const String apiBase = 'http://95.111.224.58:4000/api';

extension StringCap on String {
  String capitalize() => isEmpty ? '' : this[0].toUpperCase() + substring(1);
}

class Orders extends StatefulWidget {
  const Orders({Key? key}) : super(key: key);

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  bool _loading = true;
  bool _loggedIn = false;
  String? _token;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('token');
    if (t == null) {
      setState(() {
        _loggedIn = false;
        _loading = false;
      });
    } else {
      setState(() {
        _loggedIn = true;
        _token = t;
      });
      await _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/orders/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        final list = <Map<String, dynamic>>[];
        for (var raw in data) {
          final idNum = raw['id'];
          final id = idNum is int ? idNum : int.tryParse(idNum.toString()) ?? 0;
          final dateStr = raw['placed_at']?.toString() ?? '';
          final status = raw['status']?.toString().toLowerCase() ?? 'pending';

          // collect item names
          final items = <String>[];
          final rawItems = raw['orderItems'] as List<dynamic>? ?? [];
          for (var oi in rawItems) {
            final name = oi['item']?['name']?.toString() ?? '';
            if (name.isNotEmpty) items.add(name);
          }

          // total amount
          final amtRaw = raw['total_amount'];
          final total = amtRaw is num
              ? amtRaw.toDouble()
              : double.tryParse(amtRaw.toString()) ?? 0.0;

          list.add({
            'id': id,
            'date': dateStr,
            'status': status,
            'names': items,
            'total': total,
          });
        }
        setState(() => _orders = list);
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTab(String status) {
    final filtered = _orders.where((o) => o['status'] == status).toList();
    if (filtered.isEmpty) {
      return Center(child: Text('No ${status.capitalize()} orders'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, idx) {
        final o = filtered[idx];
        final dt = DateTime.tryParse(o['date']) ?? DateTime.now();
        final dateLabel = DateFormat.yMMMd().format(dt);
        final id = o['id'] as int;
        final names = List<String>.from(o['names']);
        final summary = names.length <= 2
            ? names.join(', ')
            : '${names[0]}, ${names[1]} +${names.length - 2} more';
        final color = {
          'pending': Colors.orange,
          'ordered': primaryColor,
          'completed': Colors.green,
        }[status]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // date + badge
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dateLabel,
                          style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.capitalize(),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // order #
                  Text('#ORD-${id.toString().padLeft(4, '0')}',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  // items summary
                  Text(summary, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  // total amount
                  Text('Total: ${o['total'].toStringAsFixed(0)} IQD',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_loggedIn) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Sign in to view orders'),
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6F0),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(color: primaryColor),
          title: Text('My Orders',
              style:
                  TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Ordered'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTab('pending'),
            _buildTab('ordered'),
            _buildTab('completed'),
          ],
        ),
      ),
    );
  }
}
