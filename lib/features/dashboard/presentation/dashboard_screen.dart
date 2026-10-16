import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_app/core/constants/medical_disclaimer.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';
import 'package:love_app/features/cycle/presentation/period_log_modal.dart';
import 'package:love_app/features/cycle/presentation/widgets/cycle_calculation_dialog.dart';
import 'package:love_app/features/cycle/presentation/widgets/cycle_forecast_bar.dart';
import 'package:love_app/features/cycle/presentation/widgets/fertility_dial.dart';
import 'package:love_app/features/mood/domain/mood_status.dart';
import 'package:love_app/features/mood/presentation/widgets/spark_button.dart';
import 'package:love_app/features/pairing/presentation/pairing_modal.dart';
import 'package:love_app/features/pairing/presentation/partner_info_modal.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';
import 'package:love_app/features/scheduling/presentation/schedule_date_modal.dart';
import 'package:love_app/features/scheduling/presentation/widgets/scheduled_date_card.dart';
import 'package:love_app/features/onboarding/presentation/create_profile_screen.dart';
import 'package:love_app/features/onboarding/presentation/welcome_screen.dart';
import 'package:love_app/core/services/sound_service.dart';
import 'package:love_app/features/memories/presentation/memories_inbox_modal.dart';
import 'package:love_app/features/mood/presentation/widgets/sound_picker_modal.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.read(coupleRepositoryProvider.notifier).autoClosePastDates();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openPeriodModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PeriodLogModal(
        initialStartDate: repo.lastPeriodStartDate,
        initialCycleLength: repo.cycleLength,
        initialPeriodLength: repo.periodLength,
        initialBufferDays: repo.safetyBufferDays,
        onSave: (start, cycle, period, buffer) {
          ref.read(coupleRepositoryProvider.notifier).updatePeriodLog(
                startDate: start,
                cycleLength: cycle,
                periodLength: period,
                bufferDays: buffer,
              );
        },
      ),
    );
  }

  void _openScheduleModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleDateModal(
        lastPeriodStartDate: repo.lastPeriodStartDate,
        cycleLength: repo.cycleLength,
        periodLength: repo.periodLength,
        safetyBufferDays: repo.safetyBufferDays,
        onSchedule: (dateTime) {
          ref.read(coupleRepositoryProvider.notifier).proposeDate(dateTime);
        },
      ),
    );
  }

  void _openRescheduleModal(BuildContext context, ScheduledIntimacy date) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleDateModal(
        title: 'Reschedule Date Night',
        submitLabel: 'Propose New Time',
        initialDateTime: date.scheduledAt.toLocal(),
        lastPeriodStartDate: repo.lastPeriodStartDate,
        cycleLength: repo.cycleLength,
        periodLength: repo.periodLength,
        safetyBufferDays: repo.safetyBufferDays,
        onSchedule: (dateTime) {
          ref.read(coupleRepositoryProvider.notifier).proposeReschedule(date.id, dateTime);
        },
      ),
    );
  }

  void _openPairingModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PairingModal(
        inviteCode: repo.inviteCode,
        isPaired: repo.isPaired,
        partnerName: repo.partnerName,
        onPairCode: (code) {
          ref.read(coupleRepositoryProvider.notifier).pairWithCode(code);
        },
        onRegenerateCode: () {
          ref.read(coupleRepositoryProvider.notifier).regenerateInviteCode();
        },
      ),
    );
  }

  void _openPartnerModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PartnerInfoModal(
        partnerName: repo.partnerName.isNotEmpty ? repo.partnerName : 'Partner',
        partnerRole: repo.partnerRole,
        partnerTracksCycle: repo.partnerTracksCycle,
        inviteCode: repo.inviteCode,
        partnerAvatarUrl: repo.partnerAvatarUrl,
        onDisconnectPartner: () {
          ref.read(coupleRepositoryProvider.notifier).disconnectPartner();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partner removed. Returned to individual mode.')),
          );
        },
      ),
    );
  }

  void _openSoundPickerModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SoundPickerModal(
        currentSoundId: repo.sparkSoundId,
        onSelectSound: (soundId) {
          ref.read(coupleRepositoryProvider.notifier).setSparkSound(soundId);
        },
      ),
    );
  }

  void _openCancelSoundPickerModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SoundPickerModal(
        currentSoundId: repo.cancelSoundId,
        options: kCancelSoundOptions,
        title: 'Cancellation Sound',
        subtitle: 'Pick the soothing chime when canceling a spark or date',
        headerIcon: '🍃',
        testId: 4,
        testTitle: 'Spark Canceled',
        testBody: 'Your partner canceled the spark gently.',
        onSelectSound: (soundId) {
          ref.read(coupleRepositoryProvider.notifier).setCancelSound(soundId);
        },
      ),
    );
  }

  void _openDateRequestSoundPickerModal(BuildContext context) {
    final repo = ref.read(coupleRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SoundPickerModal(
        currentSoundId: repo.dateRequestSoundId,
        options: kDateRequestSoundOptions,
        title: 'Date Request Sound',
        subtitle: 'Pick the romantic chime when your partner asks you out',
        headerIcon: '💌',
        testId: 5,
        testTitle: 'Date Night Proposed',
        testBody: 'Your partner suggested a special date together!',
        onSelectSound: (soundId) {
          ref.read(coupleRepositoryProvider.notifier).setDateRequestSound(soundId);
        },
      ),
    );
  }

  void _openUserProfileModal(BuildContext context, CoupleRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.blush,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.crimson.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: repo.userAvatarUrl.isNotEmpty
                    ? Image.network(
                        repo.userAvatarUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, _, _) => _buildUserFallbackAvatar(repo),
                      )
                    : _buildUserFallbackAvatar(repo),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              repo.currentUserName.isNotEmpty ? repo.currentUserName : 'You',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            if (repo.userEmail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blush.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      height: 14,
                      width: 14,
                      errorBuilder: (_, _, _) => const Icon(Icons.account_circle, size: 14, color: AppTheme.crimson),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      repo.userEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.plum,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.blush),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: repo.tracksCycle ? AppTheme.blush : Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          repo.tracksCycle ? Icons.calendar_month_rounded : Icons.male_rounded,
                          size: 20,
                          color: repo.tracksCycle ? AppTheme.crimson : Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Role',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              repo.tracksCycle ? 'Tracks Menstrual Cycle' : 'Does Not Track Cycle',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.plum),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.blush,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          repo.isPaired ? Icons.favorite_rounded : Icons.person_outline_rounded,
                          size: 20,
                          color: AppTheme.crimson,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connection Status',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              repo.isPaired ? 'Connected with ${repo.partnerName}' : 'Individual Mode (Unpaired)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.plum),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openSoundPickerModal(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.blush,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 20,
                              color: AppTheme.crimson,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Spark Match Sound',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  kSparkSoundOptions.firstWhere(
                                    (s) => s.id == repo.sparkSoundId,
                                    orElse: () => kSparkSoundOptions.first,
                                  ).name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.plum),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openCancelSoundPickerModal(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🍃', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cancellation Sound',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  kCancelSoundOptions.firstWhere(
                                    (s) => s.id == repo.cancelSoundId,
                                    orElse: () => kCancelSoundOptions.first,
                                  ).name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.plum),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDateRequestSoundPickerModal(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF1F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('💌', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date Request Sound',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  kDateRequestSoundOptions.firstWhere(
                                    (s) => s.id == repo.dateRequestSoundId,
                                    orElse: () => kDateRequestSoundOptions.first,
                                  ).name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.plum),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (repo.isSignedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.crimson, size: 18),
                  label: const Text(
                    'Sign Out of Google',
                    style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.crimson.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(coupleRepositoryProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserFallbackAvatar(CoupleRepository repo) {
    final initial = repo.currentUserName.isNotEmpty ? repo.currentUserName[0].toUpperCase() : 'U';
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.crimson, AppTheme.plum],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _openMemoriesModal(BuildContext context) {
    ref.read(coupleRepositoryProvider.notifier).markMemoriesAsRead();
    final memories = ref.read(coupleMemoriesProvider);
    final scheduledDates = ref.read(scheduledDatesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MemoriesInboxModal(
        memories: memories,
        scheduledDates: scheduledDates,
        onClearAll: () async {
          await ref.read(coupleRepositoryProvider.notifier).clearAllMemories();
        },
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect Space?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will clear your local couple session on this device and return to the Welcome screen so you can start from scratch.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect & Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true && context.mounted) {
      await ref.read(coupleRepositoryProvider.notifier).resetToOnboarding();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildConnectPartnerCard(BuildContext context, CoupleRepository repo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.blush.withValues(alpha: 0.6), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppTheme.crimson, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect Your Partner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.plum,
                      ),
                    ),
                    Text(
                      'Sync cycle & double-blind spark matches in real time',
                      style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimson,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Hey! Join our private LoveSync space using invite code ${repo.inviteCode} 💕',
                        subject: 'LoveSync Partner Invite',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.key_rounded, size: 16),
                  label: const Text('Enter Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.plum,
                    side: const BorderSide(color: AppTheme.roseGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _openPairingModal(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Widget _buildSexTab(
    BuildContext context,
    CoupleRepository repo,
    MoodStatus mood,
    ScheduledIntimacy? nextDate,
    int unreadCount,
  ) {
    final userName = repo.currentUserName.isNotEmpty ? repo.currentUserName : 'You';

    return SingleChildScrollView(
      key: const PageStorageKey('sex_tab_scroll'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getGreeting()}, $userName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.plum,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Private encrypted sanctuary · Both must agree',
            style: TextStyle(fontSize: 12.5, color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          if (!repo.isPaired) ...[
            _buildConnectPartnerCard(context, repo),
            const SizedBox(height: 18),
          ],

          // Sex & Intimacy features are greyed out and not clickable until a partner is connected
          IgnorePointer(
            ignoring: !repo.isPaired,
            child: ColorFiltered(
              colorFilter: repo.isPaired
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: Opacity(
                opacity: repo.isPaired ? 1.0 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ══════════════════════════════════════════════════════
                    // SECTION 1: SPARK
                    // ══════════════════════════════════════════════════════
                    _buildSectionHeader(
                      title: 'THE SPARK',
                      subtitle: 'Zero-pressure double-blind mood alignment',
                      icon: Icons.local_fire_department_rounded,
                    ),
                    const SizedBox(height: 10),
                    SparkButton(
                      moodStatus: mood,
                      partnerName: repo.partnerName,
                      userName: repo.currentUserName,
                      userAvatarUrl: repo.userAvatarUrl,
                      partnerAvatarUrl: repo.partnerAvatarUrl,
                      onToggle: () async {
                        if (mood.isMatch) {
                          await ref.read(coupleRepositoryProvider.notifier).turnOffSparkMatch();
                        } else {
                          await ref.read(coupleRepositoryProvider.notifier).toggleMoodSignal();
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════════
                    // SECTION 2: DATE NIGHT
                    // ══════════════════════════════════════════════════════
                    _buildSectionHeader(
                      title: 'DATE NIGHT',
                      subtitle: 'Cycle bio-rhythm aligned romance',
                      icon: Icons.event_available_rounded,
                    ),
                    const SizedBox(height: 10),
                    ScheduledDateCard(
                      dateItem: nextDate,
                      currentUserId: repo.currentUserId,
                      userAvatarUrl: repo.userAvatarUrl,
                      partnerAvatarUrl: repo.partnerAvatarUrl,
                      userName: repo.currentUserName,
                      partnerName: repo.partnerName,
                      lastPeriodStartDate: repo.lastPeriodStartDate,
                      cycleLength: repo.cycleLength,
                      periodLength: repo.periodLength,
                      safetyBufferDays: repo.safetyBufferDays,
                      onOpenScheduleModal: () => _openScheduleModal(context),
                      onReschedule: nextDate != null ? () => _openRescheduleModal(context, nextDate) : null,
                      onCancelProposal: nextDate != null
                          ? () => ref.read(coupleRepositoryProvider.notifier).cancelScheduledDate(nextDate.id)
                          : null,
                      onCancelDate: nextDate != null
                          ? () => ref.read(coupleRepositoryProvider.notifier).cancelScheduledDate(nextDate.id)
                          : null,
                      onRespond: (id, status) {
                        ref.read(coupleRepositoryProvider.notifier).respondToDate(id, status);
                      },
                      onRespondVibeCheck: (id, status) {
                        ref.read(coupleRepositoryProvider.notifier).respondVibeCheck(id, status);
                      },
                    ),

                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════════
                    // SECTION 3: MEMORIES & MOMENTS
                    // ══════════════════════════════════════════════════════
                    _buildSectionHeader(
                      title: 'MEMORIES',
                      subtitle: 'Shared intimacy timeline & celebrated sparks',
                      icon: Icons.favorite_rounded,
                      badgeText: unreadCount > 0 ? '$unreadCount NEW' : null,
                      trailingAction: TextButton.icon(
                        onPressed: () => _openMemoriesModal(context),
                        icon: const Icon(Icons.inbox_rounded, size: 15, color: AppTheme.crimson),
                        label: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimson,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMemoriesSection(context, ref, unreadCount),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
    Widget? trailingAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: AppTheme.crimson),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppTheme.crimson,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.crimson,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (trailingAction != null) ...[
          const SizedBox(width: 8),
          trailingAction,
        ],
      ],
    );
  }

  Widget _buildMemoriesSection(BuildContext context, WidgetRef ref, int unreadCount) {
    final memories = ref.watch(coupleMemoriesProvider);

    if (memories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.blush, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 20, color: AppTheme.plum),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No memories documented yet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.plum),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lit sparks and confirmed dates will be saved here.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final latestMemory = memories.first;
    return InkWell(
      onTap: () => _openMemoriesModal(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unreadCount > 0 ? AppTheme.roseGold : AppTheme.blush,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (unreadCount > 0 ? AppTheme.crimson : AppTheme.plum).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unreadCount > 0 ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
                size: 20,
                color: unreadCount > 0 ? AppTheme.crimson : AppTheme.plum,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          latestMemory.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.plum,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.crimson,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount NEW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    latestMemory.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleTab(
    BuildContext context,
    CoupleRepository repo,
    DailyFertilityInfo fertility,
  ) {
    if (!repo.tracksCycle && !repo.isPaired) {
      return SingleChildScrollView(
        key: const PageStorageKey('cycle_tab_unpaired'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.blush.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 40,
                  color: AppTheme.crimson,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Her Cycle Sync',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your account is set as a non-tracking partner. Connect with your partner to sync her fertility phases, safe intimacy windows, and cycle updates in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => _openPairingModal(context),
                icon: const Icon(Icons.link_rounded, size: 20),
                label: const Text('Connect with Partner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimson,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final partnerDisplay = repo.partnerName.isNotEmpty ? repo.partnerName : 'Her';

    return SingleChildScrollView(
      key: const PageStorageKey('cycle_tab_scroll'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Transparency Disclaimer Pill
          InkWell(
            onTap: () => MedicalDisclaimer.showDisclaimerDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2C0E28).withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_rounded,
                      size: 18,
                      color: Color(0xFF877277),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Natural fertility tracking is an estimate, not a guarantee (~12-24% typical annual failure rate). Always verify with basal temperature & cervical symptoms.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Scientific Cycle Calculation Tooltip / Guide Card
          InkWell(
            onTap: () => CycleCalculationDialog.show(
              context,
              cycleLength: repo.cycleLength,
              periodLength: repo.periodLength,
              safetyBufferDays: repo.safetyBufferDays,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2C0E28).withValues(alpha: 0.06),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B113B).withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.blush.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      size: 16,
                      color: AppTheme.crimson,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.tracksCycle
                              ? 'How Your Cycle Is Calculated'
                              : 'How $partnerDisplay\'s Cycle Is Calculated',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.plum,
                          ),
                        ),
                        Text(
                          'Sensiplan Model (±${repo.safetyBufferDays}d buffer + 24h egg viability). Tap for details.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: AppTheme.crimson,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 1. Hero Natural Rhythm & Segmented Cycle Dial
          FertilityDial(
            fertilityInfo: fertility,
            canLog: repo.tracksCycle,
            managerName: repo.partnerName,
            lastPeriodStartDate: repo.lastPeriodStartDate,
            cycleLength: repo.cycleLength,
            periodLength: repo.periodLength,
            safetyBufferDays: repo.safetyBufferDays,
            onLogPeriod: () => _openPeriodModal(context),
          ),

          const SizedBox(height: 24),

          // 2. 7-Day Safety Forecast Bar
          CycleForecastBar(
            lastPeriodStartDate: repo.lastPeriodStartDate,
            cycleLength: repo.cycleLength,
            periodLength: repo.periodLength,
            safetyBufferDays: repo.safetyBufferDays,
          ),

          const SizedBox(height: 28),

          // 3. Bottom Action: Log Period (Tracker) or Live Sync Banner (Partner)
          if (repo.tracksCycle)
            InkWell(
              onTap: () => _openPeriodModal(context),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppTheme.roseGold.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B113B).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.water_drop_rounded,
                      size: 20,
                      color: AppTheme.crimson,
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 19,
                      color: AppTheme.plum,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Log Period / Adjust Parameters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.plum,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.roseGold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B113B).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.blush.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sync_lock_rounded,
                      size: 20,
                      color: AppTheme.crimson,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Managed by ${repo.partnerName.isNotEmpty ? repo.partnerName : 'your partner'}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.plum,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Period logs and cycle dates are recorded by her and synced to your device in real time.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              repo.isPaired && repo.partnerName.isNotEmpty
                  ? 'Synced with ${repo.partnerName} · Live fertility status'
                  : 'Local tracking · Natural fertility estimation',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(coupleRepositoryProvider);
    final fertility = ref.watch(todayFertilityProvider);
    final mood = ref.watch(todayMoodStatusProvider);
    final scheduledDates = ref.watch(scheduledDatesProvider);
    final unreadCount = ref.watch(unreadMemoriesCountProvider);
    final now = DateTime.now();
    ScheduledIntimacy? nextDate;
    if (scheduledDates.isNotEmpty) {
      final upcoming = scheduledDates
          .where((d) => !d.scheduledAt.toLocal().isBefore(now) && d.status != IntimacyStatus.completed && d.status != IntimacyStatus.rainchecked && d.status != IntimacyStatus.canceled)
          .toList();
      if (upcoming.isNotEmpty) {
        upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        nextDate = upcoming.first;
      }
    }

    if (repo.isPaired && repo.partnerName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(coupleRepositoryProvider.notifier).pingPartner();
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 10,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondaryContainer, AppTheme.crimson],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.crimson.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.favorite_rounded, color: Colors.white, size: 15),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LoveSync',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: AppTheme.plum,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (repo.isPaired)
            InkWell(
              onTap: () => _openPartnerModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.blush),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B113B).withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.crimson,
                      ),
                      child: ClipOval(
                        child: repo.partnerAvatarUrl.isNotEmpty
                            ? Image.network(
                                repo.partnerAvatarUrl,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    repo.partnerName.isNotEmpty ? repo.partnerName[0].toUpperCase() : 'P',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  repo.partnerName.isNotEmpty ? repo.partnerName[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Partner',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.plumLight,
                              height: 1.1,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            repo.partnerName.isNotEmpty ? repo.partnerName : 'Connected',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.plum,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _openPairingModal(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppTheme.crimson),
              label: const Text(
                'Add Partner',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.crimson,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          // User Google Profile Avatar (Next to My Partner chip)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _openUserProfileModal(context, repo),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceContainerLow,
                  border: Border.all(color: AppTheme.blush, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B113B).withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: repo.userAvatarUrl.isNotEmpty
                      ? Image.network(
                          repo.userAvatarUrl,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              repo.currentUserName.isNotEmpty ? repo.currentUserName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: AppTheme.crimson,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            repo.currentUserName.isNotEmpty ? repo.currentUserName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppTheme.crimson,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Memories & Spark Inbox',
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                '$unreadCount',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.crimson,
              child: const Icon(
                Icons.mail_outline_rounded,
                color: AppTheme.plum,
                size: 22,
              ),
            ),
            onPressed: () => _openMemoriesModal(context),
          ),
          PopupMenuButton<String>(
            padding: const EdgeInsets.only(right: 6),
            icon: const Icon(Icons.more_vert, color: AppTheme.plum),
            onSelected: (val) async {
              if (val == 'memories') {
                _openMemoriesModal(context);
              } else if (val == 'partner_info') {
                _openPartnerModal(context);
              } else if (val == 'edit_profile') {
                await ref.read(coupleRepositoryProvider.notifier).returnToProfileSetup();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
                    (route) => false,
                  );
                }
              } else if (val == 'disclaimer') {
                MedicalDisclaimer.showDisclaimerDialog(context);
              } else if (val == 'protect') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud backup is active with Supabase!')),
                );
              } else if (val == 'disconnect') {
                _confirmDisconnect(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'memories',
                child: Row(
                  children: [
                    Icon(
                      unreadCount > 0 ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
                      size: 18,
                      color: AppTheme.crimson,
                    ),
                    const SizedBox(width: 8),
                    Text(unreadCount > 0 ? 'Memories Inbox ($unreadCount new)' : 'Memories Inbox'),
                  ],
                ),
              ),
              if (repo.isPaired)
                PopupMenuItem(
                  value: 'partner_info',
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, size: 18, color: AppTheme.crimson),
                      const SizedBox(width: 8),
                      Text(repo.partnerName.isNotEmpty ? 'My Partner (${repo.partnerName})' : 'My Partner'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit_profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppTheme.crimson),
                    SizedBox(width: 8),
                    Text('Edit Name & Role'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'protect',
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: AppTheme.crimson),
                    SizedBox(width: 8),
                    Text('Cloud Protection Active'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'disclaimer',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.crimson),
                    SizedBox(width: 8),
                    Text('Medical Disclaimer'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Disconnect / Re-pair Space'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildSexTab(context, repo, mood, nextDate, unreadCount),
            _buildCycleTab(context, repo, fertility),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex.clamp(0, 1),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded, color: AppTheme.crimson),
            label: 'Sex & Intimacy',
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa_rounded, color: AppTheme.crimson),
            label: repo.tracksCycle
                ? 'Cycle & Period'
                : (repo.isPaired && repo.partnerName.isNotEmpty
                    ? '${repo.partnerName}\'s Cycle'
                    : 'Her Cycle'),
          ),
        ],
      ),
    );
  }
}
