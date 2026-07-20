import 'package:flutter/material.dart';
import 'item.dart';
import 'utils.dart';

/// Model representing a product category
class Category {
  final int id;
  final String nameEn, nameKu, nameAr;
  final String imageUrl;
  final List<Item> items;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    this.imageUrl = "",
    this.items = const [],
  });

  factory Category.fromJson(Map<String, dynamic> j) {
    // if the server embedded an "items" array, decode it
    final rawItems = j['items'] as List<dynamic>?;
    final parsedItems = rawItems
            ?.map((m) => Item.fromJson(m as Map<String, dynamic>))
            .toList() ??
        <Item>[];

    return Category(
      id: parseInt(j['id']),
      nameEn: j['name_en'] ?? '',
      nameKu: j['name_ku'] ?? '',
      nameAr: j['name_ar'] ?? '',
      imageUrl: j['image_url'] ?? '',
      items: parsedItems,
    );
  }

  String localizedName(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    switch (code) {
      case 'ku':
        return nameKu.isNotEmpty ? nameKu : nameEn;
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      default:
        return nameEn;
    }
  }
}

