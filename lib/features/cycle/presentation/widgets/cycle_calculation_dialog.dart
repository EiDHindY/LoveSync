import 'package:flutter/material.dart';
import 'package:love_app/core/theme/app_theme.dart';

class CycleCalculationDialog extends StatelessWidget {
  final int cycleLength;
  final int periodLength;
  final int safetyBufferDays;

  const CycleCalculationDialog({
    super.key,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.safetyBufferDays = 2,
  });

  static void show(
    BuildContext context, {
    int cycleLength = 28,
    int periodLength = 5,
    int safetyBufferDays = 2,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => CycleCalculationDialog(
        cycleLength: cycleLength,
        periodLength: periodLength,
        safetyBufferDays: safetyBufferDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ovulationDay = cycleLength - 14;
    final coreFertileStart = ovulationDay - 5;
    final coreFertileEnd = ovulationDay;
    final effectiveBuffer = safetyBufferDays < 2 ? 2 : safetyBufferDays;

    int rawBufferStart = (ovulationDay - effectiveBuffer) - 5;
    if (rawBufferStart - (periodLength + 1) <= 1 && rawBufferStart > periodLength) {
      rawBufferStart = periodLength + 1;
    }
    final bufferStart = rawBufferStart;
    final bufferEnd = (ovulationDay + effectiveBuffer) + 1;
    final safeStart = bufferEnd + 1;
    final lutealSafeDaysCount = cycleLength - safeStart + 1;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: const [
          Icon(Icons.science_rounded, color: AppTheme.crimson, size: 26),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'How Safe & Fertile Days Are Calculated',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensiplan Clinical Model with Symmetrical ±$safetyBufferDays Day Safety Buffer & 24h Ovum Viability.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            // Summary Settings Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Cycle', '$cycleLength d'),
                  _buildSummaryItem('Bleeding', '$periodLength d'),
                  _buildSummaryItem('Ovulation', 'Day $ovulationDay'),
                  _buildSummaryItem('Buffer', '±$safetyBufferDays d'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '5-Phase Clinical Cycle Breakdown:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            const SizedBox(height: 10),

            // 1. Menstruation
            _buildPhaseCard(
              phaseNumber: '1',
              title: 'Menstruation',
              dayRange: 'Days 1 – $periodLength ($periodLength days)',
              color: const Color(0xFFC084FC),
              badgeColor: const Color(0xFFF3E8FF),
              textColor: const Color(0xFF6B21A8),
              summary: 'Active endometrial shedding. Basal hormone levels; very low pregnancy risk.',
              details: 'Follicular recruitment is at the earliest antral stage (2–5 mm). Cervical os is closed by thick G-type mucus.',
            ),
            const SizedBox(height: 10),

            // 2. Pre-Ovulation Caution Buffer
            _buildPhaseCard(
              phaseNumber: '2',
              title: 'Pre-Ovulation Caution Buffer',
              dayRange: 'Days $bufferStart – ${coreFertileStart - 1} (${(coreFertileStart - bufferStart)} days)',
              color: const Color(0xFFF59E0B),
              badgeColor: const Color(0xFFFEF3C7),
              textColor: const Color(0xFF92400E),
              summary: 'Protected sex recommended (condom/withdrawal). Guards against early ovulation + 5-day sperm life.',
              details: '• Sensiplan 5-Day Rule: Eliminates the dangerous 1-day "safe" island on Day 6.\n'
                  '• Biology: Ovulation can arrive as early as Day ${ovulationDay - safetyBufferDays}. Because sperm survive up to 5 days (120h) in fertile mucus, intercourse here carries real pregnancy risk.',
            ),
            const SizedBox(height: 10),

            // 3. Peak Fertile Window
            _buildPhaseCard(
              phaseNumber: '3',
              title: 'Peak Fertile Window (Ovulation Peak 🔥)',
              dayRange: 'Days $coreFertileStart – $coreFertileEnd (${(coreFertileEnd - coreFertileStart + 1)} days)',
              color: const Color(0xFFFE5678),
              badgeColor: const Color(0xFFFEE2E2),
              textColor: const Color(0xFF991B1B),
              summary: 'Highest pregnancy risk! Avoid ejaculation inside if preventing conception.',
              details: '• The Wilcox 6-Day Window: Copious alkaline estrogenic (E-type) mucus channels sperm.\n'
                  '• Ovulation Day (Day $ovulationDay): Single-act conception probability peaks at 25%–34% on Days 12–14.',
            ),
            const SizedBox(height: 10),

            // 4. Post-Ovulation Caution Buffer
            _buildPhaseCard(
              phaseNumber: '4',
              title: 'Post-Ovulation Caution Buffer',
              dayRange: 'Days ${coreFertileEnd + 1} – $bufferEnd (${(bufferEnd - coreFertileEnd)} days)',
              color: const Color(0xFFF59E0B),
              badgeColor: const Color(0xFFFEF3C7),
              textColor: const Color(0xFF92400E),
              summary: 'Protected sex recommended. Covers delayed ovulation (+2d) and 24h egg viability.',
              details: '• Delayed Ovulation: Ovulation can shift up to Day ${ovulationDay + safetyBufferDays}.\n'
                  '• Ovum Lifespan: An egg extruded on Day ${ovulationDay + safetyBufferDays} survives 12 to 24 hours (through Day $bufferEnd). Days 15, 16, and 17 must remain caution!',
            ),
            const SizedBox(height: 10),

            // 5. Luteal Safe Window
            _buildPhaseCard(
              phaseNumber: '5',
              title: 'Luteal Safe Window (Safest of Month)',
              dayRange: 'Days $safeStart – $cycleLength ($lutealSafeDaysCount days)',
              color: const Color(0xFF10B981),
              badgeColor: const Color(0xFFECFDF5),
              textColor: const Color(0xFF065F46),
              summary: 'Lowest pregnancy risk. Safe for unprotected sex if cycle is regular.',
              details: '• Egg Autolyzed: The secondary oocyte has completely dissolved.\n'
                  '• Progesterone Blockade: High progesterone from the corpus luteum creates an impenetrable cervical mucus plug and halts any further ovulation until next period begins on Day 1.',
            ),
            const SizedBox(height: 16),

            // Mathematical Reference
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biomedical Calculation Summary:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Estimated Ovulation: Cycle Length ($cycleLength) - 14 = Day $ovulationDay\n'
                    '${bufferStart < coreFertileStart && bufferStart > periodLength ? '• Pre-Ovulation Caution: Days $bufferStart – ${coreFertileStart - 1} (early ovulation guard)\n' : ''}'
                    '• Peak Fertile Window: Days $coreFertileStart – $coreFertileEnd (5d sperm lifespan + ovulation)\n'
                    '• Post-Ovulation Buffer: Days ${coreFertileEnd + 1} – $bufferEnd (+${effectiveBuffer}d buffer + 24h egg viability)\n'
                    '• Luteal Safe Start: Day $safeStart through Day $cycleLength ($lutealSafeDaysCount safe days)',
                    style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF444444)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scientific References Citation
            Text(
              'Peer-Reviewed Sources:\n'
              '• Wilcox AJ et al. New England Journal of Medicine (1995; 333:1517–1521)\n'
              '• Dunson DB et al. Human Reproduction (1999; 14:1835–1839)\n'
              '• Frank-Herrmann P et al. Human Reproduction / Sensiplan (2007; 22:1310–1319)',
              style: TextStyle(fontSize: 10.5, height: 1.35, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  static Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.plum,
          ),
        ),
      ],
    );
  }

  static Widget _buildPhaseCard({
    required String phaseNumber,
    required String title,
    required String dayRange,
    required Color color,
    required Color badgeColor,
    required Color textColor,
    required String summary,
    required String details,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  phaseNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              dayRange,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
