import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'api_config.dart';

class AppVersionStatus {
  final bool requiresUpdate;
  final String? message;
  final String? storeUrl;
  final String? minVersion;
  final int? minBuild;

  const AppVersionStatus({
    required this.requiresUpdate,
    this.message,
    this.storeUrl,
    this.minVersion,
    this.minBuild,
  });

  AppVersionStatus copyWith({
    bool? requiresUpdate,
    String? message,
    String? storeUrl,
    String? minVersion,
    int? minBuild,
  }) {
    return AppVersionStatus(
      requiresUpdate: requiresUpdate ?? this.requiresUpdate,
      message: message ?? this.message,
      storeUrl: storeUrl ?? this.storeUrl,
      minVersion: minVersion ?? this.minVersion,
      minBuild: minBuild ?? this.minBuild,
    );
  }
}

class AppVersionService {
  const AppVersionService();

  Future<AppVersionStatus> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final currentVersionInfo =
          _VersionInfo.parse(packageInfo.version, fallbackBuild: currentBuild) ??
              _VersionInfo(0, 0, 0, currentBuild);
      final platform = Platform.isIOS ? 'ios' : 'android';
      final uri = apiUrl('/app-version', {'platform': platform});

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return const AppVersionStatus(requiresUpdate: false);
      }

      final Map<String, dynamic> payload = jsonDecode(response.body);
      final minBuild = _toInt(payload['min_supported_build']);
      final minVersionRaw = payload['min_supported_version'] as String?;
      final minVersionInfo =
          _VersionInfo.parse(minVersionRaw, fallbackBuild: minBuild);
      final bool isActive = payload['is_active'] != false;
      bool requires = false;

      if (minVersionInfo != null &&
          currentVersionInfo.compareTo(minVersionInfo) < 0) {
        requires = true;
      }

      if (!requires &&
          isActive &&
          minBuild != null &&
          minBuild > 0 &&
          currentBuild < minBuild) {
        requires = true;
      }

      return AppVersionStatus(
        requiresUpdate: requires,
        message: payload['update_message'] as String?,
        storeUrl: payload['store_url'] as String?,
        minVersion: minVersionRaw,
        minBuild: minBuild,
      );
    } catch (_) {
      return const AppVersionStatus(requiresUpdate: false);
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class _VersionInfo implements Comparable<_VersionInfo> {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const _VersionInfo(this.major, this.minor, this.patch, this.build);

  static _VersionInfo? parse(String? raw, {int? fallbackBuild}) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final plusParts = trimmed.split('+');
    final versionPart = plusParts[0];
    int? build = plusParts.length > 1 ? int.tryParse(plusParts[1]) : null;
    build ??= fallbackBuild;

    final segments = versionPart.split('.');
    final major = segments.isNotEmpty ? int.tryParse(segments[0]) ?? 0 : 0;
    final minor = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
    final patch = segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;

    return _VersionInfo(major, minor, patch, build ?? 0);
  }

  @override
  int compareTo(_VersionInfo other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }
}
