import 'package:flutter/material.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class ViewOncePhotoViewer extends StatefulWidget {
  final String imageUrl;
  final String senderName;
  final VoidCallback onBurn;

  const ViewOncePhotoViewer({
    super.key,
    required this.imageUrl,
    required this.senderName,
    required this.onBurn,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String senderName,
    required VoidCallback onBurn,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => ViewOncePhotoViewer(
          imageUrl: imageUrl,
          senderName: senderName,
          onBurn: onBurn,
        ),
      ),
    );
  }

  @override
  State<ViewOncePhotoViewer> createState() => _ViewOncePhotoViewerState();
}

class _ViewOncePhotoViewerState extends State<ViewOncePhotoViewer> {
  bool _burned = false;

  void _closeAndBurn() {
    if (!_burned) {
      _burned = true;
      widget.onBurn();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeAndBurn();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: _closeAndBurn,
                      tooltip: 'Close and burn',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View-Once Photo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.local_fire_department_rounded, color: AppTheme.crimson, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Burns after viewing · Zero cloud storage',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 24),
                      tooltip: 'Save or share photo',
                      onPressed: () {
                        Share.shareUri(Uri.parse(widget.imageUrl));
                      },
                    ),
                  ],
                ),
              ),

              // Image Area with Zoom
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppTheme.crimson,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Photo already expired or unavailable',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Footer Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: Colors.black87,
                child: Center(
                  child: Text(
                    'Closing this screen will permanently delete the photo from cloud storage.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
