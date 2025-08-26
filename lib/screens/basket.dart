// BasketPage to show items in cart with grouping and order
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/checkout.dart';
import 'package:barvin/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart' show apiBase;
import 'package:url_launcher/url_launcher.dart'; // NEW

const Color whatsAppGreen = Color(0xFF25D366);

// Use international format (no leading 0, country code first)
const String kWhatsAppNumber = '9647502312211';

const Color primaryColor = Color(0xFF567765);

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});
  @override
  BasketPageState createState() => BasketPageState(); // <- public
}

class CartEntry {
  final Item item;
  int quantity;
  CartEntry({required this.item, required this.quantity});
}

class BasketPageState extends State<BasketPage> {
  String _userName = '';
  String _userPhone = '';
  String _userAddress = '';
  List<CartEntry> _entries = [];
  double _deliveryFee = 0; // ← from /settings
  bool _isLoggedIn = false;
  bool _freeDelivery = false;
  bool _isLoadingOrder = false;
  String token = '';

  String _normalizeImageUrl(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith('http')) return raw;
    final base = apiBase.replaceAll('/api', ''); // http://95.111.224.58:4000
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$base/$path';
  }

  Future<void> reload() async {
    await _loadCart();
    await _loadSettings();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadCart();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/settings'));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = m['delivery_fee_iqd'];
        final fee = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '');
        if (fee != null) {
          setState(() => _deliveryFee = fee);
        }
      } else {
        // debug only
        print('Settings load failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      // debug only
      print('Settings load error: $e');
    }
  }

  Future<void> _checkLoginAndLoadCart() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('loggedIn') ?? false;
    token = prefs.getString('token') ?? '';
    await _loadCart();
    setState(() {
      if (_isLoggedIn) {
        _userName = prefs.getString('userName') ?? '';
        _userPhone = prefs.getString('userPhone') ?? '';
        _userAddress = prefs.getString('userAddress') ?? '';
      }
    });
  }

  String _buildWhatsAppMessage(BuildContext context) {
    final s = S.of(context);
    final b = StringBuffer();

    b.writeln(s.waHeader);
    if (_isLoggedIn) {
      if (_userName.isNotEmpty) b.writeln('👤 ${s.waName}: $_userName');
      if (_userPhone.isNotEmpty) b.writeln('📞 ${s.waPhone}: $_userPhone');
      if (_userAddress.isNotEmpty)
        b.writeln('📍 ${s.waAddress}: $_userAddress');
    }
    b.writeln('—' * 18);

    for (final e in _entries) {
      final lineTotal = (e.item.price * e.quantity).toStringAsFixed(0);
      b.writeln(
          '• ${e.item.localizedName(context)}  x${e.quantity}  = $lineTotal ${s.currencyIqd}');
    }

    b.writeln('—' * 18);
    b.writeln(
        '${s.waSubtotal}: ${_subtotal.toStringAsFixed(0)} ${s.currencyIqd}');
    b.writeln(
      '${s.waDelivery}: ${_freeDelivery ? s.waFree : "${_deliveryFee.toStringAsFixed(0)} ${s.currencyIqd}"}',
    );
    b.writeln(
        '${s.waTotalUpper}: ${_total.toStringAsFixed(0)} ${s.currencyIqd}');

    return b.toString();
  }

  Future<void> _sendOrderViaWhatsApp() async {
    final s = S.of(context);
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.snackBasketEmpty)),
      );
      return;
    }

    final msg = _buildWhatsAppMessage(context);
    final phone = kWhatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Try the app scheme first
    final uriApp = Uri.parse(
        'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(msg)}');
    // Fallback to web
    final uriWeb =
        Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');

    try {
      if (await canLaunchUrl(uriApp)) {
        await launchUrl(uriApp, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot open WhatsApp';
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.snackWhatsAppOpenFail)),
      );
    }
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('cart') ?? [];
    final loggedIn = prefs.getBool('loggedIn') ?? false;
    final hasDebt = prefs.getBool('debt') ?? false;

    // Decode & ensure every entry has a quantity
    final raw = rawList.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      m['quantity'] = m.containsKey('quantity') ? m['quantity'] : '1';
      m['id'] = m['id'].toString();
      return m;
    }).toList();

    // Group by id and sum quantities
    final Map<String, CartEntry> grouped = {};
    for (var m in raw) {
      final idStr = m['id'].toString();
      final name = m['name'] as String;
      final price = double.tryParse(m['price'].toString()) ?? 0;
      final qty = int.tryParse(m['quantity'].toString()) ?? 1;

      final item = Item(
        id: int.parse(idStr),
        nameEn: name,
        nameKu: name,
        nameAr: name,
        imageUrl: m['imageUrl'] ?? '',
        price: price,
        discount: double.tryParse((m['discount'] ?? '0').toString()) ?? 0.0,
        description: (m['description'] ?? '').toString(),
        supplier_name:
            (m['supplierName'] ?? m['supplier_name'] ?? '').toString(),
      );

      if (grouped.containsKey(idStr)) {
        grouped[idStr]!.quantity += qty;
      } else {
        grouped[idStr] = CartEntry(item: item, quantity: qty);
      }
    }

    // Persist the cleaned, grouped cart
    final cleaned = grouped.values
        .map((e) => jsonEncode({
              'id': e.item.id.toString(),
              'name': e.item.nameEn,
              'price': e.item.price.toString(),
              'discount': e.item.discount.toString(),
              'quantity': e.quantity.toString(),
              'imageUrl': e.item.imageUrl,
              'description': e.item.description,
              'supplierName': e.item.supplier_name,
            }))
        .toList();
    await prefs.setStringList('cart', cleaned);

    setState(() {
      _entries = grouped.values.toList();
      _isLoggedIn = loggedIn;
      _freeDelivery = hasDebt;
    });
  }

  double get _subtotal =>
      _entries.fold(0.0, (sum, e) => sum + e.item.price * e.quantity);

  double get _total => _subtotal + (_freeDelivery ? 0.0 : _deliveryFee);

  Future<void> _updateQuantity(int index, int delta) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      final newQty = _entries[index].quantity + delta;

      if (newQty < 1) {
        _entries.removeAt(index);
      } else {
        _entries[index].quantity = newQty;
      }
    });

    // persist back to prefs:
    final cleaned = _entries
        .map((e) => jsonEncode({
              'id': e.item.id.toString(),
              'name': e.item.nameEn,
              'price': e.item.price.toString(),
              'quantity': e.quantity.toString(),
            }))
        .toList();
    await prefs.setStringList('cart', cleaned);
  }

  // ignore: unused_element
  Future<void> _sendOrder() async {
    final s = S.of(context);
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.snackSignInToOrder)),
      );
      return;
    }

    setState(() => _isLoadingOrder = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final payload = {
      'items': _entries
          .map((e) => {
                'item_id': e.item.id,
                'quantity': e.quantity,
              })
          .toList(),
    };

    try {
      final res = await http.post(
        Uri.parse('$apiBase/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.snackOrderSuccess)),
        );
        await prefs.remove('cart');
        setState(() {
          _entries.clear();
        });
      } else {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['error'] ?? s.snackOrderFail)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.snackNetworkError)),
      );
      print(e);
    } finally {
      setState(() => _isLoadingOrder = false);
    }
  }

  // ignore: unused_element
  Future<void> _clearBasket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    print('Basket cleared');
    setState(() {
      _entries.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canOrder = _isLoggedIn && !_isLoadingOrder && _entries.isNotEmpty;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFD3E4C4), // soft green
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(s.basketTitle, style: const TextStyle(color: textColor)),
        actions: [
          IconButton(
            tooltip: s.whatsAppTooltip,
            onPressed: _entries.isEmpty ? null : _sendOrderViaWhatsApp,
            icon: Icon(
              Icons.chat,
              color: _entries.isEmpty ? Colors.grey : whatsAppGreen,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ─── Item List ────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, idx) {
                  final entry = _entries[idx];
                  final thumbUrl = _normalizeImageUrl(entry.item.imageUrl);

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffFEFAE0),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: thumbUrl.isNotEmpty
                              ? Image.network(
                                  thumbUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.fastfood,
                                      color: Colors.grey),
                                ),
                        ),

                        const SizedBox(width: 12),

                        // title + subtitle + quantity (flexible)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // name
                              Text(
                                entry.item.localizedName(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              // description
                              Text(
                                entry.item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),

                              // quantity controls
                              Row(
                                children: [
                                  _QuantityButton(
                                      icon: Icons.remove,
                                      onTap: () => _updateQuantity(idx, -1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${entry.quantity}',
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                  _QuantityButton(
                                      icon: Icons.add,
                                      onTap: () => _updateQuantity(idx, 1)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // price + delete
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(minWidth: 90, maxWidth: 140),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(entry.item.price * entry.quantity).toStringAsFixed(0)} ${s.currencyIqd}',
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () =>
                                    _updateQuantity(idx, -entry.quantity),
                                child: const Icon(Icons.delete_forever,
                                    color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ─── Order Summary ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xffFEFAE0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(label: s.subtotal, value: _subtotal),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: s.delivery,
                    value: _freeDelivery ? 0 : _deliveryFee,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: s.total,
                    value: _total,
                    isBold: true,
                    fontSize: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Checkout Button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: canOrder
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.checkoutProceed,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round button for “–” and “+”
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Icon(icon, size: 20, color: primaryColor),
      ),
    );
  }
}

/// A single row in the order summary
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final double fontSize;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            )),
        Text('${value.toStringAsFixed(0)} ${s.currencyIqd}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            )),
      ],
    );
  }
}
