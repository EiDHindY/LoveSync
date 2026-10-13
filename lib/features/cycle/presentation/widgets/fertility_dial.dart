import 'package:flutter/material.dart';
import 'package:love_app/core/constants/medical_disclaimer.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';

class FertilityDial extends StatelessWidget {
  final DailyFertilityInfo fertilityInfo;
  final VoidCallback onLogPeriod;
  final bool canLog;
  final String? managerName;

  const FertilityDial({
    super.key,
    required this.fertilityInfo,
    required this.onLogPeriod,
    this.canLog = true,
    this.managerName,
  });

  @override
  Widget build(BuildContext context) {
    final day = fertilityInfo.dayOfCycle;
    final total = fertilityInfo.cycleLength;
    final progress = day != null ? (day / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: fertilityInfo.color.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: fertilityInfo.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppTheme.plum.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'CYCLE & SAFETY TRACKER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppTheme.plum.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20, color: AppTheme.crimson),
                tooltip: 'Medical Disclaimer',
                onPressed: () => MedicalDisclaimer.showDisclaimerDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Circular Progress Dial
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.blush.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(fertilityInfo.color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(fertilityInfo.icon, size: 32, color: fertilityInfo.color),
                  const SizedBox(height: 4),
                  Text(
                    day != null ? 'Day $day' : 'No Data',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.plum,
                    ),
                  ),
                  Text(
                    day != null ? 'of $total days' : (canLog ? 'Tap to log' : 'Awaiting log'),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.plum.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Status Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fertilityInfo.bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: fertilityInfo.color.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: fertilityInfo.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fertilityInfo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: fertilityInfo.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  fertilityInfo.recommendation,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fertilityInfo.rationale,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Log Period Button or Read-Only Notice
          if (canLog) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogPeriod,
                icon: const Icon(Icons.water_drop, size: 18, color: AppTheme.crimson),
                label: const Text('Log Period / Adjust Cycle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.crimson,
                  side: const BorderSide(color: AppTheme.roseGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.blush),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 16, color: AppTheme.crimson),
                  const SizedBox(width: 8),
                  Text(
                    managerName != null && managerName!.isNotEmpty
                        ? 'Cycle managed by $managerName'
                        : 'Cycle tracked by your partner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
