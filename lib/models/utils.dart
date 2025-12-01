/// Utility functions for model parsing

double parseNum(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  // Clean strings like "20%", " 15 ", etc.
  final cleaned = v.toString().trim().replaceAll(RegExp(r'[^0-9\.\-]'), '');
  return double.tryParse(cleaned) ?? 0.0;
}

int parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

