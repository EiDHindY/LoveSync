import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';

class PeriodLogModal extends StatefulWidget {
  final DateTime? initialStartDate;
  final int initialCycleLength;
  final int initialPeriodLength;
  final int initialBufferDays;
  final Function(DateTime startDate, int cycleLength, int periodLength, int bufferDays) onSave;

  const PeriodLogModal({
    super.key,
    required this.initialStartDate,
    required this.initialCycleLength,
    required this.initialPeriodLength,
    required this.initialBufferDays,
    required this.onSave,
  });

  @override
  State<PeriodLogModal> createState() => _PeriodLogModalState();
}

class _PeriodLogModalState extends State<PeriodLogModal> {
  late DateTime _selectedDate;
  late int _cycleLength;
  late int _periodLength;
  late int _bufferDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialStartDate ?? DateTime.now().subtract(const Duration(days: 7));
    _cycleLength = widget.initialCycleLength;
    _periodLength = widget.initialPeriodLength;
    _bufferDays = widget.initialBufferDays;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.crimson,
              onPrimary: Colors.white,
              onSurface: AppTheme.plum,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Log Period & Cycle Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accurate start dates ensure the safest fertility predictions.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            // Start Date Picker
            const Text(
              'First Day of Last Period',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.blush.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.crimson),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.plum,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit, size: 18, color: AppTheme.crimson),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Cycle Length Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Average Cycle Length', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$_cycleLength days',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson)),
              ],
            ),
            Slider(
              value: _cycleLength.toDouble(),
              min: 21,
              max: 38,
              divisions: 17,
              activeColor: AppTheme.crimson,
              onChanged: (val) => setState(() => _cycleLength = val.toInt()),
            ),
            // Period Length Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Period Bleeding Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$_periodLength days',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson)),
              ],
            ),
            Slider(
              value: _periodLength.toDouble(),
              min: 3,
              max: 8,
              divisions: 5,
              activeColor: AppTheme.crimson,
              onChanged: (val) => setState(() => _periodLength = val.toInt()),
            ),
            // Safety Buffer Slider
            Row(
              children: [
                const Text('Safety Buffer Margin', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.crimson),
                  tooltip: 'What is Safety Buffer?',
                  onPressed: () => _showBufferExplanationDialog(context),
                ),
                const Spacer(),
                Text(
                  '±$_bufferDays days buffer',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson),
                ),
              ],
            ),
            Slider(
              value: _bufferDays.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              activeColor: AppTheme.crimson,
              onChanged: (val) => setState(() => _bufferDays = val.toInt()),
            ),
            // Dynamic Descriptive Explanation Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 16, color: AppTheme.crimson),
                      const SizedBox(width: 6),
                      Text(
                        _getBufferTitle(_bufferDays),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.plum,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _getBufferDescription(_bufferDays),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.plum.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showBufferExplanationDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'What is this buffer & how does it protect us? Tap to learn',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.crimson,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.crimson),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_selectedDate, _cycleLength, _periodLength, _bufferDays);
                  Navigator.of(context).pop();
                },
                child: const Text('Save & Update Predictions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBufferTitle(int buffer) {
    switch (buffer) {
      case 1:
        return 'Tight Cushion (±1 Day)';
      case 2:
        return 'Standard Cushion (±2 Days) • Recommended';
      case 3:
        return 'Extended Cushion (±3 Days)';
      case 4:
        return 'Maximum Protection (±4 Days)';
      default:
        return '±$buffer Days Buffer';
    }
  }

  String _getBufferDescription(int buffer) {
    switch (buffer) {
      case 1:
        return 'Adds 1 caution day before & after ovulation. Best if your cycles are strictly regular like clockwork.';
      case 2:
        return 'Adds 2 caution days before & 1 day after ovulation. Shields against typical shifts caused by stress, travel, or fatigue.';
      case 3:
        return 'Adds 3 caution days before & 1 day after ovulation. Recommended if your cycle length varies by a couple of days.';
      case 4:
        return 'Adds 4 caution days before & 1 day after ovulation. Widest caution cushion for irregular cycles or zero pregnancy risk tolerance.';
      default:
        return 'Adds extra caution days around the fertile window.';
    }
  }

  void _showBufferExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppTheme.crimson, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Safety Buffer Margin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
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
                'A protective cushion against unexpected ovulation shifts.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 14),
              // What it is & why
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.blush.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Why is a safety buffer needed?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.plum,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A woman’s body is not a machine. Stress, poor sleep, travel, or hormone shifts can cause ovulation to happen 1–2 days earlier or later than standard math predicts.\n\nBecause sperm can survive inside for up to 5 days, having unprotected sex right before an unexpected early ovulation can result in pregnancy.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF333333)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Traffic Light System in LoveSync:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
              const SizedBox(height: 8),
              _buildPhaseExplainer(
                icon: Icons.water_drop,
                color: AppTheme.periodPurple,
                title: '🟣 Period Active (Days 1–5)',
                desc: 'Active menstrual bleeding. Very low conception risk.',
              ),
              const SizedBox(height: 6),
              _buildPhaseExplainer(
                icon: Icons.warning_amber_rounded,
                color: AppTheme.cautionAmber,
                title: '🟡 Safety Buffer (Caution Zone)',
                desc: 'The buffer days! Ovulation could happen early or late. Use condoms or avoid ejaculation.',
              ),
              const SizedBox(height: 6),
              _buildPhaseExplainer(
                icon: Icons.block,
                color: AppTheme.fertileRed,
                title: '🔴 Fertile Window (Peak Ovulation)',
                desc: 'Highest pregnancy risk. Avoid unprotected ejaculation if preventing conception.',
              ),
              const SizedBox(height: 6),
              _buildPhaseExplainer(
                icon: Icons.check_circle_outline,
                color: AppTheme.safeGreen,
                title: '🟢 Safe Window (Post-Ovulation)',
                desc: 'Ovum has dissolved. Lowest conception risk of the cycle.',
              ),
              const SizedBox(height: 14),
              const Text(
                'Which setting should you pick?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '• ±1 Day: If your cycle is strictly predictable like clockwork.\n'
                '• ±2 Days: Recommended standard setting for most couples.\n'
                '• ±3 or ±4 Days: If cycles fluctuate by a few days, or for zero pregnancy risk tolerance.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF444444)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  static Widget _buildPhaseExplainer({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF222222), height: 1.3),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
