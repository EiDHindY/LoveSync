import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';

class ScheduleDateModal extends StatefulWidget {
  final DateTime? lastPeriodStartDate;
  final int cycleLength;
  final int periodLength;
  final int safetyBufferDays;
  final Function(DateTime scheduledAt) onSchedule;
  final String? title;
  final String? submitLabel;
  final DateTime? initialDateTime;

  const ScheduleDateModal({
    super.key,
    required this.lastPeriodStartDate,
    required this.cycleLength,
    required this.periodLength,
    required this.safetyBufferDays,
    required this.onSchedule,
    this.title,
    this.submitLabel,
    this.initialDateTime,
  });

  @override
  State<ScheduleDateModal> createState() => _ScheduleDateModalState();
}

class _ScheduleDateModalState extends State<ScheduleDateModal> {
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);

  DateTime get _scheduledDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  bool get _isPast => _scheduledDateTime.isBefore(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (widget.initialDateTime != null) {
      final initial = widget.initialDateTime!.toLocal();
      _selectedDate = DateTime(initial.year, initial.month, initial.day);
      _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);
    } else {
      // Default to upcoming 3 days from now at 9:00 PM
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 3));
    }
  }

  DailyFertilityInfo _getProjectedFertility(DateTime date) {
    return CycleEngine.calculateFertility(
      targetDate: date,
      lastPeriodStartDate: widget.lastPeriodStartDate,
      cycleLength: widget.cycleLength,
      periodLength: widget.periodLength,
      safetyBufferDays: widget.safetyBufferDays,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
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
      setState(() {
        _selectedDate = picked;
        // If user picked today, ensure the selected time hasn't already passed
        final isToday = picked.year == now.year && picked.month == now.month && picked.day == now.day;
        if (isToday) {
          final nowMinutes = now.hour * 60 + now.minute;
          final selectedMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
          if (selectedMinutes <= nowMinutes) {
            final nextHour = (now.hour + 1) % 24;
            _selectedTime = TimeOfDay(hour: nextHour, minute: 0);
          }
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;
      if (isToday) {
        final candidate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        if (candidate.isBefore(now)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot select a time in the past. Please choose a future time.'),
                backgroundColor: AppTheme.crimson,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(_selectedDate);
    final timeStr = _selectedTime.format(context);
    final projectedFertility = _getProjectedFertility(_selectedDate);

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
          Row(
            children: [
              const Icon(Icons.event_available, color: AppTheme.crimson),
              const SizedBox(width: 8),
              Text(
                widget.title ?? 'Schedule Intimacy Date',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Propose a romantic rendezvous with projected fertility safety.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Date & Time Selectors Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.blush),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.blush),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Smart countdown & validation preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isPast ? const Color(0xFFFFF1F2) : const Color(0xFFFBF4F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPast
                    ? const Color(0xFFFDA4AF)
                    : AppTheme.roseGold.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPast ? Icons.schedule_send_rounded : Icons.hourglass_top_rounded,
                  size: 20,
                  color: _isPast ? AppTheme.crimson : AppTheme.deepBerry,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPast ? 'CANNOT SCHEDULE IN THE PAST' : 'TIME UNTIL DATE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _isPast ? AppTheme.crimson : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPast
                            ? 'Please select a future date or time.'
                            : ScheduledIntimacy.formatDurationUntil(_scheduledDateTime),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isPast ? AppTheme.crimson : AppTheme.plum,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Live Fertility Preview Badge for Selected Date
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: projectedFertility.bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: projectedFertility.color.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(projectedFertility.icon, color: projectedFertility.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected Status: ${projectedFertility.title}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: projectedFertility.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        projectedFertility.recommendation,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Send Invitation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPast
                  ? null
                  : () {
                      widget.onSchedule(_scheduledDateTime);
                      Navigator.of(context).pop();
                    },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(_isPast ? 'Choose a Future Time' : (widget.submitLabel ?? 'Send Date Proposal')),
            ),
          ),
        ],
      ),
    );
  }
}
