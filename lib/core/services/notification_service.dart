import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:love_app/core/services/sound_player/sound_player.dart';

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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final isSparkMatch = (id == 1) || title.contains('Match') || title.contains('Spark');

    // 1. Play unique spark chime sound
    if (isSparkMatch) {
      playSparkSound();
    }

    // 2. Heartbeat Haptic Feedback
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // 3. Distinct Red In-App Floating Notification Banner (Visible on Web & Mobile Foreground)
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
                gradient: isSparkMatch
                    ? const LinearGradient(
                        colors: [Color(0xFF8B0029), Color(0xFFC70039), Color(0xFFFF1E56)],
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
                  color: isSparkMatch ? const Color(0xFFFF7597) : Colors.white24,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSparkMatch ? const Color(0xFFC70039) : Colors.black)
                        .withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: Text(
                      isSparkMatch ? '🔥' : '✨',
                      style: const TextStyle(fontSize: 22),
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
                            if (isSparkMatch)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SPARK',
                                  style: TextStyle(
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

    // 4. Android System Notification with Custom Red Coloring & Heartbeat Sound
    final androidDetails = isSparkMatch
        ? AndroidNotificationDetails(
            'lovesync_spark_channel_v3',
            'LoveSync Spark Matches 🔥',
            channelDescription: 'Passionate red celebration alerts for mutual spark matches',
            importance: Importance.max,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound('spark_match'),
            playSound: true,
            enableLights: true,
            ledColor: const Color(0xFFFF0055),
            ledOnMs: 1000,
            ledOffMs: 500,
            color: const Color(0xFFD61A4C), // Passionate Crimson Red
            colorized: true, // Paints the Android notification header & accents in red
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 250, 150, 250, 150, 400]), // heartbeat pulse
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'LoveSync Intimacy Spark',
            ),
          )
        : const AndroidNotificationDetails(
            'lovesync_channel',
            'LoveSync Alerts',
            channelDescription: 'Notifications for mutual spark matches and date night proposals',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            color: Color(0xFFC0264D),
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
      debugPrint('Error showing notification: $e');
    }
  }
}
