import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:love_app/core/config/supabase_config.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isSaving = false;
  bool _savedToGallery = false;

  String get _effectiveUrl {
    if (widget.imageUrl.startsWith('http://') || widget.imageUrl.startsWith('https://')) {
      return widget.imageUrl;
    }
    if (SupabaseConfig.isInitialized) {
      return Supabase.instance.client.storage.from('chat_images').getPublicUrl(widget.imageUrl);
    }
    return widget.imageUrl;
  }

  @override
  void initState() {
    super.initState();
    _autoSaveToGallery();
  }

  Future<void> _autoSaveToGallery() async {
    if (kIsWeb) return;
    if (widget.imageUrl.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      Uint8List? imageBytes;

      // 1. Try downloading via Supabase storage client if available
      if (SupabaseConfig.isInitialized) {
        try {
          final client = Supabase.instance.client;
          String path = widget.imageUrl;
          if (path.contains('/chat_images/')) {
            path = path.split('/chat_images/').last.split('?').first;
          }
          imageBytes = await client.storage.from('chat_images').download(path);
        } catch (e) {
          debugPrint('Notice downloading from Supabase storage: $e');
        }
      }

      // 2. Fallback to HTTP GET using resolved URL
      if (imageBytes == null || imageBytes.isEmpty) {
        final url = _effectiveUrl;
        if (url.startsWith('http')) {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        }
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        await Gal.putImageBytes(
          imageBytes,
          album: 'LoveSync',
          name: 'LoveSync_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (mounted) {
          setState(() {
            _savedToGallery = true;
            _isSaving = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSaving = false);
      }
    } catch (e) {
      debugPrint('Notice auto-saving photo to gallery: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                          const Text(
                            'View-Once Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              if (_isSaving) ...[
                                const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white70),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Saving to Gallery...',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ] else if (_savedToGallery) ...[
                                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'Saved to Gallery (LoveSync) ✓',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                const Icon(Icons.local_fire_department_rounded, color: AppTheme.crimson, size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'Burns after viewing · Zero cloud storage',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_savedToGallery && !kIsWeb)
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.greenAccent, size: 24),
                        tooltip: 'Open in Phone Gallery',
                        onPressed: () => Gal.open(),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 24),
                        tooltip: 'Share photo',
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(uri: Uri.parse(_effectiveUrl)),
                          );
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
                      _effectiveUrl,
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
                    _savedToGallery
                        ? '✓ Photo saved to your phone\'s Gallery. Closing will permanently delete it from chat and cloud storage.'
                        : 'Closing this screen will permanently delete the photo from cloud storage.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.3,
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
