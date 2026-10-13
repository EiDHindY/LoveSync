import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';

class ScheduledDateCard extends StatelessWidget {
  final ScheduledIntimacy? dateItem;
  final String currentUserId;
  final DateTime? lastPeriodStartDate;
  final int cycleLength;
  final int periodLength;
  final int safetyBufferDays;
  final VoidCallback onOpenScheduleModal;
  final Function(String id, IntimacyStatus status) onRespond;
  final Function(String id, VibeCheckStatus status) onRespondVibeCheck;

  const ScheduledDateCard({
    super.key,
    required this.dateItem,
    required this.currentUserId,
    required this.lastPeriodStartDate,
    required this.cycleLength,
    required this.periodLength,
    required this.safetyBufferDays,
    required this.onOpenScheduleModal,
    required this.onRespond,
    required this.onRespondVibeCheck,
  });

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    if (dateItem == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.blush, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, color: AppTheme.crimson, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PLAN AHEAD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.plum.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'No upcoming intimacy date scheduled.',
              style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenScheduleModal,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Schedule Date Night'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepBerry,
                  side: const BorderSide(color: AppTheme.roseGold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final date = dateItem!;
    final dateFormatted = DateFormat('EEEE, MMM d @ h:mm a').format(date.scheduledAt);
    final isOwner = date.proposedBy == currentUserId;
    final isDateToday = _isToday(date.scheduledAt);

    final fertility = CycleEngine.calculateFertility(
      targetDate: date.scheduledAt,
      lastPeriodStartDate: lastPeriodStartDate,
      cycleLength: cycleLength,
      periodLength: periodLength,
      safetyBufferDays: safetyBufferDays,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: date.status == IntimacyStatus.accepted
              ? AppTheme.roseGold
              : AppTheme.blush,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blush.withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, size: 18, color: AppTheme.crimson),
                  const SizedBox(width: 8),
                  Text(
                    'DATE NIGHT INVITATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppTheme.plum.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              _buildStatusPill(date.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            dateFormatted,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.plum,
            ),
          ),
          const SizedBox(height: 8),

          // Fertility Badge for that day
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fertility.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fertility.icon, size: 14, color: fertility.color),
                const SizedBox(width: 6),
                Text(
                  'Projected: ${fertility.title}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fertility.color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Day-Of Vibe Check-in Card
          if (isDateToday && date.status == IntimacyStatus.accepted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.spa, size: 18, color: AppTheme.crimson),
                      SizedBox(width: 8),
                      Text(
                        'Gentle Day-Of Vibe Check',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Date is tonight! Still feeling the spark, or exhausted from the day?",
                    style: TextStyle(fontSize: 12, color: Color(0xFF444444)),
                  ),
                  const SizedBox(height: 10),
                  if (date.vibeCheckStatus == VibeCheckStatus.confirmed)
                    const Text(
                      '✨ Confirmed! Looking forward to tonight 🔥',
                      style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold),
                    )
                  else if (date.vibeCheckStatus == VibeCheckStatus.convertedCuddle)
                    const Text(
                      '🫂 Soft evening planned: Warm cuddles & movie night instead!',
                      style: TextStyle(color: Color(0xFF6B113B), fontWeight: FontWeight.bold),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.crimson,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => onRespondVibeCheck(date.id, VibeCheckStatus.confirmed),
                            child: const Text('Still on! 🔥', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () =>
                                onRespondVibeCheck(date.id, VibeCheckStatus.convertedCuddle),
                            child: const Text('Cuddle instead 🫂', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ] else if (date.status == IntimacyStatus.pending && !isOwner) ...[
            // Guilt-Free Response Actions
            const Text(
              'Your partner proposed this date. How are you feeling?',
              style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBerry,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.accepted),
                    child: const Text("Count me in! 🔥", style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.plum,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.rainchecked),
                    child: const Text('Raincheck 🍿', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else if (date.status == IntimacyStatus.pending && isOwner) ...[
            const Text(
              'Invitation sent to your partner. Awaiting their response...',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ] else if (date.status == IntimacyStatus.rainchecked) ...[
            const Text(
              'Raincheck accepted: Soft cuddle or relaxing movie night planned instead! 🍿',
              style: TextStyle(fontSize: 13, color: AppTheme.deepBerry, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenScheduleModal,
              child: const Text('Plan Another Date', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(IntimacyStatus status) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case IntimacyStatus.accepted:
        bg = AppTheme.safeGreenBg;
        text = AppTheme.safeGreen;
        label = 'ACCEPTED';
        break;
      case IntimacyStatus.pending:
        bg = AppTheme.cautionAmberBg;
        text = AppTheme.cautionAmber;
        label = 'PENDING';
        break;
      case IntimacyStatus.rainchecked:
        bg = AppTheme.blush;
        text = AppTheme.crimson;
        label = 'RAINCHECKED';
        break;
      case IntimacyStatus.counterOffered:
        bg = AppTheme.periodPurpleBg;
        text = AppTheme.periodPurple;
        label = 'COUNTER-OFFER';
        break;
      case IntimacyStatus.completed:
        bg = Colors.grey.shade200;
        text = Colors.grey.shade700;
        label = 'COMPLETED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
