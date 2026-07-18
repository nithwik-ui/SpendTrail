import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final String publishedDate;
  final int? apkSize;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedDate,
    this.apkSize,
  });
}

class UpdateService {
  static const String _repoUrl = 'https://api.github.com/repos/${AppConfig.githubRepo}/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await Dio().get(_repoUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'] as String;
        final downloadUrl = data['html_url'] as String;
        final releaseNotes = data['body'] as String? ?? 'No release notes provided.';
        final publishedDate = data['published_at'] as String? ?? '';
        
        int? apkSize;
        if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
          final asset = (data['assets'] as List).firstWhere(
            (a) => (a['name'] as String).endsWith('.apk'), 
            orElse: () => null
          );
          if (asset != null) {
            apkSize = asset['size'] as int?;
          }
        }
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        
        final normalizedLatest = latestVersion.replaceAll('v', '');
        
        if (_isNewerVersion(currentVersion, normalizedLatest)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: normalizedLatest,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
            publishedDate: publishedDate,
            apkSize: apkSize,
          );
        }
      }
    } catch (e) {
      // Failed to check for update, ignore silently
    }
    return null;
  }
  
  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
  
  static Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
