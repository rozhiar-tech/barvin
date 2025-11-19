import 'package:flutter/material.dart';

class HandWork {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String description;
  final String thumbnailUrl;
  final String imageUrl;

  const HandWork({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    required this.thumbnailUrl,
    required this.imageUrl,
  });

  factory HandWork.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int _int(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return HandWork(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      price: _num(json['price']),
      quantity: _int(json['quantity']),
      description: (json['description'] ?? '').toString(),
      thumbnailUrl: (json['thumbnail_url'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
    );
  }

  String? get primaryImage {
    if (imageUrl.isNotEmpty) return imageUrl;
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    return null;
  }
}

class FoodBasketProduct {
  final int itemId;
  final String nameEn;
  final String nameKu;
  final String nameAr;
  final String imageUrl;
  final double price;
  final int defaultQuantity;

  const FoodBasketProduct({
    required this.itemId,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    required this.imageUrl,
    required this.price,
    required this.defaultQuantity,
  });

  factory FoodBasketProduct.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int _int(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final pivot = json['FoodBasketItem'] as Map<String, dynamic>?;

    return FoodBasketProduct(
      itemId: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      nameEn: (json['name_en'] ?? '').toString(),
      nameKu: (json['name_ku'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      price: _num(json['price']),
      defaultQuantity: _int(pivot?['quantity'] ?? json['quantity']),
    );
  }

  String localizedName(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'ku':
        return nameKu.isNotEmpty
            ? nameKu
            : (nameEn.isNotEmpty ? nameEn : nameAr);
      case 'ar':
        return nameAr.isNotEmpty
            ? nameAr
            : (nameEn.isNotEmpty ? nameEn : nameKu);
      default:
        return nameEn.isNotEmpty
            ? nameEn
            : (nameKu.isNotEmpty ? nameKu : nameAr);
    }
  }
}

class FoodBasket {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int? userId;
  final List<FoodBasketProduct> items;

  const FoodBasket({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.userId,
    required this.items,
  });

  factory FoodBasket.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int? _intOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final rawItems = (json['items'] as List?) ?? const [];

    return FoodBasket(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _num(json['price']),
      imageUrl: (json['image_url'] ?? '').toString(),
      userId: _intOrNull(json['user_id']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(FoodBasketProduct.fromJson)
          .toList(),
    );
  }

  String? get primaryImage => imageUrl.isNotEmpty ? imageUrl : null;
}
