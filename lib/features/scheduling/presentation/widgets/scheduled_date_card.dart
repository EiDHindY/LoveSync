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
        return 'Romantic Intimacy';
    }
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C0E28).withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.calendar_month_rounded, color: AppTheme.crimson, size: 18),
                SizedBox(width: 8),
                Text(
                  'DATE NIGHT & INTIMACY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.crimson,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'No upcoming date scheduled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan an evening synced with your partner\'s natural cycle bio-rhythms.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenScheduleModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Schedule a Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBerry,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final isDatePast = date.scheduledAt.isBefore(DateTime.now());
    final isAccepted = date.status == IntimacyStatus.accepted;

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
        color: isAccepted ? null : Colors.white,
        gradient: isAccepted
            ? const LinearGradient(
                colors: [
                  Color(0xFF6B113B),
                  Color(0xFFB61D46),
                  Color(0xFF4A0025),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAccepted
              ? Colors.white.withValues(alpha: 0.25)
              : AppTheme.blush,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAccepted ? const Color(0xFF6B113B) : const Color(0xFF2C0E28))
                .withValues(alpha: isAccepted ? 0.35 : 0.04),
            blurRadius: isAccepted ? 24 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: isAccepted ? AppTheme.primaryFixed : AppTheme.crimson,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DATE NIGHT INVITATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isAccepted ? AppTheme.primaryFixed : AppTheme.crimson,
                    ),
                  ),
                ],
              ),
              _buildStatusPill(date.status, isAccepted: isAccepted),
            ],
          ),
          const SizedBox(height: 12),

          // Date and Time
          Text(
            dateFormatted,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isAccepted ? Colors.white : AppTheme.plum,
            ),
          ),
          const SizedBox(height: 8),

          // Chips Row: Countdown & Bio-rhythm
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Days and Hours Left Countdown Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? Colors.white.withValues(alpha: 0.18)
                      : (isDatePast ? Colors.grey.shade100 : const Color(0xFFFFF0F5)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAccepted
                        ? Colors.white.withValues(alpha: 0.35)
                        : (isDatePast ? Colors.grey.shade300 : AppTheme.crimson.withValues(alpha: 0.35)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 13,
                      color: isAccepted
                          ? Colors.white
                          : (isDatePast ? Colors.grey.shade600 : AppTheme.crimson),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      date.formatCountdown(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAccepted
                            ? Colors.white
                            : (isDatePast ? Colors.grey.shade700 : AppTheme.crimson),
                      ),
                    ),
                  ],
                ),
              ),

              // Cycle Safety / Bio-rhythm Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? Colors.white.withValues(alpha: 0.18)
                      : fertility.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAccepted
                        ? Colors.white.withValues(alpha: 0.35)
                        : fertility.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isAccepted ? AppTheme.primaryFixed : fertility.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fertility.dayOfCycle != null
                            ? '${fertility.title} (Day ${fertility.dayOfCycle})'
                            : fertility.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAccepted ? Colors.white : fertility.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bio-rhythm insight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAccepted
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAccepted
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppTheme.blush,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.spa_rounded,
                  size: 15,
                  color: isAccepted ? AppTheme.primaryFixed : AppTheme.crimson,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getBioRhythmInsight(fertility),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isAccepted ? Colors.white.withValues(alpha: 0.95) : AppTheme.deepBerry,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actions
          if (isDateToday && isAccepted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.celebration_rounded, size: 16, color: AppTheme.primaryFixed),
                      SizedBox(width: 6),
                      Text(
                        'Gentle Day-Of Vibe Check',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Date is tonight! Still feeling the spark, or exhausted from the day?",
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 8),
                  if (date.vibeCheckStatus == VibeCheckStatus.confirmed)
                    const Text(
                      '✨ Confirmed! Looking forward to tonight 🔥',
                      style: TextStyle(color: AppTheme.primaryFixed, fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  else if (date.vibeCheckStatus == VibeCheckStatus.convertedCuddle)
                    const Text(
                      '🫂 Soft evening planned: Warm cuddles & movie night instead!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.crimson,
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
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
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
            // Guilt-Free Response Actions
            const Text(
              'Your partner proposed this date. How are you feeling?',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.accepted),
                    icon: const Icon(Icons.celebration_rounded, size: 16),
                    label: const Text('Accept Date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.plum,
                      side: const BorderSide(color: AppTheme.roseGold),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.rainchecked),
                    child: const Text('Raincheck 🍿', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ),
          ] else if (date.status == IntimacyStatus.pending && isOwner) ...[
            const Text(
              'Invitation sent to your partner. Awaiting their response...',
              style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ] else if (date.status == IntimacyStatus.rainchecked) ...[
            const Text(
              'Raincheck accepted: Soft cuddle or relaxing movie night planned instead! 🍿',
              style: TextStyle(fontSize: 12.5, color: AppTheme.deepBerry, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenScheduleModal,
              icon: Icon(
                Icons.edit_calendar_rounded,
                size: 15,
                color: isAccepted ? Colors.white.withValues(alpha: 0.9) : AppTheme.deepBerry,
              ),
              label: Text(
                'Plan Another Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAccepted ? Colors.white.withValues(alpha: 0.9) : AppTheme.deepBerry,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(IntimacyStatus status, {bool isAccepted = false}) {
    if (isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'ACCEPTED',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
    }

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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
