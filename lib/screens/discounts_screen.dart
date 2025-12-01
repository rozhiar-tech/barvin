import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barvin/models/discount.dart';
import 'package:barvin/screens/home.dart' show apiBase;
import 'package:barvin/constants/app_constants.dart';
import 'single_item.dart';

const Color primaryColor = AppColors.primaryLight;
const Color secondaryColor = AppColors.secondary;
const Color textColor = AppColors.textPrimary;

class DiscountDetailScreen extends StatelessWidget {
  final Discount discount;
  const DiscountDetailScreen({Key? key, required this.discount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = discount.items;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text(
          discount.title.isNotEmpty ? discount.title : 'Discount',
          style: const TextStyle(color: textColor),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: secondaryColor),
        elevation: 0,
        actions: [
          if (discount.badge.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      discount.badge,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No items in this discount',
                  style: TextStyle(color: textColor)))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final imgUrl = _formatUrl(it.imageUrl);
                  final hasDiscount = it.discount > 0;
                  final discounted =
                      (it.price * (1 - it.discount / 100)).toStringAsFixed(0);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SingleItem(
                            id: it.id,
                            icon: Icons.fastfood,
                            name: it.localizedName(context),
                            description: it.description,
                            unitPrice: it.price,
                            imageUrl: imgUrl,
                            discount: it.discount,
                            supplierName: it.supplier_name,
                            categoryId: it.categoryId,
                            categoryNameEn: it.categoryNameEn,
                            categoryNameKu: it.categoryNameKu,
                            categoryNameAr: it.categoryNameAr,
                            subcategoryId: it.subcategoryId,
                            subcategoryNameEn: it.subcategoryNameEn,
                            subcategoryNameKu: it.subcategoryNameKu,
                            subcategoryNameAr: it.subcategoryNameAr,
                            packSize: it.packSize,
                            unit: it.unit,
                            packPrice: it.packPrice,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // image + badge
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: AspectRatio(
                                  aspectRatio: 1.2,
                                  child: imgUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imgUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.error),
                                        )
                                      : Container(color: Colors.grey[200]),
                                ),
                              ),
                              if (hasDiscount)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                        '-${it.discount.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              it.localizedName(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: hasDiscount
                                ? Row(
                                    children: [
                                      Text('${it.price.toStringAsFixed(0)} IQD',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          )),
                                      const SizedBox(width: 8),
                                      Text('$discounted IQD',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: textColor)),
                                    ],
                                  )
                                : Text('${it.price.toStringAsFixed(0)} IQD',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor)),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatUrl(String raw) {
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    final host = apiBase.replaceAll('/api', '');
    return path.isEmpty ? '' : '$host/$path';
  }
}
