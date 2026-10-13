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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Safety Buffer Margin', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('±$_bufferDays days buffer',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson)),
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
            Text(
              'A higher buffer adds extra caution days before and after ovulation for added safety.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
}
