import 'package:flutter/material.dart';
import 'utils.dart';

/// Model representing a product/item
class Item {
  final int id;
  final String nameEn, nameKu, nameAr;
  final String imageUrl;
  final double price, discount;
  final String description;
  final String supplier_name;
  final int? categoryId;
  final String? categoryNameEn;
  final String? categoryNameKu;
  final String? categoryNameAr;
  final int? subcategoryId;
  final String? subcategoryNameEn;
  final String? subcategoryNameKu;
  final String? subcategoryNameAr;

  // NEW (optional)
  final int? discountId;
  final int packSize;
  final String unit;
  final double? packPrice;

  Item({
    required this.id,
    required this.nameEn,
    required this.nameKu,
    required this.nameAr,
    required this.imageUrl,
    required this.price,
    required this.discount,
    required this.description,
    required this.supplier_name,
    this.categoryId,
    this.categoryNameEn,
    this.categoryNameKu,
    this.categoryNameAr,
    this.subcategoryId,
    this.subcategoryNameEn,
    this.subcategoryNameKu,
    this.subcategoryNameAr,
    this.discountId,
    this.packSize = 1,
    this.unit = '',
    this.packPrice,
  });

  factory Item.fromJson(Map<String, dynamic> j) {
    int? catId = parseInt(j['category_id'] ?? j['categoryId']);
    String? catNameEn = (j['category_name_en'] ?? '').toString();
    String? catNameKu = (j['category_name_ku'] ?? '').toString();
    String? catNameAr = (j['category_name_ar'] ?? '').toString();

    final catObj = j['category'];
    if (catObj is Map<String, dynamic>) {
      catNameEn =
          (catObj['name_en'] ?? catObj['name'] ?? catNameEn ?? '').toString();
      catNameKu = (catObj['name_ku'] ?? catNameKu ?? '').toString();
      catNameAr = (catObj['name_ar'] ?? catNameAr ?? '').toString();
    }

    int? subId =
        parseInt(j['subcategory_id'] ?? j['subcategoryId'] ?? j['sub_category_id']);

    String? subNameEn = (j['subcategory_name_en'] ?? '').toString();
    String? subNameKu = (j['subcategory_name_ku'] ?? '').toString();
    String? subNameAr = (j['subcategory_name_ar'] ?? '').toString();

    final subObj = j['subcategory'] ?? j['sub_category'];
    if (subObj is Map<String, dynamic>) {
      subNameEn =
          (subObj['name_en'] ?? subObj['name'] ?? subNameEn ?? '').toString();
      subNameKu = (subObj['name_ku'] ?? subNameKu ?? '').toString();
      subNameAr = (subObj['name_ar'] ?? subNameAr ?? '').toString();
    }

    final price = parseNum(j['price']);
    final discount = parseNum(
      j['discount'] ?? j['discount_percent'] ?? j['discountPercentage'],
    );

    final supplier =
        (j['supplierName'] ?? j['supplier_name'] ?? j['vendor'] ?? '')
            .toString();

    final packSize = parseInt(j['pack_size']);
    final unit = (j['unit'] ?? '').toString();
    final packPriceRaw = j['pack_price'];
    final packPrice = packPriceRaw == null ? null : parseNum(packPriceRaw);
    final did = j['discount_id'] == null
        ? null
        : int.tryParse(j['discount_id'].toString());

    return Item(
      id: parseInt(j['id']),
      nameEn: j['name_en'] ?? '',
      nameKu: j['name_ku'] ?? '',
      nameAr: j['name_ar'] ?? '',
      imageUrl: j['image_url'] ?? '',
      price: price,
      discount: discount,
      description: j['description']?.toString().trim() ?? '',
      supplier_name: supplier,
      categoryId: catId,
      categoryNameEn: catNameEn.isNotEmpty == true ? catNameEn : null,
      categoryNameKu: catNameKu.isNotEmpty == true ? catNameKu : null,
      categoryNameAr: catNameAr.isNotEmpty == true ? catNameAr : null,
      subcategoryId: subId,
      subcategoryNameEn: subNameEn.isNotEmpty == true ? subNameEn : null,
      subcategoryNameKu: subNameKu.isNotEmpty == true ? subNameKu : null,
      subcategoryNameAr: subNameAr.isNotEmpty == true ? subNameAr : null,
      discountId: did,
      packSize: packSize > 0 ? packSize : 1,
      unit: unit,
      packPrice: (packPrice != null && packPrice > 0) ? packPrice : null,
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

  String? localizedSubcategoryName(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    String? fallback =
        subcategoryNameEn ?? subcategoryNameKu ?? subcategoryNameAr;
    switch (code) {
      case 'ku':
        return (subcategoryNameKu?.isNotEmpty ?? false)
            ? subcategoryNameKu
            : fallback;
      case 'ar':
        return (subcategoryNameAr?.isNotEmpty ?? false)
            ? subcategoryNameAr
            : fallback;
      default:
        return (subcategoryNameEn?.isNotEmpty ?? false)
            ? subcategoryNameEn
            : fallback;
    }
  }

  String? localizedCategoryName(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    String? fallback = categoryNameEn ?? categoryNameKu ?? categoryNameAr;
    switch (code) {
      case 'ku':
        return (categoryNameKu?.isNotEmpty ?? false)
            ? categoryNameKu
            : fallback;
      case 'ar':
        return (categoryNameAr?.isNotEmpty ?? false)
            ? categoryNameAr
            : fallback;
      default:
        return (categoryNameEn?.isNotEmpty ?? false)
            ? categoryNameEn
            : fallback;
    }
  }
}

