import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:love_app/core/services/update_service.dart';
import 'package:love_app/core/theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => UpdateDialog(updateInfo: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  bool _installerLaunched = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    if (widget.updateInfo.apkUrl.isEmpty) {
      _openBrowserFallback();
      return;
    }

    setState(() {
      _isDownloading = true;
      _installerLaunched = false;
      _errorMessage = null;
      _progress = 0.0;
      _statusText = 'Starting download...';
    });

    try {
      _otaSubscription = UpdateService.startOtaUpdate(widget.updateInfo.apkUrl).listen(
        (OtaEvent event) {
          if (!mounted) return;
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final percent = double.tryParse(event.value ?? '0') ?? 0.0;
              setState(() {
                _progress = (percent / 100.0).clamp(0.0, 1.0);
                _statusText = 'Downloading update... ${percent.toInt()}%';
              });
              break;
            case OtaStatus.INSTALLING:
              setState(() {
                _progress = 1.0;
                _isDownloading = false;
                _installerLaunched = true;
                _statusText = 'Installer launched! Please confirm the prompt on your screen.';
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _errorMessage = 'An update is already running in background.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _errorMessage = 'Install permission not granted. Please allow unknown apps.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            default:
              setState(() {
                _errorMessage = 'Download failed (${event.status.name}). You can download directly via browser.';
                _isDownloading = false;
              });
              break;
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Update error: $e';
            _isDownloading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not start in-app update: $e';
        _isDownloading = false;
      });
    }
  }

  Future<void> _openBrowserFallback() async {
    final uri = Uri.parse(
      widget.updateInfo.apkUrl.isNotEmpty
          ? widget.updateInfo.apkUrl
          : 'https://github.com/EiDHindY/LoveSync/releases/latest',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Icon with glowing badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.blush,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.crimson.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.system_update_rounded,
                size: 32,
                color: AppTheme.crimson,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Update Available! 🚀',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            const SizedBox(height: 6),

            // Version difference badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.blush),
              ),
              child: Text(
                'v${info.currentVersion}  ➔  v${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.crimson,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Downloading Progress Indicator
            if (_isDownloading || _installerLaunched) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: AppTheme.blush,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.crimson),
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.plum,
                ),
              ),
              if (_progress >= 0.9) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _openBrowserFallback,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                  label: const Text('Installer not opening? Tap for direct download', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.crimson,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],

            // Installer guidance notice
            if (_installerLaunched) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Installer Prompted',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      'If Android reports an incompatible update signature, uninstall the older build once to migrate to the permanent release key.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Error display if any
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _openBrowserFallback,
                      icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                      label: const Text('Download via Browser', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Action Buttons
            Row(
              children: [
                if (!_isDownloading)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _installerLaunched ? 'Close' : 'Later',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (!_isDownloading) const SizedBox(width: 10),
                Expanded(
                  flex: _isDownloading ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _isDownloading
                          ? 'Updating...'
                          : _installerLaunched
                              ? 'Retry Install'
                              : 'Update Now',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
