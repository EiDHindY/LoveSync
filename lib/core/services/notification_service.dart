import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:love_app/core/services/sound_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone init notice: $e');
    }

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Request notification permissions for Android 13+
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Notification init notice: $e');
    }
  }

  static String _resolveNotificationIcon({
    required int id,
    required String title,
    String? explicitIcon,
  }) {
    if (explicitIcon != null && explicitIcon.isNotEmpty) {
      return explicitIcon;
    }
    final lowerTitle = title.toLowerCase();
    if (id == 1 || id == 3 || lowerTitle.contains('match') || lowerTitle.contains('spark ignited') || lowerTitle.contains('accepted') || lowerTitle.contains('confirmed')) {
      return 'notif_spark_match';
    }
    if (id == 2 || lowerTitle.contains('proposal') || lowerTitle.contains('rendezvous')) {
      return 'notif_date_proposal';
    }
    if (id == 4 || id == 21 || lowerTitle.contains('cancel')) {
      return 'notif_canceled';
    }
    if (id == 10 || lowerTitle.contains('connected') || lowerTitle.contains('joined')) {
      return 'notif_partner_connected';
    }
    if (id == 9001 || lowerTitle.contains('period') || lowerTitle.contains('cycle begins')) {
      return 'notif_date_nudge';
    }
    if (id == 9002 || lowerTitle.contains('safe window')) {
      return 'notif_spark_match';
    }
    if (id >= 1000 || lowerTitle.contains('tomorrow') || lowerTitle.contains('1 hour') || lowerTitle.contains('nudge')) {
      return 'notif_date_nudge';
    }
    return 'notif_default';
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? soundId,
    String? iconName,
  }) async {
    final effectiveSound = (soundId != null && soundId.isNotEmpty) ? soundId : 'heartbeat_pulse';
    final hasExplicitSound = soundId != null && soundId.isNotEmpty;
    final isSparkOrAccepted = (id == 1) || (id == 3) || title.contains('Match') || title.contains('Spark') || title.toLowerCase().contains('accepted');
    final isNudge = title.contains('Tomorrow') || title.contains('1 Hour') || title.contains('Nudge') || (soundId == 'classic_spark');
    final isCancel = (id == 4) || (id == 21) || title.toLowerCase().contains('cancel');

    final iconDrawable = _resolveNotificationIcon(
      id: id,
      title: title,
      explicitIcon: iconName,
    );

    // 1. Play unique chime sound
    if (hasExplicitSound || isSparkOrAccepted) {
      SoundService().playSound(effectiveSound);
    }

    // 2. Soft & Gentle Haptic Feedback
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    // 3. Distinct In-App Floating Notification Banner (Visible on Web & Mobile Foreground)
    try {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 7),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSparkOrAccepted
                    ? const LinearGradient(
                        colors: [Color(0xFF8B0029), Color(0xFFC70039), Color(0xFFFF1E56)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : isNudge
                        ? const LinearGradient(
                            colors: [Color(0xFF9C1B4E), Color(0xFFC0264D), Color(0xFFFF3366)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : isCancel
                            ? const LinearGradient(
                                colors: [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF4A0E2E), Color(0xFF6B113B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isSparkOrAccepted || isNudge) ? const Color(0xFFFF7597) : Colors.white24,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSparkOrAccepted ? const Color(0xFFC70039) : Colors.black)
                        .withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/notifications/$iconDrawable.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            isSparkOrAccepted ? '🔥' : (isNudge ? '💕' : (isCancel ? '🍃' : '✨')),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSparkOrAccepted
                                    ? (title.toLowerCase().contains('accepted') ? 'DATE' : 'SPARK')
                                    : (isNudge ? 'NUDGE' : (isCancel ? 'NOTICE' : 'DATE')),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing in-app banner: $e');
    }

    if (kIsWeb) {
      debugPrint('[Web Notification] $title: $body');
      return;
    }

    // 4. Android System Notification with Custom Red Coloring, Large Icon & Chime
    final androidDetails = (hasExplicitSound || isSparkOrAccepted)
        ? AndroidNotificationDetails(
            'lovesync_channel_$effectiveSound',
            'LoveSync Alerts',
            channelDescription: 'Romantic alerts, mutual spark matches, and date night nudges',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(effectiveSound),
            playSound: true,
            enableLights: true,
            ledColor: const Color(0xFFFF0055),
            ledOnMs: 1000,
            ledOffMs: 500,
            color: const Color(0xFFD61A4C), // Passionate Crimson Red
            colorized: true, // Paints the Android notification header & accents in red
            largeIcon: DrawableResourceAndroidBitmap(iconDrawable),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 80, 100, 80]), // soft tender pulse
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: isSparkOrAccepted
                  ? 'LoveSync Intimacy Spark'
                  : (isNudge ? 'LoveSync Intimacy Nudge' : (isCancel ? 'LoveSync Notice' : 'LoveSync Date Night')),
            ),
          )
        : AndroidNotificationDetails(
            'lovesync_channel',
            'LoveSync Alerts',
            channelDescription: 'Notifications for mutual spark matches and date night proposals',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap(iconDrawable),
            showWhen: true,
            enableVibration: true,
            color: const Color(0xFFC0264D),
          );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification with custom sound: $e');
      try {
        final fallbackAndroid = AndroidNotificationDetails(
          'lovesync_channel',
          'LoveSync Alerts',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          largeIcon: DrawableResourceAndroidBitmap(iconDrawable),
          color: const Color(0xFFD61A4C),
        );
        await _notificationsPlugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(android: fallbackAndroid),
          payload: payload,
        );
      } catch (_) {}
    }
  }

  /// Schedules a future system notification (e.g. 1 day before or 1 hour before scheduled date)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? soundId,
    String? payload,
    String? iconName,
  }) async {
    if (kIsWeb) return;
    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    final effectiveSound = (soundId != null && soundId.isNotEmpty) ? soundId : 'classic_spark';
    final iconDrawable = _resolveNotificationIcon(
      id: id,
      title: title,
      explicitIcon: iconName ?? 'notif_date_nudge',
    );

    final androidDetails = AndroidNotificationDetails(
      'lovesync_nudge_channel_$effectiveSound',
      'LoveSync Nudges & Reminders',
      channelDescription: 'Gentle intimate nudges before scheduled rendezvous',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(effectiveSound),
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFFFF0055),
      ledOnMs: 1000,
      ledOffMs: 500,
      color: const Color(0xFFD61A4C),
      colorized: true,
      largeIcon: DrawableResourceAndroidBitmap(iconDrawable),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 100, 150, 100]),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: (id == 9001 || id == 9002)
            ? 'LoveSync Cycle Guide'
            : 'LoveSync Intimacy Nudge',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Cancels a scheduled or active notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }
}
