import 'package:barvin/config/environment.dart';

String get apiOrigin => Environment.apiOrigin;
String get apiBase => Environment.apiBase;

Uri apiUrl(String path, [Map<String, dynamic>? query]) {
  final normalized = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$apiBase$normalized').replace(queryParameters: query);
}

String mediaUrlFrom(String rawPath) {
  final trimmed = rawPath.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final relative = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '$apiOrigin/$relative';
}
