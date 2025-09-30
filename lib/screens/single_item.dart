// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
  final double discount; // % off (item-level)
  final String imageUrl;
  final String? supplierName;

  /// OPTIONAL: pass these if you already have them; otherwise they'll be fetched.
  final int? packSize; // e.g. 24
  final String? unit; // e.g. "pcs", "kg", ...
  final double? packPrice; // total price for a whole pack (OPTIONAL)

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
    this.packPrice,
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
  double? _packPrice; // total pack price (if provided by server)

  // campaign discount (via discount_id → /discounts/…)
  String? _campaignKind; // "percent" | "amount"
  double? _campaignValue; // value of the discount
  bool _campaignActive = false;

  // We also pull discount_id from the item payload (if present)
  int? _discountId;

  // ---------- PRICE HELPERS ----------

  double get _baseUnitPrice => widget.unitPrice;

  // Item discount
  double _applyItemDiscount(double price) {
    final d = widget.discount;
    if (d <= 0) return price;
    final v = price * (1 - d / 100.0);
    return v.clamp(0, double.infinity);
  }

  // Campaign discount
  double _applyCampaignDiscount(double price) {
    if (!_campaignActive || _campaignKind == null || _campaignValue == null) {
      return price;
    }
    double out = price;
    if (_campaignKind == 'percent') {
      out = price * (1 - (_campaignValue! / 100.0));
    } else if (_campaignKind == 'amount') {
      out = price - _campaignValue!;
    }
    return out.clamp(0, double.infinity);
  }

  // Convenient accessors to compare sources
  double get _withItem => _applyItemDiscount(_baseUnitPrice);
  double get _withCampaign => _applyCampaignDiscount(_baseUnitPrice);

  // Choose the better (lower) unit price between item.discount and campaign discount.
  double get _bestUnitPrice => math.min(_withItem, _withCampaign);

  // Which discount source is winning? ("item" | "campaign" | "none")
  String get _bestSource {
    const eps = 0.0001;
    if (_campaignActive && _withCampaign + eps < _withItem) return 'campaign';
    if (widget.discount > 0 && _withItem + eps < _baseUnitPrice) return 'item';
    return 'none';
  }

  // Effective pack price:
  // - Prefer explicit packPrice if provided.
  // - Else fall back to bestUnitPrice × packSize.
  double get _effectivePackPrice {
    final ps = (_packSize ?? 1);
    if (ps > 1 && (_packPrice ?? 0) > 0) return _packPrice!;
    return _bestUnitPrice * (ps > 0 ? ps : 1);
  }

  // Line total switches between units vs packs
  double get _lineTotal => _orderByPack
      ? _effectivePackPrice * _quantity
      : _bestUnitPrice * _quantity;

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
    _packPrice = widget.packPrice;

    // Fetch any missing details (pack, supplier, discount_id / campaign)
    _loadDetailsFromServer();
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
        final pp = _toDouble(m['pack_price']);
        final did = int.tryParse((m['discount_id'] ?? '').toString());

        // If backend embedded the discount itself (appliedDiscount), parse it
        final ad = m['appliedDiscount'];
        String? kind;
        double? val;
        bool active = false;
        if (ad is Map) {
          kind = (ad['kind'] ?? 'percent').toString();
          val = _toDouble(ad['value']) ?? 0.0;
          final a =
              (ad['active'] == true) || (ad['active']?.toString() == 'true');

          bool live = false;
          if (a) {
            final s = _toDate(ad['start_at']);
            final e = _toDate(ad['end_at']);
            final now = DateTime.now().toUtc();
            final su = s?.toUtc();
            final eu = e?.toUtc();
            live = (su == null || !now.isBefore(su)) &&
                (eu == null || !now.isAfter(eu));
          }
          active = live;
        }

        if (!mounted) return;
        setState(() {
          if (sup.isNotEmpty) _supplier = sup;
          if (pk != null && pk > 0) _packSize = pk;
          if (un.isNotEmpty) _unit = un;
          if ((pp ?? 0) > 0) _packPrice = pp;
          _discountId = did;

          if (ad is Map) {
            _campaignKind = kind;
            _campaignValue = val;
            _campaignActive = active;
          }

          if ((_packSize ?? 1) <= 1) _orderByPack = false; // no pack option
        });

        // If server didn't embed the discount object, fetch it by id
        if ((ad == null || !_campaignActive) && did != null) {
          await _loadCampaignDiscount(did);
        }
      }
    } catch (_) {
      // ignore fetch errors silently
    }
  }

  Future<void> _loadCampaignDiscount(int id) async {
    // Try direct endpoint first
    Future<Map<String, dynamic>?> _getOne() async {
      try {
        final r = await http.get(Uri.parse('$apiBase/discounts/$id'));
        if (r.statusCode == 200) {
          return jsonDecode(r.body) as Map<String, dynamic>;
        }
      } catch (_) {}
      return null;
    }

    Map<String, dynamic>? d = await _getOne();

    // Fallback: scan /discounts/public
    if (d == null) {
      try {
        final res = await http.get(Uri.parse('$apiBase/discounts/public'));
        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body) as List;
          d = list
              .cast<Map<String, dynamic>>()
              .firstWhere((x) => _toInt(x['id']) == id, orElse: () => {});
          if (d!.isEmpty) d = null;
        }
      } catch (_) {}
    }

    if (d == null || !mounted) return;

    final kind = (d['kind'] ?? 'percent').toString();
    final val = _toDouble(d['value']) ?? 0.0;
    final activeFlag =
        (d['active'] == true) || (d['active']?.toString() == 'true');

    bool isLive = false;
    if (activeFlag) {
      final s = _toDate(d['start_at']);
      final e = _toDate(d['end_at']);
      final now = DateTime.now().toUtc();
      final su = s?.toUtc();
      final eu = e?.toUtc();
      isLive =
          (su == null || !now.isBefore(su)) && (eu == null || !now.isAfter(eu));
    }

    setState(() {
      _campaignKind = kind;
      _campaignValue = val;
      _campaignActive = isLive;
    });
  }

  // ---------- CART ----------

  Future<void> _addToBasket() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList('cart') ?? [];
    final cart = cartList
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList(growable: true);

    // How many *units* to add based on the current mode:
    final perPack = (_packSize ?? 1) > 1 ? _packSize! : 1;
    final unitsToAdd = _orderByPack ? (_quantity * perPack) : _quantity;

    // If ordering by pack and we have an explicit pack price, store per-unit as (pack_price / pack_size).
    // Else store the best unit price.
    double unitPriceToStore;
    if (_orderByPack && (_packPrice ?? 0) > 0 && perPack > 0) {
      unitPriceToStore = (_packPrice! / perPack);
    } else {
      unitPriceToStore = _bestUnitPrice;
    }

    final itemId = widget.id.toString();
    final idx = cart.indexWhere((e) => e['id'].toString() == itemId);

    if (idx >= 0) {
      final existing = cart[idx];
      final existingQty = int.tryParse(existing['quantity'].toString()) ?? 0;
      existing['quantity'] = (existingQty + unitsToAdd).toString();

      // keep metadata reasonably up to date
      existing['price'] = unitPriceToStore.toStringAsFixed(0);
      existing['discount'] = widget.discount.toString(); // keep original field
      existing['imageUrl'] = widget.imageUrl;
      existing['supplierName'] = (_supplier ?? '');
      existing['unit'] = _unit ?? '';
      existing['packSize'] = (_packSize ?? 1).toString();

      cart[idx] = existing;
    } else {
      cart.add({
        'id': itemId,
        'name': widget.name,
        'price': unitPriceToStore.toStringAsFixed(0), // store effective unit
        'discount': widget.discount.toString(), // original item discount field
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

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final heroTag = 'itemImage_${widget.id}';
    final hasPackOption = (_packSize ?? 1) > 1;

    // Display strings
    final currency = S.of(context).currency_code_iqd;

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

            const SizedBox(height: 6),

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
              const SizedBox(height: 4),
            ],

            // PRICE & DISCOUNT (showing best unit price)
            _PriceBlock(
              basePrice: _baseUnitPrice,
              bestUnitPrice: _bestUnitPrice,
              itemDiscountPercent: widget.discount,
              currency: currency,
            ),

            // VISUAL: which discount source applied?
            _DiscountBadges(
              itemDiscountPercent: widget.discount,
              campaignKind: _campaignKind,
              campaignValue: _campaignValue,
              campaignActive: _campaignActive,
              bestSource: _bestSource,
              currency: currency,
            ),

            // PACK OPTION
            if (hasPackOption) ...[
              // const SizedBox(height: 12),
              // Center(
              //   child: Text(
              //     '${S.of(context).pack_size} = ${_packSize!} ${_unit ?? "unit"}${_packSize! > 1 ? "s" : ""}',
              //     style: TextStyle(color: Colors.grey[700]),
              //   ),
              // ),
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
              // If we have an explicit pack price, show it
              if ((_packPrice ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      '${S.of(context).pack}: ${_packPrice!.toStringAsFixed(0)} $currency',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

                // Line total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${_lineTotal.toStringAsFixed(0)} $currency',
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
                  style: const TextStyle(
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

  // ---------- utils ----------
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final cleaned = v.toString().trim().replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(cleaned);
  }

  DateTime? _toDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}

/// Small widget to display unit price with optional strike-through.
class _PriceBlock extends StatelessWidget {
  final double basePrice;
  final double bestUnitPrice;
  final double itemDiscountPercent;
  final String currency;

  const _PriceBlock({
    Key? key,
    required this.basePrice,
    required this.bestUnitPrice,
    required this.itemDiscountPercent,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show strike-through only if the best price is lower than base
    final hasLower = bestUnitPrice < basePrice - 0.0001;

    if (hasLower) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${basePrice.toStringAsFixed(0)} $currency',
            style: const TextStyle(
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${bestUnitPrice.toStringAsFixed(0)} $currency',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      );
    }

    return Text(
      '${bestUnitPrice.toStringAsFixed(0)} $currency',
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

/// Chips row explaining which discount is applied.
class _DiscountBadges extends StatelessWidget {
  final double itemDiscountPercent;
  final String? campaignKind; // "percent" | "amount"
  final double? campaignValue;
  final bool campaignActive;
  final String bestSource; // "item" | "campaign" | "none"
  final String currency;

  const _DiscountBadges({
    Key? key,
    required this.itemDiscountPercent,
    required this.campaignKind,
    required this.campaignValue,
    required this.campaignActive,
    required this.bestSource,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showItem = itemDiscountPercent > 0;
    final showCampaign = campaignActive == true && (campaignValue ?? 0) > 0;

    if (!showItem && !showCampaign) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (showItem) {
      final applied = bestSource == 'item';
      chips.add(_buildChip(
        label:
            '${S.of(context).item} −${itemDiscountPercent.toStringAsFixed(0)}%',
        applied: applied,
      ));
    }

    if (showCampaign) {
      final applied = bestSource == 'campaign';
      final isPercent = (campaignKind ?? 'percent') == 'percent';
      final valueStr = isPercent
          ? '−${campaignValue!.toStringAsFixed(0)}%'
          : '−${campaignValue!.toStringAsFixed(0)} $currency';
      chips.add(_buildChip(
        label: '${S.of(context).campaign} $valueStr',
        applied: applied,
      ));
    }

    // Add a small helper text if something is applied
    final info = bestSource == 'none'
        ? null
        : Text(
            bestSource == 'item'
                ? '${S.of(context).bestPriceItem}'
                : '${S.of(context).bestPriceCampaign}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: chips,
          ),
          if (info != null) ...[
            const SizedBox(height: 6),
            info,
          ]
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required bool applied}) {
    return Chip(
      avatar: applied
          ? const Icon(Icons.check, size: 16, color: primaryColor)
          : const Icon(Icons.local_offer, size: 16, color: Colors.grey),
      label: Text(
        label,
        style: TextStyle(
          color: applied ? Colors.black87 : Colors.black54,
          fontWeight: applied ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      backgroundColor:
          applied ? primaryColor.withOpacity(0.15) : Colors.grey.shade200,
      shape: StadiumBorder(
        side: BorderSide(
          color:
              applied ? primaryColor.withOpacity(0.35) : Colors.grey.shade300,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
      backgroundColor: Colors.white,
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
