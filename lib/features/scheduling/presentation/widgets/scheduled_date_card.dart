import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';
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

  String _getBioRhythmInsight(DailyFertilityInfo fertility) {
    switch (fertility.phase) {
      case FertilityPhase.safe:
        return 'Luteal Phase Calm · Relaxing Vibe Recommended';
      case FertilityPhase.caution:
        return 'Approaching Fertile Buffer · Gentle Intimacy';
      case FertilityPhase.fertile:
        return 'High Ovulation Energy · Electric Connection';
      case FertilityPhase.menstruating:
        return 'Menstrual Cycle Active · Comfort & Pampering';
      case FertilityPhase.unknown:
        return 'Romantic Sanctuary · Intimate Moments';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dateItem == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.blush, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C0E28).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.wine_bar_rounded, color: AppTheme.crimson, size: 18),
                SizedBox(width: 8),
                Text(
                  'SPECIAL PROPOSAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.crimson,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'No upcoming intimacy date scheduled.',
              style: TextStyle(fontSize: 14, color: AppTheme.plum, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Surprise your partner with a romantic candlelit evening.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenScheduleModal,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Plan Date Night'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBerry,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final date = dateItem!;
    final dateFormatted = DateFormat('EEEE, MMM d · h:mm a').format(date.scheduledAt);
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
              ? AppTheme.roseGold.withValues(alpha: 0.6)
              : AppTheme.blush,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C0E28).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Tag & Embedded Cycle Safety Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.wine_bar_rounded, size: 18, color: AppTheme.crimson),
                  SizedBox(width: 6),
                  Text(
                    'SPECIAL PROPOSAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppTheme.crimson,
                    ),
                  ),
                ],
              ),
              // Embedded Cycle Safety Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: fertility.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fertility.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: fertility.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      fertility.dayOfCycle != null
                          ? '${fertility.title} (Day ${fertility.dayOfCycle})'
                          : fertility.title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: fertility.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          const Text(
            'Candlelight Dinner & Rooftop Drinks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.plum,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Date & Time
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                dateFormatted,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'L\'Aura Sky Lounge · Intimate Corner Table',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Atmospheric Photo Preview with Overlay
          Container(
            width: double.infinity,
            height: 124,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF4A0025), Color(0xFF6B113B), Color(0xFF2C0E28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Soft candle bokeh glow illustration
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.6, -0.2),
                          radius: 1.1,
                          colors: [
                            const Color(0xFFFFB0C9).withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: AppTheme.primaryFixed, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Romantic Sanctuary',
                        style: TextStyle(
                          color: AppTheme.primaryFixed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.deck_outlined, size: 13, color: AppTheme.primaryFixed),
                        SizedBox(width: 5),
                        Text(
                          'Corner Table Reserved · Ambient Jazz',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bio-Rhythm Intimacy Insight Note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.blush),
            ),
            child: Row(
              children: [
                const Icon(Icons.spa_rounded, size: 15, color: AppTheme.crimson),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getBioRhythmInsight(fertility),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepBerry,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actions
          if (isDateToday && date.status == IntimacyStatus.accepted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.celebration_rounded, size: 16, color: AppTheme.crimson),
                      SizedBox(width: 6),
                      Text(
                        'Gentle Day-Of Vibe Check',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.plum),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Date is tonight! Still feeling the spark, or exhausted from the day?",
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF444444)),
                  ),
                  const SizedBox(height: 8),
                  if (date.vibeCheckStatus == VibeCheckStatus.confirmed)
                    const Text(
                      '✨ Confirmed! Looking forward to tonight 🔥',
                      style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  else if (date.vibeCheckStatus == VibeCheckStatus.convertedCuddle)
                    const Text(
                      '🫂 Soft evening planned: Warm cuddles & movie night instead!',
                      style: TextStyle(color: AppTheme.deepBerry, fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.crimson,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => onRespondVibeCheck(date.id, VibeCheckStatus.confirmed),
                            child: const Text('Still on! 🔥', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.deepBerry,
                              side: const BorderSide(color: AppTheme.roseGold),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => onRespondVibeCheck(date.id, VibeCheckStatus.convertedCuddle),
                            child: const Text('Cuddle instead 🫂', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ] else if (date.status == IntimacyStatus.pending && !isOwner) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.accepted),
                    icon: const Icon(Icons.celebration_rounded, size: 16),
                    label: const Text('Accept Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.plum,
                      side: const BorderSide(color: AppTheme.roseGold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.rainchecked),
                    child: const Text('Raincheck 🍿', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusPill(date.status),
                TextButton.icon(
                  onPressed: onOpenScheduleModal,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 15, color: AppTheme.deepBerry),
                  label: const Text(
                    'Plan Another Date',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepBerry),
                  ),
                ),
              ],
            ),
          ],
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
        label = 'ACCEPTED 🥂';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
