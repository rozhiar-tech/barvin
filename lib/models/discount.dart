import 'item.dart';
import 'utils.dart';

/// Model representing a discount/promotion
class Discount {
  final int id;
  final String title;
  final String description;

  /// "percent" | "amount"
  final String kind;
  final double value;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool active;
  final String imageUrl;
  final List<Item> items;

  Discount({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.value,
    required this.startAt,
    required this.endAt,
    required this.active,
    required this.imageUrl,
    required this.items,
  });

  factory Discount.fromJson(Map<String, dynamic> j) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final rawItems = (j['items'] as List?) ?? const [];
    // prefer image_url; else build from filename (what controller now sends anyway)
    String img = (j['image_url'] ?? '').toString();
    if (img.isEmpty) {
      final file = (j['image'] ?? '').toString();
      if (file.isNotEmpty) img = '/uploads/discounts/$file';
    }

    return Discount(
      id: j['id'] as int,
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      kind: (j['kind'] ?? 'percent').toString(),
      value: parseNum(j['value']),
      startAt: _parseDate(j['start_at']),
      endAt: _parseDate(j['end_at']),
      active: (j['active'] == true) || (j['active']?.toString() == 'true'),
      imageUrl: img,
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map((m) => Item.fromJson(m))
          .toList(),
    );
  }

  bool get isLive {
    if (!active) return false;
    final now = DateTime.now().toUtc();
    final s = startAt?.toUtc();
    final e = endAt?.toUtc();
    if (s != null && now.isBefore(s)) return false;
    if (e != null && now.isAfter(e)) return false;
    return true;
  }

  /// Formatted badge like "-14%" or "-500 IQD"
  String get badge {
    if (kind == 'percent') return '-${value.toStringAsFixed(0)}%';
    // assuming IQD; change label if you localize currency
    return '-${value.toStringAsFixed(0)} IQD';
  }
}

