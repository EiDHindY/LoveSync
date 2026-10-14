import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/memories/domain/couple_memory.dart';

class MemoriesInboxModal extends StatelessWidget {
  final List<CoupleMemory> memories;

  const MemoriesInboxModal({
    super.key,
    required this.memories,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday • ${DateFormat('h:mm a').format(dt)}';
    if (diff.inDays < 7) return '${DateFormat('EEEE').format(dt)} • ${DateFormat('h:mm a').format(dt)}';
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B0029), Color(0xFFC70039)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC70039).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Memories & Spark Inbox',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.plum,
                        ),
                      ),
                      Text(
                        memories.isEmpty
                            ? 'Your shared intimacy timeline'
                            : '${memories.length} documented moment${memories.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Content List
          Expanded(
            child: memories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.blush.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('💌', style: TextStyle(fontSize: 40)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Memories Yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.plum,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When both of you light your spark and celebrate, or plan a date night, every milestone will be preserved here so you never forget.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    itemCount: memories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = memories[index];
                      final isCelebrated = item.type == 'spark_celebrated';
                      final isMatch = item.type == 'spark_match';
                      final isDate = item.type == 'date_night' || item.type == 'date_accepted';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCelebrated
                              ? const Color(0xFFFFF9F9)
                              : isMatch
                                  ? const Color(0xFFFFF0F3)
                                  : isDate
                                      ? const Color(0xFFFBF6FF)
                                      : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCelebrated
                                ? AppTheme.roseGold.withValues(alpha: 0.5)
                                : isMatch
                                    ? const Color(0xFFFFB3C1)
                                    : isDate
                                        ? const Color(0xFFD4B0E5)
                                        : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCelebrated
                                    ? const Color(0xFFFFDF7D).withValues(alpha: 0.25)
                                    : isMatch
                                        ? const Color(0xFFFF1E56).withValues(alpha: 0.12)
                                        : isDate
                                            ? const Color(0xFF9C27B0).withValues(alpha: 0.12)
                                            : AppTheme.blush,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                isCelebrated
                                    ? '🎉'
                                    : isMatch
                                        ? '🔥'
                                        : isDate
                                            ? '📅'
                                            : '💕',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.plum,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTime(item.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (item.windowKey != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        item.windowKey!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
