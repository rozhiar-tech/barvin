import 'package:barvin/screens/home.dart';
import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF567765);

class SeeMoreScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final it = items[index];
            // convert price to IQD:
            final priceIqd = it.price.round();
            final discountedIqd = (it.discount > 0)
                ? ((it.price * (1 - it.discount / 100)).round())
                : null;
            final raw = it.imageUrl.startsWith('/')
                ? it.imageUrl.substring(1)
                : it.imageUrl;
            final url = '$host/$raw';

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // you can navigate to a detail page here
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // image
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: it.imageUrl.isNotEmpty
                          ? Image.network(url, height: 100, fit: BoxFit.cover)
                          : Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(Icons.fastfood,
                                  size: 40, color: secondaryColor),
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

                    const SizedBox(height: 4),
                    // description
                    if (it.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          it.description,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const Spacer(),
                    // price
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: discountedIqd != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$priceIqd IQD',
                                  style: TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey),
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
    );
  }
}
