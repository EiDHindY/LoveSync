import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/chat/presentation/dm_chat_view.dart';
import 'package:love_app/features/memories/domain/couple_memory.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';

enum MemoryFilter { all, sparks, dates, chat }

enum ClearTarget { sparks, dates, both }

class MemoriesInboxModal extends ConsumerStatefulWidget {
  final List<CoupleMemory> memories;
  final List<ScheduledIntimacy>? scheduledDates;
  final Future<void> Function()? onClearAll;
  final Future<void> Function()? onClearSparks;
  final Future<void> Function()? onClearDates;
  final VoidCallback? onOpenPairing;
  final MemoryFilter initialFilter;

  const MemoriesInboxModal({
    super.key,
    required this.memories,
    this.scheduledDates,
    this.onClearAll,
    this.onClearSparks,
    this.onClearDates,
    this.onOpenPairing,
    this.initialFilter = MemoryFilter.all,
  });

  @override
  ConsumerState<MemoriesInboxModal> createState() => _MemoriesInboxModalState();
}

class _MemoriesInboxModalState extends ConsumerState<MemoriesInboxModal> {
  late MemoryFilter _selectedFilter;
  bool _hasModifiedState = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

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

  String _formatScheduledTime(DateTime dt) {
    return DateFormat('EEEE, MMM d · h:mm a').format(dt);
  }

  String _formatCountdown(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return 'Completed';
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0) return '${hours}h, ${mins}m left';
    return '${mins}m left';
  }

  @override
  Widget build(BuildContext context) {
    final providerMemories = ref.watch(coupleMemoriesProvider);
    final providerDates = ref.watch(scheduledDatesProvider);
    final activeMemories = _hasModifiedState || providerMemories.isNotEmpty
        ? providerMemories
        : widget.memories;
    final activeScheduledDates = _hasModifiedState || providerDates.isNotEmpty
        ? providerDates
        : (widget.scheduledDates ?? []);

    // Separate into two distinct sections: Mutual Sparks & Scheduled Dates
    final sparkMemories = activeMemories.where((m) => m.type.startsWith('spark')).toList();
    final dateMemories = activeMemories.where((m) => !m.type.startsWith('spark')).toList();

    // Deduplicate scheduled dates so dates already represented as dateMemories aren't doubled
    final List<ScheduledIntimacy> nonDuplicateScheduled = [];
    for (final date in activeScheduledDates) {
      final dateDayStr = DateFormat('EEE, MMM d').format(date.scheduledAt);
      final alreadyLogged = dateMemories.any((m) => m.windowKey == dateDayStr);
      if (!alreadyLogged) {
        nonDuplicateScheduled.add(date);
      }
    }

    final totalDateItems = dateMemories.length + nonDuplicateScheduled.length;
    final totalMoments = activeMemories.length + nonDuplicateScheduled.length;
    final isEmpty = totalMoments == 0;
    final unreadChatCount = ref.watch(unreadChatCountProvider);
    final isChatTab = _selectedFilter == MemoryFilter.chat;

    return Container(
      height: MediaQuery.of(context).size.height * (isChatTab ? 0.94 : 0.80),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
          if (!isChatTab)
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
                          isEmpty
                              ? 'Your shared intimacy timeline'
                              : '$totalMoments documented moment${totalMoments == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isEmpty && (widget.onClearAll != null || widget.onClearSparks != null || widget.onClearDates != null))
                    IconButton(
                      tooltip: 'Clear items',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                      onPressed: () async {
                        ClearTarget selectedTarget = (_selectedFilter == MemoryFilter.dates)
                            ? ClearTarget.dates
                            : (_selectedFilter == MemoryFilter.sparks)
                                ? ClearTarget.sparks
                                : ClearTarget.both;

                        final chosenTarget = await showDialog<ClearTarget>(
                          context: context,
                          builder: (dialogCtx) => StatefulBuilder(
                            builder: (ctx, setDialogState) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.blush,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_sweep_rounded, color: AppTheme.crimson, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Clear Inbox Items',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.plum),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose what you would like to clear:',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 14),

                                    // Option 1: Mutual Sparks
                                    _buildClearOptionTile(
                                      title: 'Mutual Sparks',
                                      subtitle: '${sparkMemories.length} spark moment${sparkMemories.length == 1 ? '' : 's'}',
                                      icon: Icons.local_fire_department_rounded,
                                      iconColor: const Color(0xFFF97316),
                                      target: ClearTarget.sparks,
                                      isSelected: selectedTarget == ClearTarget.sparks,
                                      onTap: () => setDialogState(() => selectedTarget = ClearTarget.sparks),
                                    ),
                                    const SizedBox(height: 8),

                                    // Option 2: Scheduled Dates
                                    _buildClearOptionTile(
                                      title: 'Scheduled Dates',
                                      subtitle: '$totalDateItems scheduled date${totalDateItems == 1 ? '' : 's'} & proposals',
                                      icon: Icons.event_available_rounded,
                                      iconColor: AppTheme.crimson,
                                      target: ClearTarget.dates,
                                      isSelected: selectedTarget == ClearTarget.dates,
                                      onTap: () => setDialogState(() => selectedTarget = ClearTarget.dates),
                                    ),
                                    const SizedBox(height: 8),

                                    // Option 3: Both
                                    _buildClearOptionTile(
                                      title: 'Both (Sparks & Dates)',
                                      subtitle: '$totalMoments total documented moment${totalMoments == 1 ? '' : 's'}',
                                      icon: Icons.auto_awesome_rounded,
                                      iconColor: const Color(0xFF8B5CF6),
                                      target: ClearTarget.both,
                                      isSelected: selectedTarget == ClearTarget.both,
                                      onTap: () => setDialogState(() => selectedTarget = ClearTarget.both),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(null),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.crimson,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(selectedTarget),
                                    child: Text(
                                      selectedTarget == ClearTarget.sparks
                                          ? 'Clear Sparks'
                                          : selectedTarget == ClearTarget.dates
                                              ? 'Clear Dates'
                                              : 'Clear Both',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );

                        if (chosenTarget != null) {
                          if (chosenTarget == ClearTarget.sparks) {
                            if (widget.onClearSparks != null) {
                              await widget.onClearSparks!();
                            } else if (widget.onClearAll != null) {
                              await widget.onClearAll!();
                            }
                          } else if (chosenTarget == ClearTarget.dates) {
                            if (widget.onClearDates != null) {
                              await widget.onClearDates!();
                            } else if (widget.onClearAll != null) {
                              await widget.onClearAll!();
                            }
                          } else if (chosenTarget == ClearTarget.both) {
                            if (widget.onClearAll != null) {
                              await widget.onClearAll!();
                            }
                          }
                          setState(() {
                            _hasModifiedState = true;
                          });
                        }
                      },
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),
          // Filter Segment Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill(
                    label: 'Direct Chat',
                    filter: MemoryFilter.chat,
                    icon: Icons.chat_bubble_rounded,
                    badgeCount: unreadChatCount,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: 'Mutual Sparks (${sparkMemories.length})',
                    filter: MemoryFilter.sparks,
                    icon: Icons.local_fire_department_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: 'Scheduled Dates ($totalDateItems)',
                    filter: MemoryFilter.dates,
                    icon: Icons.event_available_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: 'All ($totalMoments)',
                    filter: MemoryFilter.all,
                    icon: Icons.auto_awesome_rounded,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 16),

          // Content Area
          if (isChatTab)
            Expanded(
              child: DmChatView(
                onClose: () => setState(() => _selectedFilter = MemoryFilter.all),
                onOpenPairing: widget.onOpenPairing,
              ),
            )
          else
            Expanded(
              child: isEmpty
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
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    children: [
                      // ══════════════════════════════════════════════
                      // SECTION 1: MUTUAL SPARKS
                      // ══════════════════════════════════════════════
                      if (_selectedFilter == MemoryFilter.all || _selectedFilter == MemoryFilter.sparks) ...[
                        _buildSectionHeader(
                          title: 'MUTUAL SPARKS',
                          count: sparkMemories.length,
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF1E56),
                          bgColor: const Color(0xFFFFECEF),
                        ),
                        const SizedBox(height: 8),
                        if (sparkMemories.isEmpty)
                          _buildEmptySectionCard(
                            message: 'No mutual sparks documented yet.\nLight your spark and match to ignite your first memory.',
                            icon: Icons.local_fire_department_outlined,
                          )
                        else
                          ...sparkMemories.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildSparkMemoryCard(m),
                              )),
                        const SizedBox(height: 16),
                      ],

                      // ══════════════════════════════════════════════
                      // SECTION 2: SCHEDULED DATES
                      // ══════════════════════════════════════════════
                      if (_selectedFilter == MemoryFilter.all || _selectedFilter == MemoryFilter.dates) ...[
                        _buildSectionHeader(
                          title: 'SCHEDULED DATES',
                          count: totalDateItems,
                          icon: Icons.event_available_rounded,
                          iconColor: const Color(0xFF8B1E78),
                          bgColor: const Color(0xFFF9E8F5),
                        ),
                        const SizedBox(height: 8),
                        if (totalDateItems == 0)
                          _buildEmptySectionCard(
                            message: 'No scheduled dates yet.\nPlan a rendezvous in Date Night to log a date milestone.',
                            icon: Icons.event_outlined,
                          )
                        else ...[
                          ...dateMemories.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildDateMemoryCard(m),
                              )),
                          ...nonDuplicateScheduled.map((date) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildScheduledIntimacyCard(date),
                              )),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required MemoryFilter filter,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.plum : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.plum : AppTheme.blush,
            width: 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.plum.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.plum,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.plum,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.crimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.plum,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard({required String message, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkMemoryCard(CoupleMemory item) {
    final isCelebrated = item.type == 'spark_celebrated';
    final isCanceled = item.type == 'spark_canceled';

    Color cardBg;
    Color borderColor;
    Color iconBg;
    Widget iconWidget;

    if (isCanceled) {
      cardBg = const Color(0xFFFAF9F9);
      borderColor = Colors.grey.shade300;
      iconBg = Colors.grey.shade200;
      iconWidget = const Icon(Icons.close_rounded, size: 18, color: Colors.grey);
    } else if (isCelebrated) {
      cardBg = const Color(0xFFFFF9F9);
      borderColor = AppTheme.roseGold.withValues(alpha: 0.6);
      iconBg = const Color(0xFFFFDF7D).withValues(alpha: 0.3);
      iconWidget = const Text('🎉', style: TextStyle(fontSize: 19));
    } else {
      cardBg = const Color(0xFFFFF0F3);
      borderColor = const Color(0xFFFFB3C1);
      iconBg = const Color(0xFFFF1E56).withValues(alpha: 0.12);
      iconWidget = const Text('🔥', style: TextStyle(fontSize: 19));
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.4,
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
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: iconWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isCanceled ? Colors.grey.shade800 : AppTheme.plum,
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
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (item.windowKey != null) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      item.windowKey!,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.4,
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
  }

  Widget _buildDateMemoryCard(CoupleMemory item) {
    final isCanceled = item.type == 'date_canceled';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCanceled ? const Color(0xFFFFF9FA) : const Color(0xFFFBF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCanceled ? const Color(0xFFF0CCD7) : const Color(0xFFD4B0E5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCanceled ? const Color(0xFFC70039) : const Color(0xFF9C27B0)).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isCanceled
                  ? const Color(0xFFC70039).withValues(alpha: 0.12)
                  : const Color(0xFF9C27B0).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCanceled ? Icons.event_busy_rounded : Icons.event_available_rounded,
              size: 20,
              color: isCanceled ? const Color(0xFFC70039) : const Color(0xFF8B1E78),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isCanceled ? AppTheme.crimson : AppTheme.plum,
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
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (item.windowKey != null) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      item.windowKey!,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.4,
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
  }

  Widget _buildScheduledIntimacyCard(ScheduledIntimacy date) {
    final isAccepted = date.status == IntimacyStatus.accepted;
    final isCompleted = date.status == IntimacyStatus.completed;
    final isPending = date.status == IntimacyStatus.pending;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isCompleted) {
      badgeBg = Colors.grey.shade200;
      badgeText = Colors.grey.shade700;
      badgeLabel = 'COMPLETED';
    } else if (isAccepted) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
      badgeLabel = 'ACCEPTED';
    } else if (isPending) {
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = const Color(0xFFE65100);
      badgeLabel = 'PENDING';
    } else {
      badgeBg = AppTheme.blush;
      badgeText = AppTheme.crimson;
      badgeLabel = date.status.name.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4B0E5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF8B1E78)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatScheduledTime(date.scheduledAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.plum,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date.responseNote?.isNotEmpty == true
                      ? 'Note: ${date.responseNote}'
                      : 'Romantic rendezvous aligned with cycle bio-rhythm.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatCountdown(date.scheduledAt),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required ClearTarget target,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.blush.withValues(alpha: 0.5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.crimson : Colors.grey.shade200,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.plum : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.crimson : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
