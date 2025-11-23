import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/order_receipt.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart' show apiBase;

const Color primaryColor = Color(0xFF567765);

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

      final decoded = jsonDecode(res.body);
      final List<dynamic> dataList = decoded is List
          ? decoded
          : decoded['data'] is List
              ? decoded['data'] as List
              : [];

      final list = <Map<String, dynamic>>[];
      for (var raw in dataList) {
        final idNum = raw['id'];
        final id =
            idNum is int ? idNum : int.tryParse((idNum ?? '').toString()) ?? 0;

        final dateStr = raw['placed_at']?.toString() ?? '';
        final status = (raw['status']?.toString() ?? 'pending').toLowerCase();

        final names = <String>[];
        if (raw['orderItems'] is List) {
          for (var oi in raw['orderItems']) {
            final name = oi['item']?['name']?.toString() ?? '';
            if (name.isNotEmpty) names.add(name);
          }
        }

        final amtRaw = raw['total_amount'];
        final total = amtRaw is num
            ? amtRaw.toDouble()
            : double.tryParse(amtRaw?.toString() ?? '') ?? 0.0;

        list.add({
          'id': id,
          'date': dateStr,
          'status': status,
          'names': names,
          'total': total,
        });
      }

      setState(() {
        _orders = list;
      });
    } catch (_) {
      // swallow; UI shows empty state
    } finally {
      setState(() => _loading = false);
    }
  }

  String _statusLabel(String apiStatus, S s) {
    switch (apiStatus.toLowerCase()) {
      case 'pending':
        return s.status_pending;
      case 'delivered':
        return s.status_delivered;
      case 'ordered':
        return s.tab_ordered; // optional if you use this status
      default:
        return apiStatus.capitalize();
    }
  }

  Widget _buildTab(String status) {
    final s = S.of(context);

    final filtered = status == 'all'
        ? _orders
        : _orders.where((o) => o['status'] == status).toList();

    if (filtered.isEmpty) {
      final label = status == 'all'
          ? s.orders_empty_all
          : s.orders_empty_status(_statusLabel(status, s));
      return Center(child: Text(label));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, idx) {
        final o = filtered[idx];
        final dt = DateTime.tryParse(o['date']) ?? DateTime.now();
        final dateLabel =
            MaterialLocalizations.of(context).formatMediumDate(dt);
        final id = o['id'] as int;
        final names = List<String>.from(o['names']);
        final summary = names.length <= 2
            ? names.join(', ')
            : '${names[0]}, ${names[1]} +${names.length - 2} more';

        final statusForBadge =
            (status == 'all' ? (o['status'] as String) : status);
        final statusText = _statusLabel(statusForBadge, s);

        final statusColor = {
              'pending': Colors.orange,
              'all': primaryColor,
              'delivered': Colors.green,
            }[statusForBadge.toLowerCase()] ??
            Colors.grey;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderReceiptPage(orderId: id),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
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
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // order number
                    Text(
                      '${s.order_number_prefix}${id.toString().padLeft(4, '0')}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    // items summary
                    Text(summary, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    // total amount
                    Text(
                      '${s.total_label} ${o['total'].toStringAsFixed(0)} ${s.currency_code_iqd}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_loggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xffD3E4C4),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text(
              s.singInOrder,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFD3E4C4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            s.my_orders_title,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: s.tab_pending),
              Tab(text: s.tab_ordered),
              Tab(text: s.tab_delivered),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTab('pending'),
            _buildTab('all'),
            _buildTab('delivered'),
          ],
        ),
      ),
    );
  }
}
