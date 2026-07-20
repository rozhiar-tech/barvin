import 'dart:convert';

import 'package:barvin/generated/l10n.dart';
import 'package:barvin/models/collections.dart';
import 'package:barvin/services/api_config.dart';
import 'package:barvin/constants/contact.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FoodBasketsScreen extends StatefulWidget {
  final List<FoodBasket> initialBaskets;
  const FoodBasketsScreen({Key? key, this.initialBaskets = const []})
      : super(key: key);

  @override
  State<FoodBasketsScreen> createState() => _FoodBasketsScreenState();
}

class _FoodBasketsScreenState extends State<FoodBasketsScreen> {
  late List<FoodBasket> _baskets;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _baskets = widget.initialBaskets;
    _fetchBaskets();
  }

  Future<void> _fetchBaskets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(apiUrl('/foodbaskets'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final baskets = data
            .whereType<Map<String, dynamic>>()
            .map(FoodBasket.fromJson)
            .toList();
        setState(() => _baskets = baskets);
      } else {
        setState(
            () => _error = 'Failed to load baskets (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load baskets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        iconTheme: const IconThemeData(color: Color(0xFF567765)),
        title: Text(s.foodBasketSectionTitle,
            style: const TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBaskets,
        child: _loading && _baskets.isEmpty
            ? ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _buildBasketList(context, s),
      ),
    );
  }

  Widget _buildBasketList(BuildContext context, S s) {
    if (_baskets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const SizedBox(height: 16),
          Card(
            color: const Color(0xffFEFAE0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error ?? 'No baskets available right now.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    final itemCount = _baskets.length + (_error != null ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (_, idx) {
        if (_error != null && idx == itemCount - 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        final basket = _baskets[idx];
        final imageUrl = basket.primaryImage == null
            ? null
            : mediaUrlFrom(basket.primaryImage!);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodBasketDetailPage(basket: basket),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: const Color(0xffFEFAE0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl == null
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 40),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              basket.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${basket.price.toStringAsFixed(0)} IQD',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF567765),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        basket.description.isNotEmpty
                            ? basket.description
                            : s.presetBasketDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${basket.items.length} items included',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FoodBasketDetailPage extends StatefulWidget {
  final FoodBasket basket;
  const FoodBasketDetailPage({Key? key, required this.basket})
      : super(key: key);

  @override
  State<FoodBasketDetailPage> createState() => _FoodBasketDetailPageState();
}

class _FoodBasketDetailPageState extends State<FoodBasketDetailPage> {
  int _basketQty = 1;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
  }

  double get _total => widget.basket.price * _basketQty;

  Future<void> _openWhatsApp() async {
    final s = S.of(context);
    setState(() => _sending = true);
    final phone = kWhatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer()
      ..writeln('Food basket order')
      ..writeln('Basket: ${widget.basket.name}')
      ..writeln('Quantity: $_basketQty')
      ..writeln('Total: ${_total.toStringAsFixed(0)} ${s.currencyIqd}')
      ..writeln('Items included:');

    for (final item in widget.basket.items) {
      final qty = item.defaultQuantity > 0 ? item.defaultQuantity : 1;
      buffer.writeln('- ${item.localizedName(context)} x$qty');
    }

    final msg = buffer.toString();
    final uriApp = Uri.parse(
        'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(msg)}');
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final imageUrl = widget.basket.primaryImage == null
        ? null
        : mediaUrlFrom(widget.basket.primaryImage!);
    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        iconTheme: const IconThemeData(color: Color(0xFF567765)),
        title: Text(widget.basket.name,
            style: const TextStyle(color: Colors.black87)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: imageUrl == null
                          ? Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 48),
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.basket.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.basket.price.toStringAsFixed(0)} IQD',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF567765),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.basket.description.isNotEmpty
                              ? widget.basket.description
                              : s.presetBasketDescription,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'What is inside',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: widget.basket.items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 12),
                          itemBuilder: (_, idx) {
                            final item = widget.basket.items[idx];
                            final itemImage = item.imageUrl.isEmpty
                                ? null
                                : mediaUrlFrom(item.imageUrl);
                            final qty = item.defaultQuantity > 0
                                ? item.defaultQuantity
                                : 1;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: itemImage == null
                                      ? Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: itemImage,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.localizedName(context),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'x$qty',
                                        style: const TextStyle(
                                            color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xffFEFAE0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _basketQty > 1
                              ? () => setState(() => _basketQty -= 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_basketQty',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _basketQty += 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: ${_total.toStringAsFixed(0)} IQD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _openWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(
                    Icons.message,
                    color: Colors.green,
                  ),
                  label:
                      Text(_sending ? 'Opening WhatsApp…' : s.whatsAppTooltip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
