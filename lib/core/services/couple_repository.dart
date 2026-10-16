import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:love_app/core/config/supabase_config.dart';
import 'package:love_app/core/services/notification_service.dart';
import 'package:love_app/features/chat/domain/chat_message.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/memories/domain/couple_memory.dart';
import 'package:love_app/features/mood/domain/mood_status.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';

class CoupleRepository extends ChangeNotifier {
  static const _kPrefKey = 'lovesync_state_v2';
  final _uuid = const Uuid();

  // User & Partner
  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserRole = 'partner';
  bool _tracksCycle = true;
  String _privacyPin = '';
  String _recoveryEmail = '';
  bool _hasCreatedProfile = false;

  String _partnerId = '';
  String _partnerName = '';
  String _partnerRole = '';
  String _partnerAvatarUrl = '';
  bool _partnerTracksCycle = false;

  // Couple Info
  bool _hasCompletedOnboarding = false;
  bool _isPaired = false;
  String _inviteCode = '';
  String _coupleId = '';

  // Cycle Configuration
  DateTime? _lastPeriodStartDate;
  int _cycleLength = 28;
  int _periodLength = 5;
  int _safetyBufferDays = 2;

  // Mood Signals Map: DateKey -> { userId: bool }
  final Map<String, Map<String, bool>> _moodSignals = {};

  // Scheduled Intimacy List
  final List<ScheduledIntimacy> _scheduledDates = [];

  // Couple Memories & Spark History
  final List<CoupleMemory> _memories = [];
  final Set<String> _readMemoryIds = {};
  DateTime? _lastViewedMemoriesAt;

  // Direct Messages & Chat
  final List<ChatMessage> _chatMessages = [];

  RealtimeChannel? _realtimeChannel;

  String _userEmail = '';
  String _userAvatarUrl = '';
  String _sparkSoundId = 'heartbeat_pulse';
  String _cancelSoundId = 'sunset_marimba';
  String _dateRequestSoundId = 'moonlight_vibe';
  final Set<String> _firedNudgeKeys = {};
  StreamSubscription<AuthState>? _authSubscription;

  // Getters
  String get sparkSoundId => _sparkSoundId;
  String get cancelSoundId => _cancelSoundId;
  String get dateRequestSoundId => _dateRequestSoundId;

  Future<void> setSparkSound(String soundId) async {
    _sparkSoundId = soundId;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setCancelSound(String soundId) async {
    _cancelSoundId = soundId;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setDateRequestSound(String soundId) async {
    _dateRequestSoundId = soundId;
    await _saveToStorage();
    notifyListeners();
  }
  String get currentUserId => _currentUserId;
  String get currentUserName {
    if (_currentUserName.isNotEmpty) return _currentUserName;
    if (SupabaseConfig.isInitialized) {
      final current = Supabase.instance.client.auth.currentUser;
      if (current != null) return _extractDisplayName(current);
    }
    return '';
  }
  String get currentUserRole => _currentUserRole;
  String get userEmail {
    if (_userEmail.isNotEmpty) return _userEmail;
    if (SupabaseConfig.isInitialized) {
      return Supabase.instance.client.auth.currentUser?.email ?? '';
    }
    return '';
  }
  String get userAvatarUrl {
    if (_userAvatarUrl.isNotEmpty) return _userAvatarUrl;
    if (SupabaseConfig.isInitialized) {
      final current = Supabase.instance.client.auth.currentUser;
      if (current != null) return _extractAvatarUrl(current);
    }
    return '';
  }
  bool get isSignedIn => userEmail.isNotEmpty || (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null);
  bool get tracksCycle => _tracksCycle;
  String get privacyPin => _privacyPin;
  String get recoveryEmail => _recoveryEmail;
  bool get hasCreatedProfile => _hasCreatedProfile;
  bool get hasPrivacyPin => _privacyPin.isNotEmpty;
  String get partnerName => _partnerName;
  String get partnerRole => _partnerRole;
  String get partnerAvatarUrl => _partnerAvatarUrl;
  bool get partnerTracksCycle => _partnerTracksCycle;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isPaired => _isPaired;
  String get inviteCode => _inviteCode;
  String get coupleId => _coupleId;
  DateTime? get lastPeriodStartDate => _lastPeriodStartDate;
  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;
  int get safetyBufferDays => _safetyBufferDays;
  List<ScheduledIntimacy> get scheduledDates {
    autoClosePastDates(notify: false);
    return List.unmodifiable(_scheduledDates);
  }

  bool autoClosePastDates({bool notify = true}) {
    final now = DateTime.now();
    bool changed = false;
    for (int i = 0; i < _scheduledDates.length; i++) {
      final date = _scheduledDates[i];
      if (date.status != IntimacyStatus.completed && date.scheduledAt.toLocal().isBefore(now)) {
        _scheduledDates[i] = date.copyWith(status: IntimacyStatus.completed);
        changed = true;
      }
    }
    checkDateNudges();
    if (changed) {
      _saveToStorage();
      if (notify) notifyListeners();
    }
    return changed;
  }

  int _nudgeDayId(String dateId) => (dateId.hashCode.abs() % 100000) * 10 + 1;
  int _nudgeHourId(String dateId) => (dateId.hashCode.abs() % 100000) * 10 + 2;

  Future<void> _scheduleNudgesForDate(ScheduledIntimacy date) async {
    if (date.status != IntimacyStatus.accepted) return;
    final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'your partner';
    final targetTime = date.scheduledAt.toLocal();
    final now = DateTime.now();

    // 1. Day before (24 hours prior)
    final dayBefore = targetTime.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      await NotificationService().scheduleNotification(
        id: _nudgeDayId(date.id),
        title: 'Upcoming Date Tomorrow 💕',
        body: 'Get ready for tomorrow\'s intimate rendezvous with $partnerDisplay!',
        scheduledDate: dayBefore,
        soundId: 'classic_spark',
      );
    }

    // 2. One hour before
    final hourBefore = targetTime.subtract(const Duration(hours: 1));
    if (hourBefore.isAfter(now)) {
      await NotificationService().scheduleNotification(
        id: _nudgeHourId(date.id),
        title: 'Date Night in 1 Hour 💕',
        body: 'Just one hour until your intimate rendezvous with $partnerDisplay! ✨',
        scheduledDate: hourBefore,
        soundId: 'classic_spark',
      );
    }
  }

  Future<void> _cancelNudgesForDate(String dateId) async {
    await NotificationService().cancelNotification(_nudgeDayId(dateId));
    await NotificationService().cancelNotification(_nudgeHourId(dateId));
    _firedNudgeKeys.remove('${dateId}_day_before');
    _firedNudgeKeys.remove('${dateId}_one_hour');
  }

  void _rescheduleAllUpcomingNudges() {
    final now = DateTime.now();
    for (final date in _scheduledDates) {
      if (date.status == IntimacyStatus.accepted && date.scheduledAt.toLocal().isAfter(now)) {
        _scheduleNudgesForDate(date);
      }
    }
  }

  void checkDateNudges() {
    final now = DateTime.now();
    final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'your partner';
    bool firedAny = false;

    for (final date in _scheduledDates) {
      if (date.status != IntimacyStatus.accepted) continue;
      final target = date.scheduledAt.toLocal();

      // Day before window: between [target - 24 hours] and [target - 1 hour]
      final dayBeforeStart = target.subtract(const Duration(days: 1));
      final hourBeforeStart = target.subtract(const Duration(hours: 1));
      final dayKey = '${date.id}_day_before';
      if (now.isAfter(dayBeforeStart) && now.isBefore(hourBeforeStart)) {
        if (!_firedNudgeKeys.contains(dayKey)) {
          _firedNudgeKeys.add(dayKey);
          firedAny = true;
          NotificationService().showNotification(
            id: _nudgeDayId(date.id),
            title: 'Upcoming Date Tomorrow 💕',
            body: 'Get ready for tomorrow\'s intimate rendezvous with $partnerDisplay!',
            soundId: 'classic_spark',
          );
        }
      }

      // 1 hour before window: between [target - 1 hour] and [target]
      final hourKey = '${date.id}_one_hour';
      if (now.isAfter(hourBeforeStart) && now.isBefore(target)) {
        if (!_firedNudgeKeys.contains(hourKey)) {
          _firedNudgeKeys.add(hourKey);
          firedAny = true;
          NotificationService().showNotification(
            id: _nudgeHourId(date.id),
            title: 'Date Night in 1 Hour 💕',
            body: 'Just one hour until your intimate rendezvous with $partnerDisplay! ✨',
            soundId: 'classic_spark',
          );
        }
      }
    }

    if (firedAny) {
      _saveToStorage();
    }
  }

  static const int kNotifCycleStartDayBeforeId = 9001;
  static const int kNotifSafeWindowDayBeforeId = 9002;

  Future<void> scheduleCycleNotifications() async {
    if (_lastPeriodStartDate == null) {
      await NotificationService().cancelNotification(kNotifCycleStartDayBeforeId);
      await NotificationService().cancelNotification(kNotifSafeWindowDayBeforeId);
      return;
    }

    final now = DateTime.now();
    final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'your partner';

    // 1. Day before cycle begins (scheduled at 10:00 AM local time)
    final cycleStartNotifDate = CycleEngine.getNextDayBeforeCycleStarts(
      fromDate: now,
      lastPeriodStartDate: _lastPeriodStartDate,
      cycleLength: _cycleLength,
      notificationHour: 10,
      notificationMinute: 0,
    );

    if (cycleStartNotifDate != null && cycleStartNotifDate.isAfter(now)) {
      final String title;
      final String body;
      if (_tracksCycle) {
        title = 'Period Expected Tomorrow 🌸';
        body = 'Your new cycle begins tomorrow. Take time to rest, hydrate, and care for yourself today.';
      } else {
        title = '$partnerDisplay\'s Cycle Begins Tomorrow 🌸';
        body = 'Her new cycle starts tomorrow. Be extra gentle, supportive, and show her some extra love today. 💕';
      }

      await NotificationService().scheduleNotification(
        id: kNotifCycleStartDayBeforeId,
        title: title,
        body: body,
        scheduledDate: cycleStartNotifDate,
        soundId: 'sunset_marimba',
        iconName: 'notif_date_nudge',
      );
    }

    // 2. Day before safe window begins (scheduled at 10:00 AM local time)
    final safeWindowNotifDate = CycleEngine.getNextDayBeforeSafeWindowStarts(
      fromDate: now,
      lastPeriodStartDate: _lastPeriodStartDate,
      cycleLength: _cycleLength,
      safetyBufferDays: _safetyBufferDays,
      notificationHour: 10,
      notificationMinute: 0,
    );

    if (safeWindowNotifDate != null && safeWindowNotifDate.isAfter(now)) {
      final String title;
      final String body;
      if (_tracksCycle) {
        title = 'Safe Window Begins Tomorrow 🟢';
        body = 'Post-ovulation caution ends today. Your naturally safe window begins tomorrow.';
      } else {
        title = 'Safe Window Begins Tomorrow 🟢';
        body = 'Fertile caution period ends today. Safe intimacy window with $partnerDisplay begins tomorrow.';
      }

      await NotificationService().scheduleNotification(
        id: kNotifSafeWindowDayBeforeId,
        title: title,
        body: body,
        scheduledDate: safeWindowNotifDate,
        soundId: 'classic_spark',
        iconName: 'notif_spark_match',
      );
    }
  }

  List<CoupleMemory> get memories => List.unmodifiable(_memories);
  int get unreadMemoriesCount => _memories.where((m) => !_readMemoryIds.contains(m.id)).length;
  bool isMemoryRead(String id) => _readMemoryIds.contains(id);

  Future<void> markMemoriesAsRead() async {
    if (_memories.isEmpty) return;
    _readMemoryIds.addAll(_memories.map((m) => m.id));
    _lastViewedMemoriesAt = DateTime.now();
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clearAllMemories() async {
    _memories.clear();
    _readMemoryIds.clear();
    _lastViewedMemoriesAt = null;
    await _saveToStorage();

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        await Supabase.instance.client.rpc('clear_couple_memories', params: {
          'p_couple_id': _coupleId,
        });
      } catch (e) {
        debugPrint('Notice clearing memories via RPC: $e');
        try {
          await Supabase.instance.client
              .from('couple_memories')
              .delete()
              .eq('couple_id', _coupleId);
        } catch (e2) {
          debugPrint('Notice deleting couple memories: $e2');
        }
      }
    }

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'memories_cleared',
          payload: {'couple_id': _coupleId},
        );
      } catch (e) {
        debugPrint('Broadcast memories_cleared error: $e');
      }
    }
    notifyListeners();
  }

  // Direct Messages & Chat Getters
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  int get unreadChatCount => _chatMessages.where((m) => m.senderId != _currentUserId && m.readAt == null).length;

  // ══════════════════════════════════════════════════════
  // DIRECT MESSAGES (DM) CHAT ENGINE
  // ══════════════════════════════════════════════════════
  Future<void> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msg = ChatMessage(
      id: _uuid.v4(),
      coupleId: _coupleId,
      senderId: _currentUserId,
      text: trimmed,
      createdAt: DateTime.now().toUtc(),
    );

    _chatMessages.add(msg);
    if (_chatMessages.length > 500) {
      _chatMessages.removeRange(0, _chatMessages.length - 500);
    }
    await _saveToStorage();
    notifyListeners();

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'chat_message',
          payload: {
            'sender_id': _currentUserId,
            'data': msg.toJson(),
          },
        );
      } catch (e) {
        debugPrint('Notice broadcasting chat_message: $e');
      }
    }

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client.from('couple_chat_messages').insert(msg.toJson());
      } catch (e) {
        debugPrint('Notice inserting chat message: $e');
      }
    }
  }

  Future<void> sendViewOncePhoto({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final msgId = _uuid.v4();
    String? publicUrl;
    final fileName = '$msgId.$fileExtension';
    final storagePath = '$_coupleId/$fileName';

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client.storage.from('chat_images').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );
        publicUrl = client.storage.from('chat_images').getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Notice uploading photo to storage: $e');
      }
    }

    final msg = ChatMessage(
      id: msgId,
      coupleId: _coupleId,
      senderId: _currentUserId,
      text: 'View-Once Photo',
      imageUrl: publicUrl ?? storagePath,
      isViewOnce: true,
      isViewed: false,
      createdAt: DateTime.now().toUtc(),
    );

    _chatMessages.add(msg);
    if (_chatMessages.length > 500) {
      _chatMessages.removeRange(0, _chatMessages.length - 500);
    }
    await _saveToStorage();
    notifyListeners();

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'chat_message',
          payload: {
            'sender_id': _currentUserId,
            'data': msg.toJson(),
          },
        );
      } catch (e) {
        debugPrint('Notice broadcasting photo message: $e');
      }
    }

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client.from('couple_chat_messages').insert(msg.toJson());
      } catch (e) {
        debugPrint('Notice inserting photo message to DB: $e');
      }
    }
  }

  Future<void> markChatMessagesAsRead() async {
    final now = DateTime.now().toUtc();
    final unread = _chatMessages.where((m) => m.senderId != _currentUserId && m.readAt == null).toList();
    if (unread.isEmpty) return;

    for (int i = 0; i < _chatMessages.length; i++) {
      final m = _chatMessages[i];
      if (m.senderId != _currentUserId && m.readAt == null) {
        _chatMessages[i] = m.copyWith(readAt: now);
      }
    }
    await _saveToStorage();
    notifyListeners();

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'chat_read',
          payload: {
            'sender_id': _currentUserId,
            'read_at': now.toIso8601String(),
          },
        );
      } catch (e) {
        debugPrint('Notice broadcasting chat_read: $e');
      }
    }

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        final unreadIds = unread.map((m) => m.id).toList();
        await client.from('couple_chat_messages').update({
          'read_at': now.toIso8601String(),
        }).inFilter('id', unreadIds);
      } catch (e) {
        debugPrint('Notice updating read_at in Supabase: $e');
      }
    }
  }

  Future<void> reactToChatMessage(String messageId, String emoji) async {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final existing = _chatMessages[idx];
    final updatedReactions = Map<String, String>.from(existing.reactions);
    if (updatedReactions[_currentUserId] == emoji) {
      updatedReactions.remove(_currentUserId);
    } else {
      updatedReactions[_currentUserId] = emoji;
    }
    _chatMessages[idx] = existing.copyWith(reactions: updatedReactions);
    await _saveToStorage();
    notifyListeners();

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'chat_reaction',
          payload: {
            'message_id': messageId,
            'sender_id': _currentUserId,
            'emoji': updatedReactions[_currentUserId] ?? '',
          },
        );
      } catch (e) {
        debugPrint('Notice broadcasting chat_reaction: $e');
      }
    }

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client.from('couple_chat_messages').update({
          'reactions': updatedReactions,
        }).eq('id', messageId);
      } catch (e) {
        debugPrint('Notice updating reaction in Supabase: $e');
      }
    }
  }

  Future<void> viewAndBurnPhoto(String messageId) async {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final existing = _chatMessages[idx];
    if (existing.isViewed) return;

    final rawUrl = existing.imageUrl;
    _chatMessages[idx] = existing.copyWith(isViewed: true, clearImage: true);
    await _saveToStorage();
    notifyListeners();

    // Immediately remove from Supabase Storage bucket
    if (SupabaseConfig.isInitialized && rawUrl != null && rawUrl.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        String path = rawUrl;
        if (rawUrl.contains('/chat_images/')) {
          path = rawUrl.split('/chat_images/').last;
        }
        await client.storage.from('chat_images').remove([path]);
      } catch (e) {
        debugPrint('Notice deleting burned photo from storage: $e');
      }
    }

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'chat_photo_viewed',
          payload: {
            'message_id': messageId,
            'sender_id': _currentUserId,
          },
        );
      } catch (e) {
        debugPrint('Notice broadcasting chat_photo_viewed: $e');
      }
    }

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client.from('couple_chat_messages').update({
          'is_viewed': true,
          'image_url': null,
        }).eq('id', messageId);
      } catch (e) {
        debugPrint('Notice updating burned photo in Supabase: $e');
      }
    }
  }

  Future<void> clearChatHistory() async {
    _chatMessages.clear();
    await _saveToStorage();
    notifyListeners();

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'chat_cleared',
          payload: {
            'sender_id': _currentUserId,
          },
        );
      } catch (e) {
        debugPrint('Notice broadcasting chat_cleared: $e');
      }
    }

    if (SupabaseConfig.isInitialized && _coupleId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client.from('couple_chat_messages').delete().eq('couple_id', _coupleId);
      } catch (e) {
        debugPrint('Notice clearing chat history in Supabase: $e');
      }
    }
  }

  @visibleForTesting
  void addChatMessageForTesting(ChatMessage msg) {
    _chatMessages.add(msg);
    notifyListeners();
  }

  CoupleRepository() {
    _initAuthListener();
    _loadFromStorage().then((_) {
      if (_inviteCode.isNotEmpty) {
        _subscribeToChannel();
      }
      if (SupabaseConfig.isInitialized) {
        final current = Supabase.instance.client.auth.currentUser;
        if (current != null) {
          syncWithSupabaseUser(current);
        }
      }
    });
  }

  static String _extractAvatarUrl(User user) {
    final meta = user.userMetadata;
    if (meta != null) {
      final url = meta['avatar_url'] as String? ??
          meta['picture'] as String? ??
          meta['photoURL'] as String? ??
          meta['photo_url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
    final identities = user.identities;
    if (identities != null) {
      for (final identity in identities) {
        final idData = identity.identityData;
        if (idData != null) {
          final url = idData['avatar_url'] as String? ??
              idData['picture'] as String? ??
              idData['photoURL'] as String? ??
              idData['photo_url'] as String?;
          if (url != null && url.isNotEmpty) return url;
        }
      }
    }
    return '';
  }

  static String _extractDisplayName(User user) {
    final meta = user.userMetadata;
    if (meta != null) {
      final name = meta['full_name'] as String? ?? meta['name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    final identities = user.identities;
    if (identities != null) {
      for (final identity in identities) {
        final idData = identity.identityData;
        if (idData != null) {
          final name = idData['full_name'] as String? ?? idData['name'] as String?;
          if (name != null && name.isNotEmpty) return name;
        }
      }
    }
    return user.email?.split('@').first ?? '';
  }

  void _initAuthListener() {
    try {
      if (!SupabaseConfig.isInitialized) return;
      final auth = Supabase.instance.client.auth;
      final current = auth.currentUser;
      if (current != null) {
        _userEmail = current.email ?? '';
        _userAvatarUrl = _extractAvatarUrl(current);
        if (_currentUserName.isEmpty) {
          _currentUserName = _extractDisplayName(current);
        }
      }
      _authSubscription = auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          _userEmail = session.user.email ?? '';
          _userAvatarUrl = _extractAvatarUrl(session.user);
          if (_currentUserName.isEmpty) {
            _currentUserName = _extractDisplayName(session.user);
          }
          notifyListeners();
          await syncWithSupabaseUser(session.user);
        }
      });
    } catch (e) {
      debugPrint('Auth listener init error: $e');
    }
  }

  /// Generates the 12-hour cycle window key (4 AM - 4 PM Day, 4 PM - 4 AM Night).
  /// Every cycle lasts 12 hours and resets automatically at 4 AM and 4 PM.
  String _dateKey(DateTime dt) {
    final shifted = dt.subtract(const Duration(hours: 4));
    final period = (shifted.hour < 12) ? 'DAY' : 'NIGHT';
    final dateStr = '${shifted.year}-${shifted.month.toString().padLeft(2, '0')}-${shifted.day.toString().padLeft(2, '0')}';
    return '$dateStr-$period';
  }

  /// Whether current time is in the Daytime window (4:00 AM - 4:00 PM).
  bool get isDaySparkWindow {
    final shifted = DateTime.now().subtract(const Duration(hours: 4));
    return shifted.hour < 12;
  }

  static const String _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static String generateUniqueInviteCode() {
    final random = Random.secure();
    final buffer = StringBuffer('LOVE-');
    for (int i = 0; i < 6; i++) {
      buffer.write(_codeAlphabet[random.nextInt(_codeAlphabet.length)]);
    }
    return buffer.toString();
  }

  static String normalizeInviteCode(String raw) {
    var cleaned = raw.trim().toUpperCase().replaceAll(' ', '').replaceAll('_', '-');
    if (cleaned.isEmpty) return '';
    if (!cleaned.startsWith('LOVE-')) {
      if (cleaned.startsWith('LOVE')) {
        final remainder = cleaned.substring(4).replaceAll('-', '');
        cleaned = 'LOVE-$remainder';
      } else {
        cleaned = 'LOVE-$cleaned';
      }
    }
    return cleaned;
  }

  Timer? _beaconTimer;

  void startWaitingBeacon() {
    _beaconTimer?.cancel();
    _beaconTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isPaired && _partnerName.isNotEmpty) {
        timer.cancel();
        return;
      }
      if (_realtimeChannel != null) {
        try {
          _realtimeChannel!.sendBroadcastMessage(
            event: 'partner_beacon',
            payload: {
              'sender_id': _currentUserId,
              'sender_name': _currentUserName,
              'sender_role': _currentUserRole,
              'tracks_cycle': _tracksCycle,
              'sender_avatar_url': userAvatarUrl,
            },
          );
        } catch (e) {
          debugPrint('Error sending partner_beacon: $e');
        }
      }
    });
  }

  void stopWaitingBeacon() {
    _beaconTimer?.cancel();
    _beaconTimer = null;
  }

  void _sendPartnerAck() {
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 350), () {
        if (_realtimeChannel != null) {
          try {
            _realtimeChannel!.sendBroadcastMessage(
              event: 'partner_ack',
              payload: {
                'sender_id': _currentUserId,
                'sender_name': _currentUserName,
                'sender_role': _currentUserRole,
                'tracks_cycle': _tracksCycle,
                'sender_avatar_url': userAvatarUrl,
              },
            );
          } catch (e) {
            debugPrint('Error sending partner_ack: $e');
          }
        }
      });
    }
  }

  void _broadcastPartnerJoinWithRetry() {
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 600), (timer) async {
      attempts++;
      if (_realtimeChannel != null) {
        try {
          debugPrint('Realtime: Broadcasting partner_join (attempt $attempts) on $_inviteCode');
          await _realtimeChannel!.sendBroadcastMessage(
            event: 'partner_join',
            payload: {
              'sender_id': _currentUserId,
              'sender_name': _currentUserName,
              'sender_role': _currentUserRole,
              'tracks_cycle': _tracksCycle,
              'sender_avatar_url': userAvatarUrl,
            },
          );
        } catch (e) {
          debugPrint('Error sending partner_join broadcast: $e');
        }
      }
      if ((_partnerName.isNotEmpty && _partnerId.isNotEmpty) || attempts >= 8) {
        timer.cancel();
      }
    });
  }

  void pingPartner() {
    if (_realtimeChannel != null && _inviteCode.isNotEmpty) {
      try {
        _realtimeChannel!.sendBroadcastMessage(
          event: 'partner_ping',
          payload: {
            'sender_id': _currentUserId,
            'sender_name': _currentUserName,
            'sender_role': _currentUserRole,
            'tracks_cycle': _tracksCycle,
            'sender_avatar_url': userAvatarUrl,
          },
        );
      } catch (e) {
        debugPrint('Error sending partner_ping: $e');
      }
    }
  }

  void broadcastAvatarUpdate() {
    if (_realtimeChannel != null && _inviteCode.isNotEmpty && userAvatarUrl.isNotEmpty) {
      try {
        _realtimeChannel!.sendBroadcastMessage(
          event: 'partner_avatar_update',
          payload: {
            'sender_id': _currentUserId,
            'sender_avatar_url': userAvatarUrl,
          },
        );
      } catch (e) {
        debugPrint('Error broadcasting avatar update: $e');
      }
    }
  }

  void _subscribeToChannel() {
    if (!SupabaseConfig.isInitialized || _inviteCode.isEmpty) return;

    try {
      final client = Supabase.instance.client;
      if (_realtimeChannel != null) {
        client.removeChannel(_realtimeChannel!);
      }

      final normalized = normalizeInviteCode(_inviteCode);
      _inviteCode = normalized;
      final cleanCode = normalized.replaceAll('-', '_').toUpperCase();
      debugPrint('Realtime: Subscribing to channel lovesync_couple_$cleanCode');
      _realtimeChannel = client.channel('lovesync_couple_$cleanCode');

      _realtimeChannel!
          .onBroadcast(
            event: 'partner_join',
            callback: (payload) {
              debugPrint('Realtime: Received partner_join: $payload');
              final senderId = payload['sender_id'] as String?;
              final senderName = payload['sender_name'] as String? ?? 'Partner';
              final senderRole = payload['sender_role'] as String? ?? 'partner';
              final senderTracksCycle = payload['tracks_cycle'] as bool? ?? false;
              final senderAvatar = payload['sender_avatar_url'] as String? ?? '';

              if (senderId != null && senderId != _currentUserId) {
                _partnerId = senderId;
                _partnerName = senderName;
                _partnerRole = senderRole;
                _partnerTracksCycle = senderTracksCycle;
                if (senderAvatar.isNotEmpty) {
                  _partnerAvatarUrl = senderAvatar;
                }
                _isPaired = true;
                _saveToStorage();

                _sendPartnerAck();

                NotificationService().showNotification(
                  id: 10,
                  title: 'Partner Connected! 💕',
                  body: '$_partnerName joined your private LoveSync space.',
                );
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'partner_ack',
            callback: (payload) {
              debugPrint('Realtime: Received partner_ack: $payload');
              final senderId = payload['sender_id'] as String?;
              final senderName = payload['sender_name'] as String? ?? 'Partner';
              final senderRole = payload['sender_role'] as String? ?? 'partner';
              final senderTracksCycle = payload['tracks_cycle'] as bool? ?? false;
              final senderAvatar = payload['sender_avatar_url'] as String? ?? '';

              if (senderId != null && senderId != _currentUserId) {
                _partnerId = senderId;
                _partnerName = senderName;
                _partnerRole = senderRole;
                _partnerTracksCycle = senderTracksCycle;
                if (senderAvatar.isNotEmpty) {
                  _partnerAvatarUrl = senderAvatar;
                }
                _isPaired = true;
                _saveToStorage();
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'partner_beacon',
            callback: (payload) {
              final senderId = payload['sender_id'] as String?;
              final senderName = payload['sender_name'] as String? ?? 'Partner';
              final senderRole = payload['sender_role'] as String? ?? 'partner';
              final senderTracksCycle = payload['tracks_cycle'] as bool? ?? false;
              final senderAvatar = payload['sender_avatar_url'] as String? ?? '';

              if (senderId != null && senderId != _currentUserId) {
                if (_partnerId.isEmpty || _partnerName.isEmpty) {
                  _partnerId = senderId;
                  _partnerName = senderName;
                  _partnerRole = senderRole;
                  _partnerTracksCycle = senderTracksCycle;
                  if (senderAvatar.isNotEmpty) {
                    _partnerAvatarUrl = senderAvatar;
                  }
                  _isPaired = true;
                  _saveToStorage();
                  notifyListeners();
                } else if (senderAvatar.isNotEmpty && _partnerAvatarUrl != senderAvatar) {
                  _partnerAvatarUrl = senderAvatar;
                  _saveToStorage();
                  notifyListeners();
                }
                _sendPartnerAck();
              }
            },
          )
          .onBroadcast(
            event: 'partner_ping',
            callback: (payload) {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                final senderName = payload['sender_name'] as String? ?? 'Partner';
                final senderRole = payload['sender_role'] as String? ?? 'partner';
                final senderTracksCycle = payload['tracks_cycle'] as bool? ?? false;
                final senderAvatar = payload['sender_avatar_url'] as String? ?? '';
                if (_partnerId.isEmpty || _partnerName.isEmpty) {
                  _partnerId = senderId;
                  _partnerName = senderName;
                  _partnerRole = senderRole;
                  _partnerTracksCycle = senderTracksCycle;
                  if (senderAvatar.isNotEmpty) {
                    _partnerAvatarUrl = senderAvatar;
                  }
                  _isPaired = true;
                  _saveToStorage();
                  notifyListeners();
                } else if (senderAvatar.isNotEmpty && _partnerAvatarUrl != senderAvatar) {
                  _partnerAvatarUrl = senderAvatar;
                  _saveToStorage();
                  notifyListeners();
                }
                _sendPartnerAck();
              }
            },
          )
          .onBroadcast(
            event: 'partner_avatar_update',
            callback: (payload) {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                final senderAvatar = payload['sender_avatar_url'] as String? ?? '';
                if (senderAvatar.isNotEmpty && _partnerAvatarUrl != senderAvatar) {
                  _partnerAvatarUrl = senderAvatar;
                  _saveToStorage();
                  notifyListeners();
                }
              }
            },
          )
          .onBroadcast(
            event: 'partner_unlinked',
            callback: (payload) {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                _isPaired = false;
                _partnerId = '';
                _partnerName = '';
                _partnerRole = '';
                _partnerAvatarUrl = '';
                _partnerTracksCycle = false;
                _saveToStorage();
                NotificationService().showNotification(
                  id: 11,
                  title: 'Partner Unlinked',
                  body: 'Your partner has unlinked from the shared space.',
                );
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'cycle_updated',
            callback: (payload) {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                if (payload['start_date'] != null) {
                  _lastPeriodStartDate = DateTime.parse(payload['start_date'] as String);
                }
                _cycleLength = payload['cycle_length'] as int? ?? _cycleLength;
                _periodLength = payload['period_length'] as int? ?? _periodLength;
                final incomingBuffer = payload['buffer_days'] as int?;
                if (incomingBuffer != null) {
                  _safetyBufferDays = max(2, incomingBuffer);
                }
                _saveToStorage();
                scheduleCycleNotifications();
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'mood_signal',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              final dateKey = payload['date'] as String?;
              final inTheMood = payload['in_the_mood'] as bool? ?? false;

              if (dateKey != null && senderId != null && senderId != _currentUserId) {
                if (_partnerId.isEmpty) _partnerId = senderId;
                _moodSignals.putIfAbsent(dateKey, () => {});
                _moodSignals[dateKey]![senderId] = inTheMood;

                final userMood = _moodSignals[dateKey]![_currentUserId] ?? false;
                final isMatch = userMood && inTheMood;

                if (isMatch) {
                  final matchMem = CoupleMemory(
                    id: _uuid.v4(),
                    coupleId: _coupleId,
                    createdBy: senderId,
                    type: 'spark_match',
                    title: "Spark Ignited! 🔥",
                    description: "Mutual match! Both of you lit your sparks.",
                    windowKey: dateKey,
                    createdAt: DateTime.now(),
                  );
                  if (!_memories.any((m) => m.windowKey == dateKey && m.type == 'spark_match')) {
                    _memories.insert(0, matchMem);
                  }

                  NotificationService().showNotification(
                    id: 1,
                    title: "It's a Match! 🔥",
                    body: "Both of you are in the mood tonight! The spark is ignited.",
                    soundId: _sparkSoundId,
                  );
                }
                await _saveToStorage();
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'spark_turned_off',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              final dateKey = payload['date'] as String?;
              final senderName = payload['sender_name'] as String? ?? 'Your partner';

              if (dateKey != null && senderId != null && senderId != _currentUserId) {
                _moodSignals.putIfAbsent(dateKey, () => {});
                _moodSignals[dateKey]![senderId] = false;
                _moodSignals[dateKey]![_currentUserId] = false;

                final cancelMem = CoupleMemory(
                  id: _uuid.v4(),
                  coupleId: _coupleId,
                  createdBy: senderId,
                  type: 'spark_canceled',
                  title: 'Spark Canceled',
                  description: '$senderName canceled the spark.',
                  windowKey: dateKey,
                  createdAt: DateTime.now(),
                );
                _memories.removeWhere((m) => m.windowKey == dateKey && (m.type == 'spark_canceled' || m.type == 'spark_celebrated'));
                _memories.insert(0, cancelMem);

                NotificationService().showNotification(
                  id: 4,
                  title: 'Spark Canceled',
                  body: '$senderName canceled the spark.',
                  soundId: _cancelSoundId,
                );
                await _saveToStorage();
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'date_proposed',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                final dateJson = payload['data'] as Map<String, dynamic>;
                final newDate = ScheduledIntimacy.fromJson(dateJson);
                final now = DateTime.now();
                for (int i = 0; i < _scheduledDates.length; i++) {
                  final d = _scheduledDates[i];
                  if (!d.scheduledAt.toLocal().isBefore(now) &&
                      (d.status == IntimacyStatus.accepted || d.status == IntimacyStatus.pending)) {
                    _scheduledDates[i] = d.copyWith(status: IntimacyStatus.canceled);
                  }
                }
                _scheduledDates.removeWhere((e) => e.id == newDate.id);
                _scheduledDates.insert(0, newDate);
                await _saveToStorage();

                NotificationService().showNotification(
                  id: 2,
                  title: 'New Date Night Proposal 💕',
                  body: 'Your partner proposed an intimate rendezvous!',
                  soundId: _dateRequestSoundId,
                );
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'date_responded',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                final dateId = payload['id'] as String?;
                final statusStr = payload['status'] as String?;
                final dataJson = payload['data'] as Map<String, dynamic>?;
                final memoryJson = payload['memory'] as Map<String, dynamic>?;

                if (dateId != null) {
                  final index = _scheduledDates.indexWhere((e) => e.id == dateId);
                  if (dataJson != null) {
                    final updatedItem = ScheduledIntimacy.fromJson(dataJson);
                    if (index != -1) {
                      _scheduledDates[index] = updatedItem;
                    } else {
                      _scheduledDates.insert(0, updatedItem);
                    }
                  } else if (index != -1 && statusStr != null) {
                    final parsedStatus = IntimacyStatus.values.firstWhere(
                      (e) => e.name == statusStr,
                      orElse: () => IntimacyStatus.pending,
                    );
                    _scheduledDates[index] = _scheduledDates[index].copyWith(
                      status: parsedStatus,
                      counterScheduledAt: payload['counter_scheduled_at'] != null
                          ? DateTime.tryParse(payload['counter_scheduled_at'] as String)?.toLocal()
                          : null,
                      responseNote: payload['note'] as String?,
                    );
                  }
                }

                if (memoryJson != null) {
                  final partnerMem = CoupleMemory.fromJson(memoryJson);
                  _memories.removeWhere((m) => m.id == partnerMem.id || (m.type == 'date_night' && m.windowKey == partnerMem.windowKey));
                  _memories.insert(0, partnerMem);
                }

                await _saveToStorage();

                final senderName = payload['sender_name'] as String? ?? 'Your partner';
                final isAccepted = statusStr == 'accepted';
                NotificationService().showNotification(
                  id: 3,
                  title: isAccepted ? 'Date Night Accepted! ✨' : 'Date Night Update ✨',
                  body: isAccepted
                      ? '$senderName accepted your date proposal!'
                      : '$senderName responded: $statusStr',
                  soundId: isAccepted ? 'heartbeat_pulse' : null,
                );

                if (isAccepted && dateId != null) {
                  final targetDate = _scheduledDates.firstWhere(
                    (e) => e.id == dateId,
                    orElse: () => _scheduledDates.isNotEmpty
                        ? _scheduledDates.first
                        : ScheduledIntimacy(
                            id: dateId,
                            coupleId: _coupleId,
                            proposedBy: senderId,
                            scheduledAt: DateTime.now(),
                            status: IntimacyStatus.accepted,
                            createdAt: DateTime.now(),
                          ),
                  );
                  _scheduleNudgesForDate(targetDate);
                } else if (!isAccepted && dateId != null) {
                  _cancelNudgesForDate(dateId);
                }

                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'date_canceled',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              final dateId = payload['id'] as String?;
              final canceledIdsList = (payload['canceled_ids'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? <String>{};
              if (dateId != null) canceledIdsList.add(dateId);
              final senderName = payload['sender_name'] as String? ?? 'Your partner';
              final formattedDate = payload['formatted_date'] as String? ?? 'the upcoming date';

              if (senderId != null && senderId != _currentUserId) {
                for (final cid in canceledIdsList) {
                  _cancelNudgesForDate(cid);
                }
                final now = DateTime.now();
                String? windowKey;

                for (int i = 0; i < _scheduledDates.length; i++) {
                  final d = _scheduledDates[i];
                  if (canceledIdsList.contains(d.id) ||
                      (!d.scheduledAt.toLocal().isBefore(now) &&
                          (d.status == IntimacyStatus.accepted || d.status == IntimacyStatus.pending))) {
                    windowKey ??= DateFormat('EEE, MMM d').format(d.scheduledAt.toLocal());
                    _scheduledDates[i] = d.copyWith(status: IntimacyStatus.canceled);
                  }
                }

                final cancelMem = CoupleMemory(
                  id: _uuid.v4(),
                  coupleId: _coupleId,
                  createdBy: senderId,
                  type: 'date_canceled',
                  title: 'Date Canceled',
                  description: '$senderName canceled the date scheduled for $formattedDate.',
                  windowKey: windowKey,
                  createdAt: DateTime.now().toLocal(),
                );

                if (windowKey != null) {
                  _memories.removeWhere((m) => m.type == 'date_night' && m.windowKey == windowKey);
                  _memories.removeWhere((m) => m.type == 'date_canceled' && m.windowKey == windowKey);
                }
                _memories.insert(0, cancelMem);

                NotificationService().showNotification(
                  id: 21,
                  title: 'Date Canceled',
                  body: '$senderName canceled the date scheduled for $formattedDate.',
                  soundId: _cancelSoundId,
                );

                await _saveToStorage();
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'memories_cleared',
            callback: (payload) {
              _memories.clear();
              _readMemoryIds.clear();
              _lastViewedMemoriesAt = null;
              _saveToStorage();
              notifyListeners();
            },
          )
          .onBroadcast(
            event: 'chat_message',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                final msgJson = payload['data'] as Map<String, dynamic>;
                final newMsg = ChatMessage.fromJson(msgJson);
                _chatMessages.removeWhere((m) => m.id == newMsg.id);
                _chatMessages.add(newMsg);
                if (_chatMessages.length > 500) {
                  _chatMessages.removeRange(0, _chatMessages.length - 500);
                }
                await _saveToStorage();
                NotificationService().showNotification(
                  id: 30,
                  title: newMsg.isViewOnce
                      ? 'View-Once Photo 📸'
                      : (_partnerName.isNotEmpty ? _partnerName : 'Your partner'),
                  body: newMsg.isViewOnce ? 'Sent you a private view-once photo' : newMsg.text,
                  soundId: _sparkSoundId,
                );
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'chat_reaction',
            callback: (payload) async {
              final msgId = payload['message_id'] as String?;
              final senderId = payload['sender_id'] as String?;
              final emoji = payload['emoji'] as String?;
              if (msgId != null && senderId != null) {
                final idx = _chatMessages.indexWhere((m) => m.id == msgId);
                if (idx != -1) {
                  final existing = _chatMessages[idx];
                  final newReactions = Map<String, String>.from(existing.reactions);
                  if (emoji == null || emoji.isEmpty) {
                    newReactions.remove(senderId);
                  } else {
                    newReactions[senderId] = emoji;
                  }
                  _chatMessages[idx] = existing.copyWith(reactions: newReactions);
                  await _saveToStorage();
                  notifyListeners();
                }
              }
            },
          )
          .onBroadcast(
            event: 'chat_read',
            callback: (payload) async {
              final senderId = payload['sender_id'] as String?;
              if (senderId != null && senderId != _currentUserId) {
                final readTimeStr = payload['read_at'] as String?;
                final readTime = readTimeStr != null ? DateTime.parse(readTimeStr) : DateTime.now();
                bool changed = false;
                for (int i = 0; i < _chatMessages.length; i++) {
                  final m = _chatMessages[i];
                  if (m.senderId == _currentUserId && m.readAt == null) {
                    _chatMessages[i] = m.copyWith(readAt: readTime);
                    changed = true;
                  }
                }
                if (changed) {
                  await _saveToStorage();
                  notifyListeners();
                }
              }
            },
          )
          .onBroadcast(
            event: 'chat_photo_viewed',
            callback: (payload) async {
              final msgId = payload['message_id'] as String?;
              if (msgId != null) {
                final idx = _chatMessages.indexWhere((m) => m.id == msgId);
                if (idx != -1) {
                  _chatMessages[idx] = _chatMessages[idx].copyWith(isViewed: true, imageUrl: null);
                  await _saveToStorage();
                  notifyListeners();
                }
              }
            },
          )
          .onBroadcast(
            event: 'chat_cleared',
            callback: (payload) async {
              _chatMessages.clear();
              await _saveToStorage();
              notifyListeners();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime setup notice: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_kPrefKey);
      if (dataStr != null) {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        _hasCompletedOnboarding = data['hasCompletedOnboarding'] ?? false;
        _hasCreatedProfile = data['hasConfirmedProfileStep'] ?? false;
        _privacyPin = data['privacyPin'] ?? '';
        _recoveryEmail = data['recoveryEmail'] ?? '';
        _userEmail = data['userEmail'] ?? _userEmail;
        _userAvatarUrl = data['userAvatarUrl'] ?? _userAvatarUrl;
        _currentUserId = data['currentUserId'] ?? _currentUserId;
        _currentUserName = data['currentUserName'] ?? _currentUserName;
        _currentUserRole = data['currentUserRole'] ?? _currentUserRole;
        _tracksCycle = data['tracksCycle'] ?? true;
        _partnerId = data['partnerId'] ?? _partnerId;
        _partnerName = data['partnerName'] ?? _partnerName;
        _partnerRole = data['partnerRole'] ?? _partnerRole;
        _partnerAvatarUrl = data['partnerAvatarUrl'] ?? _partnerAvatarUrl;
        _partnerTracksCycle = data['partnerTracksCycle'] ?? false;
        _isPaired = data['isPaired'] ?? _isPaired;
        _inviteCode = data['inviteCode'] ?? _inviteCode;
        _coupleId = data['coupleId'] ?? _coupleId;
        if (data['lastPeriodStartDate'] != null) {
          _lastPeriodStartDate = DateTime.parse(data['lastPeriodStartDate']);
        }
        _cycleLength = data['cycleLength'] ?? _cycleLength;
        _periodLength = data['periodLength'] ?? _periodLength;
        final storedBuffer = data['safetyBufferDays'] as int?;
        _safetyBufferDays = storedBuffer != null ? max(2, storedBuffer) : _safetyBufferDays;

        if (data['moodSignals'] != null) {
          final rawMoods = data['moodSignals'] as Map<String, dynamic>;
          rawMoods.forEach((k, v) {
            _moodSignals[k] = Map<String, bool>.from(v as Map);
          });
        }

        if (data['scheduledDates'] != null) {
          final rawDates = data['scheduledDates'] as List<dynamic>;
          _scheduledDates.clear();
          for (final item in rawDates) {
            _scheduledDates.add(ScheduledIntimacy.fromJson(item as Map<String, dynamic>));
          }
        }

        if (data['memories'] != null) {
          final rawMemories = data['memories'] as List<dynamic>;
          _memories.clear();
          for (final item in rawMemories) {
            _memories.add(CoupleMemory.fromJson(item as Map<String, dynamic>));
          }
        }

        if (data['chatMessages'] != null) {
          final rawChat = data['chatMessages'] as List<dynamic>;
          _chatMessages.clear();
          for (final item in rawChat) {
            _chatMessages.add(ChatMessage.fromJson(item as Map<String, dynamic>));
          }
        }

        if (data['readMemoryIds'] != null) {
          final rawIds = data['readMemoryIds'] as List<dynamic>;
          _readMemoryIds.clear();
          for (final id in rawIds) {
            _readMemoryIds.add(id.toString());
          }
        }
        if (data['lastViewedMemoriesAt'] != null) {
          _lastViewedMemoriesAt = DateTime.tryParse(data['lastViewedMemoriesAt'] as String);
        }
        if (data['firedNudgeKeys'] != null) {
          final rawFired = data['firedNudgeKeys'] as List<dynamic>;
          _firedNudgeKeys.clear();
          for (final k in rawFired) {
            _firedNudgeKeys.add(k.toString());
          }
        }
        final loadedSound = data['sparkSoundId'] as String?;
        if (loadedSound == null || loadedSound == 'velvet_rhodes' || loadedSound == 'romantic_harp') {
          _sparkSoundId = 'heartbeat_pulse';
        } else {
          _sparkSoundId = loadedSound;
        }
        _cancelSoundId = data['cancelSoundId'] ?? 'sunset_marimba';
        _dateRequestSoundId = data['dateRequestSoundId'] ?? 'moonlight_vibe';
        _rescheduleAllUpcomingNudges();
        scheduleCycleNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'hasCompletedOnboarding': _hasCompletedOnboarding,
        'hasCreatedProfile': _hasCreatedProfile,
        'hasConfirmedProfileStep': _hasCreatedProfile,
        'privacyPin': _privacyPin,
        'recoveryEmail': _recoveryEmail,
        'userEmail': _userEmail,
        'userAvatarUrl': _userAvatarUrl,
        'sparkSoundId': _sparkSoundId,
        'currentUserId': _currentUserId,
        'currentUserName': _currentUserName,
        'currentUserRole': _currentUserRole,
        'tracksCycle': _tracksCycle,
        'partnerId': _partnerId,
        'partnerName': _partnerName,
        'partnerRole': _partnerRole,
        'partnerAvatarUrl': _partnerAvatarUrl,
        'partnerTracksCycle': _partnerTracksCycle,
        'isPaired': _isPaired,
        'inviteCode': _inviteCode,
        'coupleId': _coupleId,
        'lastPeriodStartDate': _lastPeriodStartDate?.toIso8601String(),
        'cycleLength': _cycleLength,
        'periodLength': _periodLength,
        'safetyBufferDays': _safetyBufferDays,
        'moodSignals': _moodSignals,
        'scheduledDates': _scheduledDates.map((e) => e.toJson()).toList(),
        'memories': _memories.map((e) => e.toJson()).toList(),
        'chatMessages': _chatMessages.map((e) => e.toStorageJson()).toList(),
        'readMemoryIds': _readMemoryIds.toList(),
        'lastViewedMemoriesAt': _lastViewedMemoriesAt?.toIso8601String(),
        'firedNudgeKeys': _firedNudgeKeys.toList(),
        'cancelSoundId': _cancelSoundId,
        'dateRequestSoundId': _dateRequestSoundId,
      };
      await prefs.setString(_kPrefKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving state: $e');
    }
  }

  // Double-Blind Mood Matching Query
  MoodStatus getDailyMoodStatus([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    final key = _dateKey(targetDate);
    final daySignals = _moodSignals[key] ?? {};

    final userMood = daySignals[_currentUserId] ?? false;
    final partnerMood = daySignals[_partnerId] ?? false;

    // ZERO-KNOWLEDGE PRINCIPLE:
    // Match is only true if BOTH are in the mood.
    final isMatch = userMood && partnerMood;

    return MoodStatus(
      userInTheMood: userMood,
      isMatch: isMatch,
      signalDate: targetDate.subtract(const Duration(hours: 4)),
      hasCouple: _isPaired,
      coupleId: _coupleId,
    );
  }

  Future<MoodStatus> toggleMoodSignal([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final key = _dateKey(targetDate);
    _moodSignals.putIfAbsent(key, () => {});

    final current = _moodSignals[key]![_currentUserId] ?? false;
    final newMood = !current;
    _moodSignals[key]![_currentUserId] = newMood;

    final partnerMood = _moodSignals[key]![_partnerId] ?? false;
    final isMatch = newMood && partnerMood;

    await _saveToStorage();

    // Broadcast event across Supabase Realtime channel
    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'mood_signal',
          payload: {
            'sender_id': _currentUserId,
            'date': key,
            'in_the_mood': newMood,
            'is_match': isMatch,
          },
        );
      } catch (e) {
        debugPrint('Broadcast error: $e');
      }
    }

    if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
      try {
        final res = await Supabase.instance.client.rpc('toggle_mood_window', params: {
          'p_window': key,
          'p_in_the_mood': newMood,
        });
        if (res != null && res is Map) {
          final serverMatch = res['is_match'] == true;
          if (serverMatch && !isMatch) {
            _moodSignals[key]![_partnerId] = true;
            final matchMem = CoupleMemory(
              id: _uuid.v4(),
              coupleId: _coupleId,
              createdBy: _currentUserId,
              type: 'spark_match',
              title: "Spark Ignited! 🔥",
              description: "Mutual match! Both of you lit your sparks.",
              windowKey: key,
              createdAt: DateTime.now(),
            );
            if (!_memories.any((m) => m.windowKey == key && m.type == 'spark_match')) {
              _memories.insert(0, matchMem);
            }
            await _saveToStorage();
            NotificationService().showNotification(
              id: 1,
              title: "It's a Match! 🔥",
              body: "Both of you are in the mood tonight! The spark is ignited.",
              soundId: _sparkSoundId,
            );
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Persist mood notice: $e');
      }
    }

    if (isMatch) {
      final matchMem = CoupleMemory(
        id: _uuid.v4(),
        coupleId: _coupleId,
        createdBy: _currentUserId,
        type: 'spark_match',
        title: "Spark Ignited! 🔥",
        description: "Mutual match! Both of you lit your sparks.",
        windowKey: key,
        createdAt: DateTime.now(),
      );
      if (!_memories.any((m) => m.windowKey == key && m.type == 'spark_match')) {
        _memories.insert(0, matchMem);
      }
      NotificationService().showNotification(
        id: 1,
        title: "It's a Match! 🔥",
        body: "Both of you are in the mood tonight! The spark is ignited.",
        soundId: _sparkSoundId,
      );
    }

    notifyListeners();
    return getDailyMoodStatus(targetDate);
  }

  Future<MoodStatus> turnOffSparkMatch([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final key = _dateKey(targetDate);
    _moodSignals.putIfAbsent(key, () => {});

    // Reset mood for both partners (Cancel for both)
    _moodSignals[key]![_currentUserId] = false;
    if (_partnerId.isNotEmpty) {
      _moodSignals[key]![_partnerId] = false;
    }

    final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'Your partner';
    final cancelMem = CoupleMemory(
      id: _uuid.v4(),
      coupleId: _coupleId,
      createdBy: _currentUserId,
      type: 'spark_canceled',
      title: 'Spark Canceled',
      description: 'You canceled the spark with $partnerDisplay.',
      windowKey: key,
      createdAt: DateTime.now(),
    );
    _memories.removeWhere((m) => m.windowKey == key && (m.type == 'spark_canceled' || m.type == 'spark_celebrated'));
    _memories.insert(0, cancelMem);

    await _saveToStorage();

    // Broadcast spark_turned_off across Supabase Realtime channel
    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'spark_turned_off',
          payload: {
            'sender_id': _currentUserId,
            'sender_name': _currentUserName,
            'date': key,
            'memory': cancelMem.toJson(),
            'action': 'canceled',
          },
        );
      } catch (e) {
        debugPrint('Broadcast error: $e');
      }
    }

    if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
      try {
        await Supabase.instance.client.rpc('turn_off_spark_match', params: {
          'p_window': key,
        });
      } catch (e) {
        debugPrint('Persist turn off spark notice: $e');
      }
      try {
        if (_coupleId.isNotEmpty) {
          await Supabase.instance.client.from('couple_memories').upsert({
            'id': cancelMem.id,
            'couple_id': _coupleId,
            'created_by': _currentUserId,
            'type': cancelMem.type,
            'title': cancelMem.title,
            'description': cancelMem.description,
            'window_key': cancelMem.windowKey,
            'created_at': cancelMem.createdAt.toUtc().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Persist cancel memory error: $e');
      }
    }

    NotificationService().showNotification(
      id: 4,
      title: 'Spark Canceled',
      body: 'You canceled the spark with $partnerDisplay.',
      soundId: _cancelSoundId,
    );

    notifyListeners();
    return getDailyMoodStatus(targetDate);
  }

  // Switch Active Partner View (Used in unit tests to simulate partner perspective)
  void switchPartnerView() {
    if (_partnerId.isEmpty) {
      _partnerId = 'partner_sim_${DateTime.now().millisecondsSinceEpoch}';
    }
    final tempId = _currentUserId;
    final tempName = _currentUserName;
    final tempTracks = _tracksCycle;
    final tempRole = _currentUserRole;

    _currentUserId = _partnerId;
    _currentUserName = _partnerName.isNotEmpty ? _partnerName : 'Partner';
    _tracksCycle = _partnerTracksCycle;
    _currentUserRole = _partnerRole.isNotEmpty ? _partnerRole : 'Partner';

    _partnerId = tempId;
    _partnerName = tempName;
    _partnerTracksCycle = tempTracks;
    _partnerRole = tempRole;

    _saveToStorage();
    scheduleCycleNotifications();
    notifyListeners();
  }

  // Update Cycle Settings & Period Log
  Future<void> updatePeriodLog({
    required DateTime startDate,
    int? cycleLength,
    int? periodLength,
    int? bufferDays,
  }) async {
    _lastPeriodStartDate = startDate;
    if (cycleLength != null) _cycleLength = cycleLength;
    if (periodLength != null) _periodLength = periodLength;
    if (bufferDays != null) _safetyBufferDays = max(2, bufferDays);
    await _saveToStorage();
    await scheduleCycleNotifications();

    // Broadcast cycle update to partner's phone in real time
    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'cycle_updated',
          payload: {
            'sender_id': _currentUserId,
            'start_date': _lastPeriodStartDate?.toIso8601String(),
            'cycle_length': _cycleLength,
            'period_length': _periodLength,
            'buffer_days': _safetyBufferDays,
          },
        );
      } catch (e) {
        debugPrint('Broadcast cycle error: $e');
      }
    }

    notifyListeners();
  }

  // Pair with an Invite Code
  Future<bool> pairWithCode(String code) async {
    final normalized = normalizeInviteCode(code);
    if (normalized == _inviteCode.toUpperCase()) {
      return false; // Can't pair with own code
    }
    _isPaired = true;
    _inviteCode = normalized;
    if (_partnerId.isEmpty) {
      _partnerId = 'partner_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
      try {
        final client = Supabase.instance.client;
        final res = await client.rpc('pair_couple', params: {'p_invite_code': normalized});
        if (res != null && res['couple_id'] != null) {
          _coupleId = res['couple_id'] as String;
          final couple = await client.from('couples').select().eq('id', _coupleId).single();
          final partnerUid = couple['created_by'] as String;
          _partnerId = partnerUid;
          final pProfile = await client.from('profiles').select().eq('id', partnerUid).maybeSingle();
          if (pProfile != null) {
            _partnerName = pProfile['display_name'] ?? _partnerName;
            _partnerRole = pProfile['role'] ?? _partnerRole;
            _partnerAvatarUrl = pProfile['avatar_url'] as String? ?? _partnerAvatarUrl;
          }
        }
      } catch (e) {
        debugPrint('Supabase pair_couple notice: $e');
      }
    }

    await _saveToStorage();
    _subscribeToChannel();
    _broadcastPartnerJoinWithRetry();
    notifyListeners();
    return true;
  }

  // Disconnect / Unlink Current Partner
  Future<void> disconnectPartner() async {
    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'partner_unlinked',
          payload: {
            'sender_id': _currentUserId,
          },
        );
      } catch (e) {
        debugPrint('Error broadcasting unlink: $e');
      }
    }
    _isPaired = false;
    _partnerId = '';
    _partnerName = '';
    _partnerRole = '';
    _partnerAvatarUrl = '';
    _partnerTracksCycle = false;
    _scheduledDates.clear();
    _chatMessages.clear();
    await _saveToStorage();
    notifyListeners();
  }

  // Generate New Invite Code
  void regenerateInviteCode() {
    _inviteCode = generateUniqueInviteCode();
    _saveToStorage();
    _subscribeToChannel();
    notifyListeners();
  }

  // Scheduling Methods
  Future<void> proposeDate(DateTime dateTime) async {
    final now = DateTime.now();
    for (int i = 0; i < _scheduledDates.length; i++) {
      final d = _scheduledDates[i];
      if (!d.scheduledAt.toLocal().isBefore(now) &&
          (d.status == IntimacyStatus.accepted || d.status == IntimacyStatus.pending)) {
        _scheduledDates[i] = d.copyWith(status: IntimacyStatus.canceled);
        if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
          try {
            await Supabase.instance.client.from('scheduled_intimacy').update({
              'status': IntimacyStatus.canceled.name,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            }).eq('id', d.id);
          } catch (e) {
            debugPrint('Notice canceling previous date: $e');
          }
        }
      }
    }

    final item = ScheduledIntimacy(
      id: _uuid.v4(),
      coupleId: _coupleId,
      proposedBy: _currentUserId,
      scheduledAt: dateTime,
      status: IntimacyStatus.pending,
      createdAt: DateTime.now(),
    );
    _scheduledDates.insert(0, item);
    await _saveToStorage();

    if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null && _coupleId.isNotEmpty) {
      try {
        await Supabase.instance.client.from('scheduled_intimacy').upsert({
          'id': item.id,
          'couple_id': _coupleId,
          'proposed_by': _currentUserId,
          'scheduled_at': item.scheduledAt.toUtc().toIso8601String(),
          'status': item.status.name,
          'created_at': item.createdAt.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Persist scheduled date notice: $e');
      }
    }

    // Broadcast proposal to partner
    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'date_proposed',
          payload: {
            'sender_id': _currentUserId,
            'sender_name': _currentUserName,
            'data': item.toJson(),
          },
        );
      } catch (e) {
        debugPrint('Broadcast error: $e');
      }
    }

    notifyListeners();
  }

  Future<void> proposeReschedule(String id, DateTime newDateTime) async {
    final index = _scheduledDates.indexWhere((e) => e.id == id);
    if (index != -1) {
      final existing = _scheduledDates[index];
      final updated = existing.copyWith(
        scheduledAt: newDateTime,
        proposedBy: _currentUserId,
        status: IntimacyStatus.pending,
        vibeCheckStatus: VibeCheckStatus.pending,
      );
      _scheduledDates[index] = updated;
      await _saveToStorage();

      if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
        try {
          await Supabase.instance.client.from('scheduled_intimacy').upsert({
            'id': updated.id,
            'couple_id': updated.coupleId.isNotEmpty ? updated.coupleId : _coupleId,
            'proposed_by': _currentUserId,
            'scheduled_at': updated.scheduledAt.toUtc().toIso8601String(),
            'status': IntimacyStatus.pending.name,
            'vibe_check_status': VibeCheckStatus.pending.name,
            'created_at': updated.createdAt.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Persist reschedule notice: $e');
        }
      }

      if (_realtimeChannel != null) {
        try {
          await _realtimeChannel!.sendBroadcastMessage(
            event: 'date_proposed',
            payload: {
              'sender_id': _currentUserId,
              'sender_name': _currentUserName,
              'data': updated.toJson(),
              'is_reschedule': true,
            },
          );
        } catch (e) {
          debugPrint('Broadcast reschedule error: $e');
        }
      }

      notifyListeners();
    }
  }

  Future<void> cancelScheduledDate(String id) async {
    final now = DateTime.now();
    final targetIndex = _scheduledDates.indexWhere((e) => e.id == id);
    final targetDate = targetIndex != -1 ? _scheduledDates[targetIndex] : null;

    final canceledIds = <String>{};
    if (id.isNotEmpty) {
      canceledIds.add(id);
    }

    // Cancel the specified date and all active upcoming dates (accepted or pending)
    for (int i = 0; i < _scheduledDates.length; i++) {
      final d = _scheduledDates[i];
      if (d.id == id ||
          (!d.scheduledAt.toLocal().isBefore(now) &&
              (d.status == IntimacyStatus.accepted || d.status == IntimacyStatus.pending))) {
        _scheduledDates[i] = d.copyWith(status: IntimacyStatus.canceled);
        canceledIds.add(d.id);
      }
    }

    for (final cid in canceledIds) {
      _cancelNudgesForDate(cid);
    }

    final localScheduled = (targetDate ??
            _scheduledDates.firstWhere(
              (e) => canceledIds.contains(e.id),
              orElse: () => ScheduledIntimacy(
                id: id,
                coupleId: _coupleId,
                proposedBy: _currentUserId,
                scheduledAt: DateTime.now(),
                status: IntimacyStatus.canceled,
                createdAt: DateTime.now(),
              ),
            ))
        .scheduledAt
        .toLocal();

    final formattedDate = DateFormat('EEEE, MMM d @ h:mm a').format(localScheduled);
    final windowKey = DateFormat('EEE, MMM d').format(localScheduled);
    final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'your partner';

    final cancelMem = CoupleMemory(
      id: _uuid.v4(),
      coupleId: _coupleId,
      createdBy: _currentUserId,
      type: 'date_canceled',
      title: 'Date Canceled',
      description: 'You canceled the date with $partnerDisplay scheduled for $formattedDate.',
      windowKey: windowKey,
      createdAt: DateTime.now().toLocal(),
    );

    _memories.removeWhere((m) => m.type == 'date_night' && m.windowKey == windowKey);
    _memories.removeWhere((m) => m.type == 'date_canceled' && m.windowKey == windowKey);
    _memories.insert(0, cancelMem);

    await _saveToStorage();

    if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
      for (final cid in canceledIds) {
        try {
          await Supabase.instance.client.from('scheduled_intimacy').update({
            'status': IntimacyStatus.canceled.name,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', cid);
        } catch (e) {
          debugPrint('Cancel date Supabase notice: $e');
        }
      }

      try {
        if (_coupleId.isNotEmpty) {
          await Supabase.instance.client.from('couple_memories').upsert({
            'id': cancelMem.id,
            'couple_id': _coupleId,
            'created_by': _currentUserId,
            'type': cancelMem.type,
            'title': cancelMem.title,
            'description': cancelMem.description,
            'window_key': cancelMem.windowKey,
            'created_at': cancelMem.createdAt.toUtc().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Persist cancel date memory notice: $e');
      }
    }

    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'date_canceled',
          payload: {
            'sender_id': _currentUserId,
            'sender_name': _currentUserName,
            'id': id,
            'canceled_ids': canceledIds.toList(),
            'memory': cancelMem.toJson(),
            'formatted_date': formattedDate,
          },
        );
      } catch (e) {
        debugPrint('Broadcast cancel date error: $e');
      }
    }

    NotificationService().showNotification(
      id: 21,
      title: 'Date Canceled',
      body: 'You canceled the date with $partnerDisplay scheduled for $formattedDate.',
      soundId: _cancelSoundId,
    );

    notifyListeners();
  }

  Future<void> cancelPendingProposal(String id) async {
    await cancelScheduledDate(id);
  }

  Future<void> respondToDate(String id, IntimacyStatus newStatus, {DateTime? counterTime, String? note}) async {
    final index = _scheduledDates.indexWhere((e) => e.id == id);
    if (index != -1) {
      final existing = _scheduledDates[index];
      final updated = existing.copyWith(
        status: newStatus,
        counterScheduledAt: counterTime,
        responseNote: note,
      );
      _scheduledDates[index] = updated;

      CoupleMemory? dateMem;
      if (newStatus == IntimacyStatus.accepted) {
        final localScheduled = updated.scheduledAt.toLocal();
        final formattedDate = DateFormat('EEEE, MMM d @ h:mm a').format(localScheduled);
        final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'Your partner';
        final windowKey = DateFormat('EEE, MMM d').format(localScheduled);
        dateMem = CoupleMemory(
          id: _uuid.v4(),
          coupleId: _coupleId,
          createdBy: _currentUserId,
          type: 'date_night',
          title: 'Date Night Confirmed! ✨',
          description: 'Date scheduled with $partnerDisplay for $formattedDate.',
          windowKey: windowKey,
          createdAt: DateTime.now().toLocal(),
        );
        _memories.removeWhere((m) => m.type == 'date_night' && m.windowKey == windowKey);
        _memories.insert(0, dateMem);
        _scheduleNudgesForDate(updated);
      } else {
        _cancelNudgesForDate(updated.id);
      }

      await _saveToStorage();

      if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
        try {
          final client = Supabase.instance.client;
          await client.from('scheduled_intimacy').upsert({
            'id': updated.id,
            'couple_id': updated.coupleId.isNotEmpty ? updated.coupleId : _coupleId,
            'proposed_by': updated.proposedBy.isNotEmpty ? updated.proposedBy : _currentUserId,
            'scheduled_at': updated.scheduledAt.toUtc().toIso8601String(),
            'status': updated.status.name,
            'counter_scheduled_at': updated.counterScheduledAt?.toUtc().toIso8601String(),
            'response_note': updated.responseNote,
            'vibe_check_status': updated.vibeCheckStatus.name,
            'created_at': updated.createdAt.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });

          if (dateMem != null && _coupleId.isNotEmpty) {
            await client.from('couple_memories').upsert({
              'id': dateMem.id,
              'couple_id': _coupleId,
              'created_by': _currentUserId,
              'type': dateMem.type,
              'title': dateMem.title,
              'description': dateMem.description,
              'window_key': dateMem.windowKey,
              'created_at': dateMem.createdAt.toUtc().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Persist date response notice: $e');
        }
      }

      if (_realtimeChannel != null) {
        try {
          await _realtimeChannel!.sendBroadcastMessage(
            event: 'date_responded',
            payload: {
              'sender_id': _currentUserId,
              'sender_name': _currentUserName,
              'id': id,
              'status': newStatus.name,
              'counter_scheduled_at': counterTime?.toUtc().toIso8601String(),
              'note': note,
              'data': updated.toJson(),
              if (dateMem != null) 'memory': dateMem.toJson(),
            },
          );
        } catch (e) {
          debugPrint('Broadcast error: $e');
        }
      }

      notifyListeners();
    }
  }

  Future<void> respondVibeCheck(String id, VibeCheckStatus status) async {
    final index = _scheduledDates.indexWhere((e) => e.id == id);
    if (index != -1) {
      final existing = _scheduledDates[index];
      _scheduledDates[index] = existing.copyWith(
        vibeCheckStatus: status,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> setupNewUser({
    required String displayName,
    bool tracksCycle = true,
    String? role,
  }) async {
    await createPersonalProfile(
      displayName: displayName,
      tracksCycle: tracksCycle,
      role: role,
    );
    _hasCompletedOnboarding = true;
    await _saveToStorage();
    notifyListeners();
  }

  // Step 1: Create Personal Profile
  Future<void> createPersonalProfile({
    required String displayName,
    required bool tracksCycle,
    String? pin,
    String? email,
    String? role,
  }) async {
    if (_currentUserId.isEmpty) {
      _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    _currentUserName = displayName.trim();
    _tracksCycle = tracksCycle;
    _currentUserRole = role ?? (tracksCycle ? 'Cycle Tracker' : 'Partner');
    _partnerTracksCycle = !tracksCycle;
    if (pin != null && pin.trim().isNotEmpty) {
      _privacyPin = pin.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      _recoveryEmail = email.trim();
    }
    if (_inviteCode.isEmpty) {
      _inviteCode = generateUniqueInviteCode();
    }

    if (SupabaseConfig.isInitialized) {
      try {
        final client = Supabase.instance.client;
        final authUser = client.auth.currentUser;
        if (authUser != null) {
          _currentUserId = authUser.id;
          await client.from('profiles').upsert({
            'id': authUser.id,
            'display_name': _currentUserName,
            'role': _currentUserRole,
            if (userAvatarUrl.isNotEmpty) 'avatar_url': userAvatarUrl,
            if (_coupleId.isNotEmpty) 'couple_id': _coupleId,
          });
          if (_coupleId.isEmpty && _inviteCode.isNotEmpty) {
            Map<String, dynamic>? cRes;
            int attempts = 0;
            while (cRes == null && attempts < 4) {
              attempts++;
              try {
                cRes = await client.from('couples').insert({
                  'invite_code': _inviteCode,
                  'created_by': authUser.id,
                  'default_cycle_length': _cycleLength,
                  'default_period_length': _periodLength,
                  'safety_buffer_days': _safetyBufferDays,
                }).select().single();
              } catch (e) {
                debugPrint('Insert couple attempt $attempts notice: $e');
                if (attempts < 4) {
                  _inviteCode = generateUniqueInviteCode();
                } else {
                  rethrow;
                }
              }
            }
            if (cRes != null) {
              _coupleId = cRes['id'];
              await client.from('profiles').update({'couple_id': _coupleId}).eq('id', authUser.id);
            }
          }
        }
      } catch (e) {
        debugPrint('Supabase profile sync notice: $e');
      }
    }

    _hasCreatedProfile = true;
    _hasCompletedOnboarding = true;
    await _saveToStorage();
    scheduleCycleNotifications();
    _subscribeToChannel();
    notifyListeners();
  }

  // Complete Step 2 Solo
  Future<void> completeOnboardingSolo() async {
    _hasCompletedOnboarding = true;
    await _saveToStorage();
    notifyListeners();
  }

  // Return to Step 1 (Edit Name & Gender/Cycle Role)
  Future<void> returnToProfileSetup() async {
    _hasCreatedProfile = false;
    _hasCompletedOnboarding = false;
    await _saveToStorage();
    notifyListeners();
  }

  Future<bool> joinCoupleWithCode({
    required String code,
    String? displayName,
    bool? tracksCycle,
    String? role,
  }) async {
    final normalized = normalizeInviteCode(code);
    if (_currentUserId.isEmpty) {
      _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (displayName != null && displayName.isNotEmpty) {
      _currentUserName = displayName.trim();
    }
    if (tracksCycle != null) {
      _tracksCycle = tracksCycle;
      _partnerTracksCycle = !tracksCycle;
    }
    if (role != null) {
      _currentUserRole = role;
    }
    _partnerId = '';
    _partnerName = '';
    _partnerRole = '';
    _inviteCode = normalized;
    _isPaired = true;
    _hasCreatedProfile = true;
    _hasCompletedOnboarding = true;
    await _saveToStorage();
    _subscribeToChannel();

    _broadcastPartnerJoinWithRetry();

    notifyListeners();
    return true;
  }

  Future<void> signInWithGoogle() async {
    if (!SupabaseConfig.isInitialized) {
      throw Exception('Supabase is not configured.');
    }
    final client = Supabase.instance.client;
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.lovesync://login-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,
    );
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isInitialized) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Sign out notice: $e');
      }
    }
    _userEmail = '';
    _userAvatarUrl = '';
    _currentUserName = '';
    _hasCompletedOnboarding = false;
    _hasCreatedProfile = false;
    _isPaired = false;
    _partnerId = '';
    _partnerName = '';
    _partnerRole = '';
    _partnerAvatarUrl = '';
    _inviteCode = '';
    _moodSignals.clear();
    _scheduledDates.clear();
    _memories.clear();
    _readMemoryIds.clear();
    _lastViewedMemoriesAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefKey);
    notifyListeners();
  }

  Future<bool> syncWithSupabaseUser(User user) async {
    try {
      if (!SupabaseConfig.isInitialized) return false;
      final client = Supabase.instance.client;
      final uid = user.id;
      _currentUserId = uid;
      _userEmail = user.email ?? '';
      final av = _extractAvatarUrl(user);
      if (av.isNotEmpty) _userAvatarUrl = av;
      if (_currentUserName.isEmpty) {
        _currentUserName = _extractDisplayName(user);
      }
      notifyListeners();

      // 1. Fetch user's profile from Supabase
      final profileRes = await client.from('profiles').select().eq('id', uid).maybeSingle();

      if (profileRes != null) {
        if (_userAvatarUrl.isEmpty && profileRes['avatar_url'] != null) {
          _userAvatarUrl = profileRes['avatar_url'] as String;
        } else if (_userAvatarUrl.isNotEmpty && profileRes['avatar_url'] != _userAvatarUrl) {
          try {
            await client.from('profiles').update({'avatar_url': _userAvatarUrl}).eq('id', uid);
          } catch (_) {}
        }
      }

      if (profileRes != null && profileRes['couple_id'] != null) {
        _currentUserName = profileRes['display_name'] ?? _currentUserName;
        _currentUserRole = profileRes['role'] ?? _currentUserRole;
        if (_currentUserRole == 'Cycle Tracker' || _currentUserRole == 'Partner') {
          _tracksCycle = _currentUserRole == 'Cycle Tracker';
          _partnerTracksCycle = !_tracksCycle;
        }
        _coupleId = profileRes['couple_id'] as String;

        // Fetch couple record
        final coupleRes = await client.from('couples').select().eq('id', _coupleId).maybeSingle();
        if (coupleRes != null) {
          _inviteCode = coupleRes['invite_code'] ?? _inviteCode;
          _cycleLength = coupleRes['default_cycle_length'] ?? _cycleLength;
          _periodLength = coupleRes['default_period_length'] ?? _periodLength;
          final dbBuffer = coupleRes['safety_buffer_days'] as int?;
          if (dbBuffer != null) {
            _safetyBufferDays = max(2, dbBuffer);
          }

          final createdBy = coupleRes['created_by'] as String?;
          final partnerId = coupleRes['partner_id'] as String?;
          final otherId = (createdBy == uid) ? partnerId : createdBy;

          if (otherId != null && otherId.isNotEmpty) {
            _partnerId = otherId;
            _isPaired = true;

            // Fetch partner's profile
            final partnerProfile = await client.from('profiles').select().eq('id', otherId).maybeSingle();
            if (partnerProfile != null) {
              _partnerName = partnerProfile['display_name'] ?? 'Partner';
              _partnerRole = partnerProfile['role'] ?? 'partner';
              _partnerTracksCycle = _partnerRole == 'Cycle Tracker';
              _partnerAvatarUrl = partnerProfile['avatar_url'] as String? ?? _partnerAvatarUrl;
            }
          }
        }

        // Fetch latest cycle log
        try {
          final cycleRes = await client
              .from('cycle_logs')
              .select()
              .eq('couple_id', _coupleId)
              .order('start_date', ascending: false)
              .limit(1);
          if (cycleRes.isNotEmpty) {
            _lastPeriodStartDate = DateTime.parse(cycleRes.first['start_date'] as String);
            _cycleLength = cycleRes.first['cycle_length'] ?? _cycleLength;
            _periodLength = cycleRes.first['period_length'] ?? _periodLength;
          }
        } catch (e) {
          debugPrint('Notice fetching cycle logs: $e');
        }

        // Fetch scheduled dates
        if (_isPaired) {
          try {
            final datesRes = await client
                .from('scheduled_intimacy')
                .select()
                .eq('couple_id', _coupleId)
                .order('scheduled_at', ascending: false);
            if (datesRes.isNotEmpty) {
              final serverDates = datesRes.map((d) => ScheduledIntimacy.fromJson(d)).toList();
              _scheduledDates.clear();
              _scheduledDates.addAll(serverDates);
              _rescheduleAllUpcomingNudges();
            } else if (_scheduledDates.isNotEmpty) {
              for (final d in _scheduledDates) {
                try {
                  await client.from('scheduled_intimacy').upsert({
                    'id': d.id,
                    'couple_id': _coupleId,
                    'proposed_by': d.proposedBy.isNotEmpty ? d.proposedBy : uid,
                    'scheduled_at': d.scheduledAt.toUtc().toIso8601String(),
                    'status': d.status.name,
                    'counter_scheduled_at': d.counterScheduledAt?.toUtc().toIso8601String(),
                    'response_note': d.responseNote,
                    'vibe_check_status': d.vibeCheckStatus.name,
                    'created_at': d.createdAt.toUtc().toIso8601String(),
                    'updated_at': DateTime.now().toUtc().toIso8601String(),
                  });
                } catch (e) {
                  debugPrint('Notice upserting local date: $e');
                }
              }
            }
          } catch (e) {
            debugPrint('Notice fetching scheduled dates: $e');
          }
        } else {
          _scheduledDates.clear();
        }

        // Fetch current mood window status
        try {
          final currentKey = _dateKey(DateTime.now());
          final moodRes = await client.rpc('get_mood_window_status', params: {
            'p_window': currentKey,
          });
          if (moodRes != null && moodRes is Map) {
            final userMood = moodRes['user_mood'] == true;
            final isMatch = moodRes['is_match'] == true;
            _moodSignals.putIfAbsent(currentKey, () => {});
            _moodSignals[currentKey]![_currentUserId] = userMood;
            if (isMatch && _partnerId.isNotEmpty) {
              _moodSignals[currentKey]![_partnerId] = true;
            }
          }
        } catch (e) {
          debugPrint('Notice fetching mood window status: $e');
        }

        // Fetch couple memories
        try {
          final memoriesRes = await client
              .from('couple_memories')
              .select()
              .eq('couple_id', _coupleId)
              .order('created_at', ascending: false);
          _memories.clear();
          for (final m in memoriesRes) {
            _memories.add(CoupleMemory.fromJson(m));
          }
          await _saveToStorage();
        } catch (e) {
          debugPrint('Notice fetching couple memories: $e');
        }

        // Fetch couple chat messages
        if (_isPaired) {
          try {
            final chatRes = await client
                .from('couple_chat_messages')
                .select()
                .eq('couple_id', _coupleId)
                .order('created_at', ascending: true)
                .limit(500);
            if (chatRes.isNotEmpty) {
              _chatMessages.clear();
              for (final c in chatRes) {
                _chatMessages.add(ChatMessage.fromJson(c));
              }
            }
          } catch (e) {
            debugPrint('Notice fetching chat messages: $e');
          }
        } else {
          _chatMessages.clear();
        }

        if (_isPaired) {
          _hasCreatedProfile = true;
          _hasCompletedOnboarding = true;
        }
        await _saveToStorage();
        scheduleCycleNotifications();
        if (_inviteCode.isNotEmpty) {
          _subscribeToChannel();
        }
        notifyListeners();
        return _isPaired;
      } else {
        // User is authenticated but hasn't completed Step 1 profile creation yet.
        // Only pre-fill their display name so Step 1 (CreateProfileScreen) lets them
        // choose their name and gender/cycle role before proceeding to Step 2.
        final googleName = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email?.split('@').first ??
            '';

        if (_currentUserName.isEmpty && googleName.isNotEmpty) {
          _currentUserName = googleName;
        }

        await _saveToStorage();
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('syncWithSupabaseUser error: $e');
      return false;
    }
  }

  Future<void> resetToOnboarding() async {
    if (_realtimeChannel != null) {
      try {
        await _realtimeChannel!.sendBroadcastMessage(
          event: 'partner_unlinked',
          payload: {
            'sender_id': _currentUserId,
          },
        );
      } catch (e) {
        debugPrint('Error broadcasting unlink on reset: $e');
      }
    }
    _hasCompletedOnboarding = false;
    _hasCreatedProfile = false;
    _privacyPin = '';
    _recoveryEmail = '';
    _isPaired = false;
    _partnerId = '';
    _partnerName = '';
    _partnerRole = '';
    _partnerAvatarUrl = '';
    _inviteCode = '';
    _moodSignals.clear();
    _scheduledDates.clear();
    _memories.clear();
    _readMemoryIds.clear();
    _chatMessages.clear();
    _lastViewedMemoriesAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefKey);
    notifyListeners();
  }

  @visibleForTesting
  void setPartnerForTesting({
    required bool isPaired,
    String partnerName = '',
    String partnerRole = 'Partner',
    bool partnerTracksCycle = true,
    String? inviteCode,
    String partnerAvatarUrl = '',
  }) {
    _isPaired = isPaired;
    _partnerName = partnerName;
    _partnerRole = partnerRole;
    _partnerTracksCycle = partnerTracksCycle;
    _partnerAvatarUrl = partnerAvatarUrl;
    if (inviteCode != null) _inviteCode = inviteCode;
    notifyListeners();
  }

  @visibleForTesting
  void setUserEmailForTesting(String email) {
    _userEmail = email;
    notifyListeners();
  }

  @visibleForTesting
  void setCurrentUserIdForTesting(String id) {
    _currentUserId = id;
    notifyListeners();
  }

  @visibleForTesting
  void setChatMessagesForTesting(List<ChatMessage> messages) {
    _chatMessages.clear();
    _chatMessages.addAll(messages);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _beaconTimer?.cancel();
    super.dispose();
  }
}
