import 'package:barvin/models/item.dart';
import 'package:flutter/material.dart';

extension LocalizedItem on Item {
  String localizedDescription(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    switch (code) {
      case 'ku':
        return nameKu.isNotEmpty
            ? nameKu
            : nameEn; // or a `description_ku` field if you have one
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      default:
        return description;
    }
  }
}
