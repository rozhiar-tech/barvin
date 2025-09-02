import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart'; // for Item & parseSectionsPayload
import 'single_item.dart';

const Color primaryColor = Color(0xFFbed6be);
const Color secondaryColor = Color(0xFF6D8474);
const Color textColor = Color(0xFF212121);

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({Key? key}) : super(key: key);

  @override
  _DiscountsScreenState createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  bool _loading = true;
  List<Item> _deals = [];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/categories/with-items'));
      final raw = await compute(parseSectionsPayload, res.body);
      final items = raw
          .cast<Map<String, dynamic>>()
          .expand((map) => (map['items'] as List)
              .cast<Map<String, dynamic>>()
              .map((j) => Item.fromJson(j)))
          .where((item) => item.discount > 0)
          .toList();
      setState(() {
        _deals = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFEFAE0),
      appBar: AppBar(
        title: const Text('Discounts', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: secondaryColor),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _deals.isEmpty
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: _deals.length == 1
                      ? _buildSingleDeal(_deals.first)
                      : _buildDealsGrid(_deals),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: secondaryColor),
          const SizedBox(height: 16),
          const Text(
            'No discounts available',
            style: TextStyle(fontSize: 18, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleDeal(Item deal) {
    final imageUrl = _formatUrl(deal.imageUrl);
    return Center(
      child: GestureDetector(
        onTap: () => _openItem(deal),
        child: Container(
          height: 240,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.error, size: 40),
                ),
                // Discount badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Text('-${deal.discount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                // Gradient overlay + text
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(deal.localizedName(context),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${deal.price.toStringAsFixed(0)} IQD',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            Text(
                                '${(deal.price * (1 - deal.discount / 100)).toStringAsFixed(0)} IQD',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDealsGrid(List<Item> deals) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: deals.length,
      itemBuilder: (ctx, idx) {
        final item = deals[idx];
        final url = _formatUrl(item.imageUrl);
        return GestureDetector(
          onTap: () => _openItem(item),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.error, size: 40),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('-${item.discount.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.localizedName(context),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                              '${(item.price * (1 - item.discount / 100)).toStringAsFixed(0)} IQD',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatUrl(String raw) {
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    final host = apiBase.replaceAll('/api', '');
    return '$host/$path';
  }

  void _openItem(Item it) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleItem(
          id: it.id,
          icon: Icons.fastfood,
          name: it.localizedName(context),
          description: it.description,
          unitPrice: it.price,
          imageUrl: _formatUrl(it.imageUrl),
          discount: it.discount,
        ),
      ),
    );
  }
}
