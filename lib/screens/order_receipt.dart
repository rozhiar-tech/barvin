// lib/screens/order_receipt.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barvin/constants/app_constants.dart';
import 'package:barvin/constants/contact.dart';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/services/api_client.dart';
import 'package:barvin/services/token_storage.dart';

const Color primaryColor = AppColors.primary;

class OrderReceiptPage extends StatefulWidget {
  final int orderId;
  const OrderReceiptPage({super.key, required this.orderId});

  @override
  State<OrderReceiptPage> createState() => _OrderReceiptPageState();
}

class _OrderReceiptPageState extends State<OrderReceiptPage> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  // Company block (match your dashboard)
  static const _COMPANY = {
    'enName': 'Barvin',
    'enTag': 'For General Trading & Commercial Agencies Ltd.',
    'kuName': 'بارڤین',
    'kuTag': '''
بۆ دابیکردن و گەیاندنی
خوادرن و خواردنەوەکان و بەهارات
سەوزە و میوە و موادی سەفەری
ناونیشان / هەولێر''',
    'city': 'Erbil',
    'phones': [kSupportPhone1, kSupportPhone2, kSupportPhone3],
    'currency': 'IQD',
  };

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final token = await TokenStorage.read();
    if (token == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to view receipt')),
      );
      return;
    }
    await _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    try {
      final res = await ApiClient.instance.get(
        '${AppEndpoints.orders}/${widget.orderId}',
      );
      setState(() {
        _order = jsonDecode(res.body) as Map<String, dynamic>;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to load order')),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error — please try again')),
      );
    }
  }

  String _fmtNum(num? n) => (n ?? 0).toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          'Receipt #${widget.orderId}',
          style:
              const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6ECE8)),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildReceipt(context, order),
                    ),
                  ),
                ),
    );
  }

  Widget _buildReceipt(BuildContext context, Map<String, dynamic> o) {
    final s = S.of(context);
    // rows
    final items = (o['orderItems'] as List? ?? []);
    final rows = items.map<Map<String, dynamic>>((oi) {
      final item = (oi['item'] as Map?) ?? {};
      final code = '${item['id'] ?? ''}'.padLeft(6, '0');
      final name = (item['name'] ?? '').toString();
      final qty = num.tryParse('${oi['quantity'] ?? 0}') ?? 0;
      final unit = num.tryParse('${oi['unit_price'] ?? 0}') ?? 0;
      return {
        'code': code,
        'name': name,
        'qty': qty,
        'unit': unit,
        'total': qty * unit,
      };
    }).toList();

    final subtotal = rows.fold<num>(0, (s, r) => s + (r['total'] as num));
    final delivery = num.tryParse('${o['delivery_fee'] ?? 0}') ?? 0;
    final labor = num.tryParse('${o['labor_cost'] ?? 0}') ?? 0;
    final discount = num.tryParse('${o['order_discount'] ?? 0}') ?? 0;
    final grand = subtotal + delivery + labor - discount;
    final currency = (o['currency'] ?? _COMPANY['currency']).toString();
    final placedAt = (o['placed_at'] ?? '').toString();

    // letterhead
    final phones = List<String>.from(_COMPANY['phones'] as List);

    final letterhead = LayoutBuilder(
      builder: (_, c) {
        final narrow = c.maxWidth < 380;
        final logoSize = narrow ? 84.0 : 110.0;

        Widget phoneChip(String p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                label: Directionality(
                  // keep numbers LTR
                  textDirection: TextDirection.ltr,
                  child: Text(p,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                side: const BorderSide(color: Color(0xFFCFE3DB)),
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RIGHT (Kurdish) – take space properly
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 2),
                  const Text(
                    'بارڤین',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC43D3D),
                      letterSpacing: .3,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'بۆ دابیکردن و گەیاندنی\nخوادرن و خواردنەوەکان و بەهارات\nسەوزە و میوە و موادی سەفەری\nناونیشان / هەولێر',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Color(0xFF5F6B66), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // CENTER (logo + phones) – ALSO constrained
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  // horizontally scrollable to avoid overflow on small phones
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: phones.map(phoneChip).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // LEFT (English)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Barvin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E7A6D),
                      letterSpacing: .3,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'For General Trading & Commercial Agencies Ltd.',
                    style: TextStyle(color: Color(0xFF5F6B66), height: 1.4),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Erbil',
                    style: TextStyle(
                      color: Color(0xFF3A4C48),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    final rule = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 6,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        gradient: LinearGradient(
          colors: [Color(0xFF1E7A6D), Color(0xFFDCDCDC), Color(0xFFC43D3D)],
          stops: [0.33, 0.67, 1.0],
        ),
      ),
    );

    // meta cards
    Widget metaRow(String left, String right) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border(
                bottom: BorderSide(
                    color: const Color(0xFFDBE7E1),
                    width: 1,
                    style: BorderStyle.solid)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(left, style: const TextStyle(color: Color(0xFF4E5A56))),
              Text(right,
                  style: const TextStyle(
                      color: Color(0xFF1E7A6D), fontWeight: FontWeight.w700)),
            ],
          ),
        );

    final metaGrid = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6ECE8)),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final isNarrow = c.maxWidth < 500;
          return GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isNarrow ? 1 : 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: isNarrow ? 0 : 18,
              childAspectRatio: isNarrow ? 7 : 7,
            ),
            children: [
              metaRow(s.receiptCustomerNameLabel,
                  (o['user']?['name'] ?? '—').toString()),
              metaRow(s.receiptNumberLabel, '${o['id'] ?? ''}'),
              metaRow(s.receiptDateLabel,
                  (placedAt.isNotEmpty) ? placedAt.split('T').first : '—'),
              metaRow(s.receiptCurrencyLabel, currency),
              metaRow(
                  s.receiptDeliveryFeeLabel, '${_fmtNum(delivery)} $currency'),
              metaRow(s.receiptLaborFeeLabel, '${_fmtNum(labor)} $currency'),
              metaRow(
                  s.receiptDiscountLabel, '${_fmtNum(discount)} $currency'),
              metaRow(s.receiptBranchLabel,
                  (o['branch']?['name'] ?? 'رەئیسی').toString()),
            ],
          );
        },
      ),
    );

    // items "table"
    final itemsTable = Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E7E3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFE9F5F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                _Cell(s.receiptColNo, flex: 10, header: true),
                _Cell(s.receiptColCode, flex: 22, header: true),
                _Cell(s.receiptColName, flex: 36, header: true),
                _Cell(s.receiptColQty, flex: 14, header: true),
                _Cell(s.receiptColUnitPrice, flex: 18, header: true),
                _Cell(s.receiptColTotal, flex: 22, header: true),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: const Color(0xFFE0E7E3), width: i == 0 ? 0 : 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _Cell('${i + 1}', flex: 10),
                  _Cell(rows[i]['code'] as String, flex: 22),
                  _Cell(rows[i]['name'] as String, flex: 36),
                  _Cell(_fmtNum(rows[i]['qty'] as num), flex: 14),
                  _Cell(_fmtNum(rows[i]['unit'] as num), flex: 18),
                  _Cell(_fmtNum(rows[i]['total'] as num), flex: 22),
                ],
              ),
            ),
        ],
      ),
    );

    // totals
    Widget totalRow(String label, String value, {bool grand = false}) {
      return Padding(
        padding: EdgeInsets.only(top: grand ? 8 : 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: grand ? 16 : 14,
                    fontWeight: grand ? FontWeight.w800 : FontWeight.w600)),
            Text(value,
                style: TextStyle(
                    fontSize: grand ? 16 : 14,
                    fontWeight: grand ? FontWeight.w800 : FontWeight.w600,
                    color: grand ? const Color(0xFFC43D3D) : Colors.black)),
          ],
        ),
      );
    }

    final totals = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          totalRow(s.receiptSubtotalLabel, '${_fmtNum(subtotal)} $currency'),
          totalRow(s.receiptDeliveryFeeLabel, '${_fmtNum(delivery)} $currency'),
          totalRow(s.receiptLaborFeeLabel, '${_fmtNum(labor)} $currency'),
          totalRow(s.receiptDiscountLabel, '-${_fmtNum(discount)} $currency'),
          const Divider(height: 16),
          totalRow(s.receiptGrandTotalLabel, '${_fmtNum(grand)} $currency',
              grand: true),
        ],
      ),
    );

    final signature = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.receiptSignatureLabel,
            style: const TextStyle(fontSize: 14, color: Color(0xFF495652))),
        const SizedBox(height: 24),
        Container(height: 1, width: 280, color: const Color(0xFFC9D5CF)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        letterhead,
        rule,
        const SizedBox(height: 4),
        Center(
          child: Text(s.receiptTitle,
              style: TextStyle(
                  color: const Color(0xFFC43D3D),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        metaGrid,
        itemsTable,
        totals,
        signature,
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool header;
  const _Cell(this.text, {this.flex = 1, this.header = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: header ? Color(0xFF1E7A6D) : Colors.black87,
      fontWeight: header ? FontWeight.w700 : FontWeight.w500,
      fontSize: header ? 13 : 13,
    );
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
