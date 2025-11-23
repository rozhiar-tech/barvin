// BasketPage to show items in cart with grouping and order
import 'dart:convert';
import 'package:barvin/constants/contact.dart';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/checkout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart'
    show Item, apiBase, textColor, secondaryColor;
import 'package:url_launcher/url_launcher.dart'; // NEW

const Color whatsAppGreen = Color(0xFF25D366);

const Color primaryColor = Color(0xFF567765);

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});
  @override
  BasketPageState createState() => BasketPageState(); // <- public
}

class CartEntry {
  final Item item;
  int quantity;
  final String? basketType;
  final int? basketId;

  CartEntry({
    required this.item,
    required this.quantity,
    this.basketType,
    this.basketId,
  });
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
      final basketType = m['basket_type']?.toString();
      final basketId = m['basket_id'] == null
          ? null
          : int.tryParse(m['basket_id'].toString());

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
        final existing = grouped[idStr]!;
        existing.quantity += qty;
        if (existing.basketType == null && basketType != null) {
          grouped[idStr] = CartEntry(
            item: existing.item,
            quantity: existing.quantity,
            basketType: basketType,
            basketId: basketId ?? existing.basketId,
          );
        }
      } else {
        grouped[idStr] = CartEntry(
          item: item,
          quantity: qty,
          basketType: basketType,
          basketId: basketId,
        );
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
              if (e.basketType != null) 'basket_type': e.basketType,
              if (e.basketId != null) 'basket_id': e.basketId.toString(),
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

  Future<void> _updateQuantityForEntry(CartEntry entry, int delta) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      final index = _entries.indexOf(entry);
      if (index == -1) return;
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
              'discount': e.item.discount.toString(),
              'quantity': e.quantity.toString(),
              'imageUrl': e.item.imageUrl,
              'description': e.item.description,
              'supplierName': e.item.supplier_name,
              if (e.basketType != null) 'basket_type': e.basketType,
              if (e.basketId != null) 'basket_id': e.basketId.toString(),
            }))
        .toList();
    await prefs.setStringList('cart', cleaned);
  }

  List<_BasketRenderNode> _buildRenderNodes() {
    final items = List<CartEntry>.from(_entries);
    items.sort((a, b) =>
        _basketPriority(a.basketType).compareTo(_basketPriority(b.basketType)));
    final nodes = <_BasketRenderNode>[];
    String? lastType;
    for (final entry in items) {
      final type = entry.basketType;
      if (nodes.isEmpty || type != lastType) {
        nodes.add(_BasketRenderNode.header(_basketSectionTitle(type)));
        lastType = type;
      }
      nodes.add(_BasketRenderNode.entry(entry));
    }
    if (nodes.isEmpty) {
      nodes.add(_BasketRenderNode.header(_basketSectionTitle(null)));
    }
    return nodes;
  }

  int _basketPriority(String? type) {
    switch (type) {
      case 'custom_food_basket':
        return 0;
      case 'food_basket':
        return 1;
      default:
        return 2;
    }
  }

  String _basketSectionTitle(String? type) {
    switch (type) {
      case 'custom_food_basket':
        return 'Your custom baskets';
      case 'food_basket':
        return 'Preset food baskets';
      default:
        return 'Regular items';
    }
  }

  String? _basketLabel(String? type) {
    switch (type) {
      case 'custom_food_basket':
        return 'Custom basket';
      case 'food_basket':
        return 'Food basket';
      default:
        return null;
    }
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
    String? disabledReason;
    if (!_isLoggedIn) {
      disabledReason = "Please sign in to place your order.";
    } else if (_entries.isEmpty) {
      disabledReason = "Add an item to your basket to continue.";
    } else if (_isLoadingOrder) {
      disabledReason = "Submitting your order…";
    }
    final renderNodes = _buildRenderNodes();

    return Scaffold(
      backgroundColor: const Color(0xFFD3E4C4), // soft green
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(s.basketTitle, style: const TextStyle(color: textColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ─── Item List ────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                itemCount: renderNodes.length,
                itemBuilder: (_, idx) {
                  final node = renderNodes[idx];
                  if (node.isHeader) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Text(
                        node.header!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    );
                  }
                  final entry = node.entry!;
                  final thumbUrl = _normalizeImageUrl(entry.item.imageUrl);
                  final badge = _basketLabel(entry.basketType);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (badge != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        secondaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                entry.item.localizedName(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _QuantityButton(
                                      icon: Icons.remove,
                                      onTap: () =>
                                          _updateQuantityForEntry(entry, -1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${entry.quantity}',
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                  _QuantityButton(
                                      icon: Icons.add,
                                      onTap: () =>
                                          _updateQuantityForEntry(entry, 1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                onTap: () => _updateQuantityForEntry(
                                    entry, -entry.quantity),
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
                    label: s.deliveryFee,
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

            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        s.orderHoursHeading,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.orderHoursBody,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: secondaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.whatsappHelpBody,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _entries.isEmpty ? null : _sendOrderViaWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: Text(s.whatsappHelpCta),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _entries.isEmpty ? Colors.grey : whatsAppGreen,
                      side: BorderSide(
                        color: _entries.isEmpty ? Colors.grey : whatsAppGreen,
                      ),
                    ),
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
            if (disabledReason != null) ...[
              const SizedBox(height: 12),
              Text(
                disabledReason,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              if (!_isLoggedIn)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text("Sign in to continue"),
                ),
            ],
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

class _BasketRenderNode {
  final String? header;
  final CartEntry? entry;
  const _BasketRenderNode.header(this.header) : entry = null;
  const _BasketRenderNode.entry(this.entry) : header = null;
  bool get isHeader => header != null;
}
