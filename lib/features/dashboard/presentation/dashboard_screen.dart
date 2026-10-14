import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_app/core/constants/medical_disclaimer.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';
import 'package:love_app/features/cycle/presentation/period_log_modal.dart';
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
import 'package:love_app/features/memories/presentation/memories_inbox_modal.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
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
        onDisconnectPartner: () {
          ref.read(coupleRepositoryProvider.notifier).disconnectPartner();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partner removed. Returned to individual mode.')),
          );
        },
      ),
    );
  }

  void _openMemoriesModal(BuildContext context) {
    ref.read(coupleRepositoryProvider.notifier).markMemoriesAsRead();
    final memories = ref.read(coupleMemoriesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MemoriesInboxModal(memories: memories),
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
          // Tonight's Alignment Greeting Header
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.crimson,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "TONIGHT'S ALIGNMENT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.crimson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
                    // 1. Double-Blind Mood Matching ("The Spark") with Stitch styling
                    SparkButton(
                      moodStatus: mood,
                      partnerName: repo.partnerName,
                      userName: repo.currentUserName,
                      onToggle: () async {
                        if (mood.isMatch) {
                          await ref.read(coupleRepositoryProvider.notifier).turnOffSparkMatch();
                        } else {
                          await ref.read(coupleRepositoryProvider.notifier).toggleMoodSignal();
                        }
                      },
                    ),

                    if (ref.watch(coupleMemoriesProvider).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _openMemoriesModal(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.blush, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (unreadCount > 0 ? AppTheme.crimson : AppTheme.plum).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  unreadCount > 0 ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
                                  size: 18,
                                  color: unreadCount > 0 ? AppTheme.crimson : AppTheme.plum,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Spark & Memory Inbox',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.plum,
                                          ),
                                        ),
                                        if (unreadCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.crimson,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$unreadCount NEW',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ref.watch(coupleMemoriesProvider).first.title,
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
                              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Schedule a Date / Upcoming Date Night Option
                    ScheduledDateCard(
                      dateItem: nextDate,
                      currentUserId: repo.currentUserId,
                      lastPeriodStartDate: repo.lastPeriodStartDate,
                      cycleLength: repo.cycleLength,
                      periodLength: repo.periodLength,
                      safetyBufferDays: repo.safetyBufferDays,
                      onOpenScheduleModal: () => _openScheduleModal(context),
                      onRespond: (id, status) {
                        ref.read(coupleRepositoryProvider.notifier).respondToDate(id, status);
                      },
                      onRespondVibeCheck: (id, status) {
                        ref.read(coupleRepositoryProvider.notifier).respondVibeCheck(id, status);
                      },
                    ),
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

  Widget _buildCycleTab(
    BuildContext context,
    CoupleRepository repo,
    DailyFertilityInfo fertility,
  ) {
    return SingleChildScrollView(
      key: const PageStorageKey('cycle_tab_scroll'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Disclaimer Notice Banner
          InkWell(
            onTap: () => MedicalDisclaimer.showDisclaimerDialog(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cautionAmberBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cautionAmber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: AppTheme.cautionAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MedicalDisclaimer.shortBanner,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF92400E)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 1. Safe Window Fertility Dial
          FertilityDial(
            fertilityInfo: fertility,
            canLog: repo.tracksCycle,
            managerName: repo.partnerName,
            onLogPeriod: () => _openPeriodModal(context),
          ),

          const SizedBox(height: 20),

          // 2. 7-Day Safety Forecast Bar
          CycleForecastBar(
            lastPeriodStartDate: repo.lastPeriodStartDate,
            cycleLength: repo.cycleLength,
            periodLength: repo.periodLength,
            safetyBufferDays: repo.safetyBufferDays,
          ),

          const SizedBox(height: 30),
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
    final nextDate = scheduledDates.isNotEmpty ? scheduledDates.first : null;

    if (repo.isPaired && repo.partnerName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(coupleRepositoryProvider.notifier).pingPartner();
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
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
                child: Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LoveSync',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: -0.3,
                color: AppTheme.plum,
              ),
            ),
          ],
        ),
        actions: [
          if (repo.isPaired)
            InkWell(
              onTap: () => _openPartnerModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.crimson,
                      child: Text(
                        repo.partnerName.isNotEmpty ? repo.partnerName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Partner',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.plumLight,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            repo.partnerName.isNotEmpty ? repo.partnerName : 'Connected',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.plum,
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
        child: !repo.tracksCycle
            ? _buildSexTab(context, repo, mood, nextDate, unreadCount)
            : PageView(
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
      bottomNavigationBar: repo.tracksCycle
          ? NavigationBar(
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.local_fire_department_outlined),
                  selectedIcon: Icon(Icons.local_fire_department_rounded, color: AppTheme.crimson),
                  label: 'Sex & Intimacy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.spa_outlined),
                  selectedIcon: Icon(Icons.spa_rounded, color: AppTheme.crimson),
                  label: 'Cycle & Period',
                ),
              ],
            )
          : null,
    );
  }
}
