const String apiOrigin = 'http://95.111.224.58:3000';
const String apiBase = '$apiOrigin/api';

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
