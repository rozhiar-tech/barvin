import 'package:barvin/screens/home.dart';
import 'package:barvin/screens/single_item.dart';
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
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
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

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // image
                      Container(
                        height: 185,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: it.imageUrl.isNotEmpty
                              ? Image.network(url,
                                  height: 100, fit: BoxFit.cover)
                              : Container(
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.fastfood,
                                      size: 40, color: secondaryColor),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      // name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          it.localizedName(context),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 2),
                      // description
                      if (it.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            it.description,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const Spacer(),
                      // price
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: discountedIqd != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$priceIqd IQD',
                                    style: TextStyle(
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey),
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    '$discountedIqd IQD',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : Text(
                                '$priceIqd IQD',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
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
