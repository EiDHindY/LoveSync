import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String apkUrl;
  final bool hasUpdate;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.apkUrl,
    required this.hasUpdate,
  });
}

class UpdateService {
  static const String _repoOwner = 'EiDHindY';
  static const String _repoName = 'LoveSync';
  static const String _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : '1.0.1';
    } catch (_) {
      return '1.0.1';
    }
  }

  /// Checks GitHub Releases API for a newer version than current installed version.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'LoveSync-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final cleanLatest = rawTag.replaceFirst(RegExp(r'^[vV]'), '');
      final cleanCurrent = currentVersion.replaceFirst(RegExp(r'^[vV]'), '');

      final notes = (data['body'] as String? ?? '').trim();
      final assets = (data['assets'] as List<dynamic>? ?? []);

      // Find best APK: prefer arm64-v8a (smaller), fallback to universal, or any .apk
      String apkUrl = '';
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        final downloadUrl = asset['browser_download_url'] as String? ?? '';
        if (name.contains('arm64-v8a') && name.endsWith('.apk')) {
          apkUrl = downloadUrl;
          break;
        }
      }

      if (apkUrl.isEmpty) {
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          final downloadUrl = asset['browser_download_url'] as String? ?? '';
          if (name.contains('universal') && name.endsWith('.apk')) {
            apkUrl = downloadUrl;
            break;
          }
        }
      }

      if (apkUrl.isEmpty) {
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          final downloadUrl = asset['browser_download_url'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = downloadUrl;
            break;
          }
        }
      }

      final hasUpdate = isVersionGreater(cleanLatest, cleanCurrent);

      return AppUpdateInfo(
        latestVersion: cleanLatest,
        currentVersion: cleanCurrent,
        releaseNotes: notes,
        apkUrl: apkUrl,
        hasUpdate: hasUpdate,
      );
    } catch (e) {
      debugPrint('UpdateService check error: $e');
      return null;
    }
  }

  /// Semver comparison: returns true if v1 > v2.
  static bool isVersionGreater(String v1, String v2) {
    if (v1.isEmpty || v2.isEmpty) return false;
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    while (parts1.length < maxLen) {
      parts1.add(0);
    }
    while (parts2.length < maxLen) {
      parts2.add(0);
    }

    for (int i = 0; i < maxLen; i++) {
      if (parts1[i] > parts2[i]) return true;
      if (parts1[i] < parts2[i]) return false;
    }
    return false;
  }

  /// Starts downloading the APK and launching Android package installer via ota_update.
  static Stream<OtaEvent> startOtaUpdate(String apkUrl) {
    return OtaUpdate().execute(
      apkUrl,
      destinationFilename: 'LoveSync.apk',
    );
  }
}
