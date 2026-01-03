import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Dio _dio = Dio();

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get current version info
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.parse(packageInfo.buildNumber);

      // 2. Get latest version from backend
      // Use local IP for testing if needed, or stick to ApiService.baseUrl
      final String updateUrl = '${ApiService.baseUrl}/app/latest/';
      debugPrint('UpdateCheck: Checking at $updateUrl');
      debugPrint('UpdateCheck: Current build number is $currentVersionCode');
      
      final response = await _dio.get(updateUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        int latestVersionCode = data['version_code'] ?? 0;
        debugPrint('UpdateCheck: Latest build number on server is $latestVersionCode');
        
        // CRITICAL: Only proceed if server has a HIGHER version code
        if (latestVersionCode > currentVersionCode) {
          String latestVersionName = data['version_name'] ?? '1.0.0';
          String? apkUrl = data['apk_url'];
          
          if (apkUrl == null || apkUrl.isEmpty) {
            debugPrint('UpdateCheck: New version found but APK URL is empty. Skipping.');
            return;
          }
          
          bool isForceUpdate = data['is_force_update'] ?? false;
          String releaseNotes = data['release_notes'] ?? 'New version available';

          debugPrint('UpdateCheck: Triggering update dialog for $latestVersionName');
          if (context.mounted) {
            _showUpdateDialog(context, latestVersionName, apkUrl, isForceUpdate, releaseNotes);
          }
        } else {
          debugPrint('UpdateCheck: App is up to date ($currentVersionCode >= $latestVersionCode)');
        }
      }
    } catch (e) {
      debugPrint('UpdateCheck: Silent failure (network or server issue): $e');
    }
  }

  void _showUpdateDialog(BuildContext context, String versionName, String apkUrl, bool isForceUpdate, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => PopScope(
        canPop: !isForceUpdate,
        child: AlertDialog(
          title: Text('Update Available ($versionName)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isForceUpdate 
                  ? 'A critical update is required to continue using the app.' 
                  : 'A new version is available. Update now to get the latest features.',
              ),
              const SizedBox(height: 12),
              Text('What\'s New:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(releaseNotes, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ),
              ),
            ],
          ),
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _downloadAndInstallApk(context, apkUrl);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndInstallApk(BuildContext context, String url) async {
    try {
      // 1. Request Permissions
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        // For Android 13+ (SDK 33+), storage permission might behave differently, 
        // but we mainly need RequestInstallPackages which is usually handled by the OS when opening APK.
        // However, we need to save the file first.
      }

      // 2. Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DownloadProgressDialog(),
      );

      // 3. Download APK
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/skaagpay_update.apk';
      
      await _dio.download(
        url, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            updateDownloadProgress(received / total);
          }
        },
      );

      // 4. Close progress dialog
      Navigator.pop(context);

      // 5. Open APK
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('Error opening APK: ${result.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening APK: ${result.message}')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close progress dialog
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  // Helper for progress notification
  static Function(double)? onProgressUpdate;
  void updateDownloadProgress(double progress) {
    if (onProgressUpdate != null) {
      onProgressUpdate!(progress);
    }
  }
}

class DownloadProgressDialog extends StatefulWidget {
  const DownloadProgressDialog({super.key});

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    UpdateService.onProgressUpdate = (progress) {
      setState(() {
        _progress = progress;
      });
    };
  }

  @override
  void dispose() {
    UpdateService.onProgressUpdate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading Update...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 10),
          Text('${(_progress * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}
