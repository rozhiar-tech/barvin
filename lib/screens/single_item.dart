import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart' show apiBase;

const Color primaryColor = Color(0xFF567765);

class SingleItem extends StatefulWidget {
  final int id;
  final IconData icon;
  final String name;
  final String description;
  final double unitPrice; // base unit price (pre-discount)
  final double discount; // % off
  final String imageUrl;
  final String? supplierName;

  /// OPTIONAL: pass these if you already have them; otherwise they'll be fetched.
  final int? packSize; // e.g. 24
  final String? unit; // e.g. "pcs", "kg", ...

  const SingleItem({
    Key? key,
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.discount,
    required this.imageUrl,
    this.supplierName,
    this.packSize,
    this.unit,
  }) : super(key: key);

  @override
  State<SingleItem> createState() => _SingleItemState();
}

class _SingleItemState extends State<SingleItem> {
  int _quantity = 1; // counts units OR packs, depending on _orderByPack
  bool _orderByPack = false; // when true, qty is packs; false => units

  // details we may fetch:
  String? _supplier;
  int? _packSize; // e.g. 24
  String? _unit; // e.g. "pcs"

  double get _effectiveUnitPrice => widget.discount > 0
      ? widget.unitPrice * (1 - widget.discount / 100)
      : widget.unitPrice;

  double get _effectivePackPrice => (_packSize != null && _packSize! > 1)
      ? _effectiveUnitPrice * _packSize!
      : _effectiveUnitPrice;

  double get _lineTotal => _orderByPack
      ? _effectivePackPrice * _quantity
      : _effectiveUnitPrice * _quantity;

  void _increment() => setState(() => _quantity++);
  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  void initState() {
    super.initState();
    _supplier = (widget.supplierName ?? '').trim();
    _packSize = widget.packSize;
    _unit = widget.unit;

    // If pack info/supplier are missing, fetch from server
    if ((_supplier?.isEmpty ?? true) || _packSize == null || _unit == null) {
      _loadDetailsFromServer();
    }
  }

  Future<void> _loadDetailsFromServer() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/items/${widget.id}'));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        final sup =
            (m['supplier_name'] ?? m['supplier'] ?? m['supplierName'] ?? '')
                .toString()
                .trim();
        final pk = int.tryParse((m['pack_size'] ?? '').toString());
        final un = (m['unit'] ?? '').toString().trim();

        if (!mounted) return;
        setState(() {
          if (sup.isNotEmpty) _supplier = sup;
          if (pk != null && pk > 0) _packSize = pk;
          if (un.isNotEmpty) _unit = un;
          if ((_packSize ?? 1) <= 1)
            _orderByPack = false; // no pack option if invalid
        });
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _addToBasket() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList('cart') ?? [];
    final cart = cartList
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList(growable: true);

    // How many *units* to add based on the current mode:
    final perPack = (_packSize ?? 1) > 1 ? _packSize! : 1;
    final unitsToAdd = _orderByPack ? (_quantity * perPack) : _quantity;

    // Save the *effective* unit price so basket totals are correct even if discount is ignored later.
    final effectiveUnitPriceStr = _effectiveUnitPrice.toStringAsFixed(0);

    final itemId = widget.id.toString();
    final idx = cart.indexWhere((e) => e['id'].toString() == itemId);

    if (idx >= 0) {
      final existing = cart[idx];
      final existingQty = int.tryParse(existing['quantity'].toString()) ?? 0;
      existing['quantity'] = (existingQty + unitsToAdd).toString();

      // keep metadata reasonably up to date
      existing['price'] = effectiveUnitPriceStr;
      existing['discount'] = widget.discount.toString();
      existing['imageUrl'] = widget.imageUrl;
      existing['supplierName'] = (_supplier ?? '');
      existing['unit'] = _unit ?? '';
      existing['packSize'] = (_packSize ?? 1).toString();

      cart[idx] = existing;
    } else {
      cart.add({
        'id': itemId,
        'name': widget.name,
        'price': effectiveUnitPriceStr, // store effective unit price
        'discount': widget.discount.toString(),
        'quantity': unitsToAdd.toString(), // store *units* in the basket
        'imageUrl': widget.imageUrl,
        'supplierName': _supplier ?? '',
        'unit': _unit ?? '',
        'packSize': (_packSize ?? 1).toString(),
      });
    }

    await prefs.setStringList('cart', cart.map((m) => jsonEncode(m)).toList());

    if (!mounted) return;

    final modeLabel = _orderByPack
        ? 'pack${_quantity > 1 ? 's' : ''} = $unitsToAdd ${_unit ?? 'unit'}${unitsToAdd > 1 ? 's' : ''}'
        : '$unitsToAdd ${_unit ?? 'unit'}${unitsToAdd > 1 ? 's' : ''}';

    final message = '${widget.name} added to basket ($modeLabel)';
    Navigator.pop(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'itemImage_${widget.id}';
    final hasPackOption = (_packSize ?? 1) > 1;

    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE
            Container(
              height: 300,
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.imageUrl.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _FullscreenImagePage(
                                imageUrl: widget.imageUrl,
                                fallbackIcon: widget.icon,
                                heroTag: heroTag,
                              ),
                            ),
                          );
                        },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: heroTag,
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              fit: BoxFit.fitHeight,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(widget.icon,
                                    size: 80, color: primaryColor),
                              ),
                            )
                          : Center(
                              child: Icon(widget.icon,
                                  size: 80, color: primaryColor),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // NAME
            Text(
              widget.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, color: Colors.black87),
            ),

            const SizedBox(height: 8),

            // SUPPLIER (if any)
            if ((_supplier ?? '').isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, color: primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _supplier!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // UNIT (read-only info)
            if ((_unit ?? '').isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.straighten, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${S.of(context).unit}: ${_unit!}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // PRICE & DISCOUNT
            if (widget.discount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.unitPrice.toStringAsFixed(0)} ${S.of(context).currency_code_iqd}',
                    style: const TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_effectiveUnitPrice.toStringAsFixed(0)} ${S.of(context).currency_code_iqd}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                '${_effectiveUnitPrice.toStringAsFixed(0)} ${S.of(context).currency_code_iqd}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],

            // PACK OPTION (single selectable control)
            if (hasPackOption) ...[
              const SizedBox(height: 12),
              Center(
                child: FilterChip(
                  selected: _orderByPack,
                  onSelected: (v) => setState(() => _orderByPack = v),
                  selectedColor: primaryColor.withOpacity(0.15),
                  checkmarkColor: primaryColor,
                  label: Text('${S.of(context).pack} (×${_packSize!})'),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${S.of(context).pack_size} = ${_packSize!} ${_unit ?? "unit"}${_packSize! > 1 ? "s" : ""}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // DESCRIPTION
            if (widget.description.trim().isNotEmpty) ...[
              Text(widget.description,
                  style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 16),
            ],

            // QUANTITY & LINE TOTAL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Qty for units OR packs (depending on toggle)
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

                // Price labels
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _orderByPack
                          ? '${_effectivePackPrice.toStringAsFixed(0)} ${S.of(context).currency_code_iqd} / ${S.of(context).pack}'
                          : '${_effectiveUnitPrice.toStringAsFixed(0)} ${S.of(context).currency_code_iqd} / ${_unit ?? "${S.of(context).unit}"}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_lineTotal.toStringAsFixed(0)} ${S.of(context).currency_code_iqd}',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ADD TO BASKET
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
                child: Text(
                  S.of(context).addBasket,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable image viewer with Hero transition.
class _FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final String heroTag;

  const _FullscreenImagePage({
    Key? key,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 120, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
