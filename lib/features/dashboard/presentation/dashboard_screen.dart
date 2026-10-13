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

  Widget _buildSexTab(
    BuildContext context,
    CoupleRepository repo,
    MoodStatus mood,
    ScheduledIntimacy? nextDate,
  ) {
    return SingleChildScrollView(
      key: const PageStorageKey('sex_tab_scroll'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    // 1. Double-Blind Mood Matching ("The Spark")
                    SparkButton(
                      moodStatus: mood,
                      onToggle: () {
                        ref.read(coupleRepositoryProvider.notifier).toggleMoodSignal();
                      },
                    ),

                    const SizedBox(height: 20),

                    // 2. Low-Pressure Scheduled Intimacy Card
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.blush,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.roseGold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(Icons.favorite_rounded, color: AppTheme.crimson, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LoveSync',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  color: AppTheme.blush.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.3)),
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
                backgroundColor: AppTheme.blush.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          PopupMenuButton<String>(
            padding: const EdgeInsets.only(right: 6),
            icon: const Icon(Icons.more_vert, color: AppTheme.plum),
            onSelected: (val) async {
              if (val == 'partner_info') {
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
            ? _buildSexTab(context, repo, mood, nextDate)
            : PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _buildSexTab(context, repo, mood, nextDate),
                  _buildCycleTab(context, repo, fertility),
                ],
              ),
      ),
      bottomNavigationBar: repo.tracksCycle
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
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
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Sex & Intimacy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop_rounded),
                  label: 'Cycle & Period',
                ),
              ],
            )
          : null,
    );
  }
}
