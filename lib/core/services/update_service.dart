import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;

  const UpdateInfo({required this.version, required this.downloadUrl});
}

class UpdateState {
  final bool isChecking;
  final bool isDownloading;
  final String? downloadProgress;
  final String? errorMessage;
  final UpdateInfo? updateAvailable;

  const UpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress,
    this.errorMessage,
    this.updateAvailable,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    String? downloadProgress,
    String? errorMessage,
    UpdateInfo? updateAvailable,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      updateAvailable: updateAvailable ?? this.updateAvailable,
    );
  }
}

class UpdateService extends StateNotifier<UpdateState> {
  static const _channel = MethodChannel('com.spendtrail.spendtrail/updater');
  static const _currentVersion = 'v1.0.4';

  UpdateService() : super(const UpdateState());

  // Check GitHub API for updates
  Future<UpdateInfo?> checkForUpdates() async {
    state = const UpdateState(isChecking: true);
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final url = Uri.parse('https://api.github.com/repos/Nithwik/spendtrail/releases/latest');
      final request = await client.getUrl(url);
      request.headers.add('User-Agent', 'SpendTrail-Updater');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(content);
        final tagName = data['tag_name'] as String? ?? '';
        final assets = data['assets'] as List? ?? [];

        // Compare tag names (e.g. v1.0.5 vs v1.0.4)
        if (tagName.isNotEmpty && tagName != _currentVersion) {
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String? ?? '').endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            final downloadUrl = apkAsset['browser_download_url'] as String;
            final info = UpdateInfo(version: tagName, downloadUrl: downloadUrl);
            state = UpdateState(updateAvailable: info);
            return info;
          }
        }
      }
      state = const UpdateState();
      return null;
    } catch (e) {
      state = UpdateState(errorMessage: 'Failed to reach updates server: $e');
      return null;
    }
  }

  // Download and trigger installation of APK
  Future<bool> downloadAndInstallUpdate(UpdateInfo info) async {
    state = state.copyWith(isDownloading: true, downloadProgress: '0%', errorMessage: null);
    try {
      final tempDir = Directory.systemTemp;
      final apkFile = File('${tempDir.path}/spendtrail-update.apk');
      
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(info.downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      int downloaded = 0;

      final iosSink = apkFile.openWrite();
      await response.forEach((chunk) {
        iosSink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          final progress = ((downloaded / contentLength) * 100).toStringAsFixed(0);
          state = state.copyWith(downloadProgress: '$progress%');
        }
      });

      await iosSink.flush();
      await iosSink.close();

      state = state.copyWith(downloadProgress: 'Launching installer...');

      // Dispatch to native channel
      final bool success = await _channel.invokeMethod<bool>('installApk', {'path': apkFile.path}) ?? false;
      state = const UpdateState();
      return success;
    } catch (e) {
      state = state.copyWith(isDownloading: false, errorMessage: 'Installation failed: $e');
      return false;
    }
  }
}

// Update service provider
final updateServiceProvider = StateNotifierProvider<UpdateService, UpdateState>((ref) {
  return UpdateService();
});
