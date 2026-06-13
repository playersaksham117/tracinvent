import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/update_info.dart';

/// GitHub-based auto-update service for BillEase POS Mobile (Windows).
class GitHubUpdateService {
  static const String githubOwner = 'playersaksham117';
  static const String githubRepo = 'tracinvent';
  static const String releaseTagPrefix = 'billease-pos-mobile-v';
  static const String currentVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static String get _releasesApiUrl =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';

  static Future<GitHubRelease?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_releasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BillEasePOSMobile-App',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('GitHub API error (${response.statusCode})');
      }

      final releases = jsonDecode(response.body) as List<dynamic>;
      final current = AppVersion.fromString(currentVersion);

      for (final item in releases) {
        final release = GitHubRelease.fromJson(item as Map<String, dynamic>);
        if (!release.tagName.startsWith(releaseTagPrefix) || release.prerelease) {
          continue;
        }

        final latest = AppVersion.fromString(release.version);
        if (latest.isNewerThan(current)) {
          return release;
        }
        break;
      }

      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      rethrow;
    }
  }

  static Future<String?> downloadUpdate(
    GitHubAsset asset,
    void Function(int received, int total)? onProgress,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = p.join(directory.path, asset.name);

      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        final existingSize = await existingFile.length();
        if (existingSize == asset.size) {
          return filePath;
        }
        await existingFile.delete();
      }

      final request = http.Request('GET', Uri.parse(asset.browserDownloadUrl));
      request.headers['Accept'] = 'application/octet-stream';
      request.headers['User-Agent'] = 'BillEasePOSMobile-App';

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final file = File(filePath);
      final sink = file.openWrite();
      var received = 0;
      final total = response.contentLength ?? asset.size;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      await sink.close();
      client.close();
      return filePath;
    } catch (e) {
      debugPrint('Error downloading update: $e');
      rethrow;
    }
  }

  static Future<bool> installUpdate(String installerPath) async {
    try {
      final file = File(installerPath);
      if (!await file.exists()) {
        throw Exception('Installer file not found');
      }

      final extension = p.extension(installerPath).toLowerCase();

      if (extension == '.exe') {
        await Process.start(
          installerPath,
          ['/SILENT', '/CLOSEAPPLICATIONS'],
          mode: ProcessStartMode.detached,
        );
        await Future.delayed(const Duration(seconds: 2));
        exit(0);
      } else if (extension == '.msix' || extension == '.msixbundle') {
        final result = await Process.run(
          'powershell',
          [
            '-Command',
            'Add-AppxPackage -Path "$installerPath" -ForceApplicationShutdown',
          ],
        );
        if (result.exitCode == 0) {
          exit(0);
        }
        throw Exception('MSIX installation failed: ${result.stderr}');
      } else if (extension == '.zip') {
        return _installFromZip(installerPath);
      }

      throw Exception('Unsupported installer format: $extension');
    } catch (e) {
      debugPrint('Error installing update: $e');
      rethrow;
    }
  }

  static Future<bool> _installFromZip(String zipPath) async {
    try {
      final appDir = File(Platform.resolvedExecutable).parent;
      final backupDir = Directory(
        p.join(appDir.parent.path, 'backup_${DateTime.now().millisecondsSinceEpoch}'),
      );

      final scriptPath = p.join(
        (await getTemporaryDirectory()).path,
        'update_billease_pos_mobile.bat',
      );
      final script = '''
@echo off
echo Waiting for application to close...
timeout /t 3 /nobreak > nul

echo Creating backup...
xcopy "${appDir.path}" "${backupDir.path}" /E /I /H /Y

echo Extracting update...
powershell -Command "Expand-Archive -Path '$zipPath' -DestinationPath '${appDir.path}' -Force"

echo Starting updated application...
start "" "${Platform.resolvedExecutable}"

echo Cleaning up...
del "$zipPath"
del "%~f0"
''';

      await File(scriptPath).writeAsString(script);
      await Process.start('cmd', ['/c', scriptPath], mode: ProcessStartMode.detached);
      await Future.delayed(const Duration(seconds: 1));
      exit(0);
    } catch (e) {
      debugPrint('Error installing from ZIP: $e');
      return false;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String get versionString => 'v$currentVersion';
}

class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final bool prerelease;
  final DateTime publishedAt;
  final List<GitHubAsset> assets;
  final String htmlUrl;

  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.prerelease,
    required this.publishedAt,
    required this.assets,
    required this.htmlUrl,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      prerelease: json['prerelease'] ?? false,
      publishedAt: DateTime.parse(
        json['published_at'] ?? DateTime.now().toIso8601String(),
      ),
      htmlUrl: json['html_url'] ?? '',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => GitHubAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  GitHubAsset? get windowsAsset {
    for (final ext in ['.exe', '.msix', '.msixbundle', '.zip']) {
      for (final asset in assets) {
        final name = asset.name.toLowerCase();
        if (!name.endsWith(ext)) continue;
        if (name.contains('billease') ||
            name.contains('windows') ||
            name.contains('win') ||
            name.contains('x64')) {
          return asset;
        }
      }
    }

    for (final asset in assets) {
      final name = asset.name.toLowerCase();
      if (name.endsWith('.exe') || name.endsWith('.zip')) {
        return asset;
      }
    }
    return null;
  }

  String get version => tagName.replaceFirst(GitHubUpdateService.releaseTagPrefix, '');
}

class GitHubAsset {
  final int id;
  final String name;
  final String contentType;
  final int size;
  final int downloadCount;
  final String browserDownloadUrl;

  GitHubAsset({
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
    required this.downloadCount,
    required this.browserDownloadUrl,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      contentType: json['content_type'] ?? '',
      size: json['size'] ?? 0,
      downloadCount: json['download_count'] ?? 0,
      browserDownloadUrl: json['browser_download_url'] ?? '',
    );
  }

  String get formattedSize => GitHubUpdateService.formatBytes(size);
}
