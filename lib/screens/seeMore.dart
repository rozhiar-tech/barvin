// ignore_for_file: unused_local_variable

import 'package:barvin/screens/home.dart';
import 'package:barvin/screens/single_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF567765);

class SeeMoreScreen extends StatefulWidget {
  final String title;
  final List<Item> items;
  final String host;

  const SeeMoreScreen({
    super.key,
    required this.title,
    required this.items,
    required this.host,
  });

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

// ignore: unused_element
int _cartCount = 0;

class _SeeMoreScreenState extends State<SeeMoreScreen> {
  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('cart') ?? [];
    setState(() => _cartCount = items.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 213, 236, 221),
              Color(0xFFF1FAF5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: widget.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.55, // fine-tune this until it feels right
            ),
            itemBuilder: (context, index) {
              final it = widget.items[index];
              // convert price to IQD:
              final priceIqd = it.price.round();
              final discountedIqd = (it.discount > 0)
                  ? ((it.price * (1 - it.discount / 100)).round())
                  : null;
              final raw = it.imageUrl.startsWith('/')
                  ? it.imageUrl.substring(1)
                  : it.imageUrl;
              final url = '${widget.host}/$raw';
              final rawPath = it.imageUrl.startsWith('/')
                  ? it.imageUrl.substring(1)
                  : it.imageUrl;
              final imgUrl = '${widget.host}/$rawPath';

              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SingleItem(
                              id: it.id, // ← the real integer ID

                              icon: Icons.fastfood,
                              name: it.localizedName(context),
                              description: it.description,
                              unitPrice: it.price,
                              imageUrl: imgUrl,
                              discount: it.discount,
                            )),
                  );
                  _loadCartCount(); // ← now we reload the badge *after* you pop back
                },
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: AspectRatio(
                    aspectRatio: 0.6, // ~ width / height of the card
                    child: Column(
                      children: [
                        // ─── Image takes 60% of the card’s height ──────────────
                        Expanded(
                          flex: 6,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: it.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl:
                                        '${widget.host}/${it.imageUrl.substring(1)}',
                                    placeholder: (_, __) => Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) =>
                                        Icon(Icons.error),
                                  )
                                : Container(color: Colors.grey[300]),
                          ),
                        ),

                        // ─── Text block takes 40% ────────────────────────────────
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  it.localizedName(context),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                if (it.description.isNotEmpty)
                                  Text(
                                    it.description,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                // Wrap the price row in a FittedBox so it never overflows
                                FittedBox(
                                  child: it.discount > 0
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${it.price.round()} IQD',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${(it.price * (1 - it.discount / 100)).round()} IQD',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '${it.price.round()} IQD',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
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
          ),
        ),
      ),
    );
  }
}
