import 'package:flutter/material.dart';
import 'package:love_app/core/services/notification_service.dart';
import 'package:love_app/core/services/sound_service.dart';
import 'package:love_app/core/theme/app_theme.dart';

class SoundPickerModal extends StatefulWidget {
  final String currentSoundId;
  final ValueChanged<String> onSelectSound;
  final String title;
  final String subtitle;
  final String headerIcon;
  final List<SoundOption>? options;
  final String testTitle;
  final String testBody;
  final int testId;

  const SoundPickerModal({
    super.key,
    required this.currentSoundId,
    required this.onSelectSound,
    this.title = 'Spark Match Sound',
    this.subtitle = 'Pick the chime that plays when mutual spark ignites',
    this.headerIcon = '🎵',
    this.options,
    this.testTitle = "It's a Match! 🔥",
    this.testBody = "Both of you are in the mood tonight! The spark is ignited.",
    this.testId = 1,
  });

  @override
  State<SoundPickerModal> createState() => _SoundPickerModalState();
}

class _SoundPickerModalState extends State<SoundPickerModal> {
  late String _selectedId;
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentSoundId;
  }

  @override
  void dispose() {
    SoundService().stop();
    super.dispose();
  }

  Future<void> _previewSound(String id) async {
    setState(() {
      _currentlyPlayingId = id;
    });
    await SoundService().playSound(id);
    if (mounted) {
      // Allow visual animation of playing state for ~2.2 seconds
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _currentlyPlayingId == id) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
      });
    }
  }

  void _testNotification() {
    NotificationService().showNotification(
      id: widget.testId,
      title: widget.testTitle,
      body: widget.testBody,
      soundId: _selectedId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final soundList = widget.options ?? kSparkSoundOptions;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.blush,
                  shape: BoxShape.circle,
                ),
                child: Text(widget.headerIcon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.plum,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Sound Options List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: soundList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = soundList[index];
                final isSelected = _selectedId == option.id;
                final isPlaying = _currentlyPlayingId == option.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedId = option.id;
                    });
                    widget.onSelectSound(option.id);
                    _previewSound(option.id);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFF0F3) : AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppTheme.crimson : Colors.grey.shade200,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.crimson.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Sound emoji badge
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppTheme.blush,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.crimson.withValues(alpha: 0.3) : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              option.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    option.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? AppTheme.crimson : AppTheme.plum,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppTheme.crimson,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                option.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? AppTheme.plum.withValues(alpha: 0.75) : AppTheme.onSurfaceVariant,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Play / Preview button
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.volume_up_rounded : Icons.play_circle_fill_rounded,
                            color: isPlaying
                                ? AppTheme.crimson
                                : (isSelected ? AppTheme.crimson : Colors.grey.shade600),
                            size: 32,
                          ),
                          tooltip: 'Preview sound',
                          onPressed: () {
                            setState(() {
                              _selectedId = option.id;
                            });
                            widget.onSelectSound(option.id);
                            _previewSound(option.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Action buttons: Test Full Notification & Done
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text('Test Alert'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.crimson,
                    side: const BorderSide(color: AppTheme.crimson),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _testNotification,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimson,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
