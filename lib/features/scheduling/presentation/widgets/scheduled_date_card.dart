import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';

class ScheduledDateCard extends StatelessWidget {
  final ScheduledIntimacy? dateItem;
  final String currentUserId;
  final String? userAvatarUrl;
  final String? partnerAvatarUrl;
  final String? userName;
  final String? partnerName;
  final DateTime? lastPeriodStartDate;
  final int cycleLength;
  final int periodLength;
  final int safetyBufferDays;
  final VoidCallback onOpenScheduleModal;
  final Function(String id, IntimacyStatus status) onRespond;
  final Function(String id, VibeCheckStatus status) onRespondVibeCheck;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancelProposal;
  final VoidCallback? onCancelDate;

  const ScheduledDateCard({
    super.key,
    required this.dateItem,
    required this.currentUserId,
    this.userAvatarUrl,
    this.partnerAvatarUrl,
    this.userName,
    this.partnerName,
    required this.lastPeriodStartDate,
    required this.cycleLength,
    required this.periodLength,
    required this.safetyBufferDays,
    required this.onOpenScheduleModal,
    required this.onRespond,
    required this.onRespondVibeCheck,
    this.onReschedule,
    this.onCancelProposal,
    this.onCancelDate,
  });

  bool _isToday(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month && local.day == now.day;
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
    final localScheduledAt = date.scheduledAt.toLocal();
    final dateFormatted = DateFormat('EEEE, MMM d · h:mm a').format(localScheduledAt);
    final isOwner = date.proposedBy == currentUserId;
    final isDateToday = _isToday(localScheduledAt);
    final isDatePast = localScheduledAt.isBefore(DateTime.now());
    final isAccepted = date.status == IntimacyStatus.accepted;

    final fertility = CycleEngine.calculateFertility(
      targetDate: localScheduledAt,
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
          const SizedBox(height: 10),

          // Visual Status & Avatars Banner
          if (isAccepted)
            _buildAcceptedAvatarBanner(
              userName: userName ?? 'You',
              partnerName: partnerName ?? 'Partner',
              userAvatarUrl: userAvatarUrl,
              partnerAvatarUrl: partnerAvatarUrl,
            )
          else if (date.status == IntimacyStatus.pending)
            _buildPendingAvatarBanner(
              isOwner: isOwner,
              userName: userName ?? 'You',
              partnerName: partnerName ?? 'Partner',
              userAvatarUrl: userAvatarUrl,
              partnerAvatarUrl: partnerAvatarUrl,
            ),

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
            Text(
              '${partnerName?.isNotEmpty == true ? partnerName! : "Your partner"} proposed this date. How are you feeling?',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
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
                    icon: const Icon(Icons.favorite_rounded, size: 16),
                    label: const Text('Accept Date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.plum,
                      side: const BorderSide(color: AppTheme.roseGold),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => onRespond(date.id, IntimacyStatus.rainchecked),
                    icon: const Icon(Icons.event_repeat_rounded, size: 16, color: AppTheme.plum),
                    label: const Text('Raincheck', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ] else if (date.status == IntimacyStatus.pending && isOwner) ...[
            Text(
              'Invitation sent to ${partnerName?.isNotEmpty == true ? partnerName! : "your partner"}. Awaiting their response...',
              style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onCancelDate != null || onCancelProposal != null)
                  OutlinedButton.icon(
                    onPressed: onCancelDate ?? onCancelProposal,
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Cancel Invitation', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                if ((onCancelDate != null || onCancelProposal != null) && onReschedule != null) const SizedBox(width: 8),
                if (onReschedule != null)
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.crimson),
                    label: const Text(
                      'Change Time',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.crimson, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ] else if (date.status == IntimacyStatus.rainchecked) ...[
            const Text(
              'Raincheck accepted: Soft cuddle or relaxing movie night planned instead! 🍿',
              style: TextStyle(fontSize: 12.5, color: AppTheme.deepBerry, fontWeight: FontWeight.w600),
            ),
          ],
          if (isAccepted) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancelDate != null || onCancelProposal != null)
                  OutlinedButton.icon(
                    onPressed: onCancelDate ?? onCancelProposal,
                    icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    label: const Text(
                      'Cancel Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                if ((onCancelDate != null || onCancelProposal != null) && onReschedule != null)
                  const SizedBox(width: 8),
                if (onReschedule != null)
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: Icon(
                      Icons.edit_calendar_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    label: Text(
                      'Reschedule Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ] else if (date.status == IntimacyStatus.rainchecked || date.status == IntimacyStatus.completed) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenScheduleModal,
                icon: const Icon(
                  Icons.edit_calendar_rounded,
                  size: 15,
                  color: AppTheme.deepBerry,
                ),
                label: const Text(
                  'Plan Another Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepBerry,
                  ),
                ),
              ),
            ),
          ],
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
      case IntimacyStatus.canceled:
        bg = AppTheme.blush;
        text = AppTheme.crimson;
        label = 'CANCELED';
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

  Widget _buildAcceptedAvatarBanner({
    required String userName,
    required String partnerName,
    required String? userAvatarUrl,
    required String? partnerAvatarUrl,
  }) {
    final partnerDisplay = partnerName.isNotEmpty ? partnerName : 'Partner';
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 0,
                  child: _buildAvatarCircle(
                    imageUrl: userAvatarUrl,
                    name: userName,
                    fallbackBg: AppTheme.deepBerry,
                    fallbackTextColor: Colors.white,
                    size: 36,
                  ),
                ),
                Positioned(
                  left: 26,
                  child: _buildAvatarCircle(
                    imageUrl: partnerAvatarUrl,
                    name: partnerDisplay,
                    fallbackBg: const Color(0xFFFFB3BA),
                    fallbackTextColor: AppTheme.plum,
                    size: 36,
                  ),
                ),
                Positioned(
                  left: 21,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 10, color: Color(0xFFFF1E56)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Confirmed! ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You & $partnerDisplay are synced for romance!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAvatarBanner({
    required bool isOwner,
    required String userName,
    required String partnerName,
    required String? userAvatarUrl,
    required String? partnerAvatarUrl,
  }) {
    final partnerDisplay = partnerName.isNotEmpty ? partnerName : 'Partner';
    final userDisplay = userName.isNotEmpty ? userName : 'You';
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blush, width: 1.2),
      ),
      child: Row(
        children: [
          // Proposer
          _buildAvatarCircle(
            imageUrl: isOwner ? userAvatarUrl : partnerAvatarUrl,
            name: isOwner ? userDisplay : partnerDisplay,
            fallbackBg: AppTheme.deepBerry,
            fallbackTextColor: Colors.white,
            size: 34,
            statusBadge: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 9, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          // Arrow connector
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: AppTheme.crimson.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.crimson.withValues(alpha: 0.6)),
                ),
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: AppTheme.crimson.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Recipient
          _buildAvatarCircle(
            imageUrl: isOwner ? partnerAvatarUrl : userAvatarUrl,
            name: isOwner ? partnerDisplay : userDisplay,
            fallbackBg: const Color(0xFFFFB3BA),
            fallbackTextColor: AppTheme.plum,
            size: 34,
            statusBadge: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFFE65100), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded, size: 9, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              isOwner
                  ? 'Awaiting $partnerDisplay\'s response'
                  : '$partnerDisplay invited you!',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.plum,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle({
    required String? imageUrl,
    required String name,
    required Color fallbackBg,
    required Color fallbackTextColor,
    double size = 38,
    Widget? statusBadge,
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fallbackBg,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.bold,
                          color: fallbackTextColor,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: size * 0.42,
                        fontWeight: FontWeight.bold,
                        color: fallbackTextColor,
                      ),
                    ),
                  ),
          ),
        ),
        if (statusBadge != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: statusBadge,
          ),
      ],
    );
  }
}
