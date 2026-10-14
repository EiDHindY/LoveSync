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

  RealtimeChannel? _realtimeChannel;

  String _userEmail = '';
  String _userAvatarUrl = '';
  StreamSubscription<AuthState>? _authSubscription;

  // Getters
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
  bool get partnerTracksCycle => _partnerTracksCycle;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isPaired => _isPaired;
  String get inviteCode => _inviteCode;
  String get coupleId => _coupleId;
  DateTime? get lastPeriodStartDate => _lastPeriodStartDate;
  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;
  int get safetyBufferDays => _safetyBufferDays;
  List<ScheduledIntimacy> get scheduledDates => List.unmodifiable(_scheduledDates);
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
      final url = meta['avatar_url'] as String? ?? meta['picture'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
    final identities = user.identities;
    if (identities != null) {
      for (final identity in identities) {
        final idData = identity.identityData;
        if (idData != null) {
          final url = idData['avatar_url'] as String? ?? idData['picture'] as String?;
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
          },
        );
      } catch (e) {
        debugPrint('Error sending partner_ping: $e');
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

              if (senderId != null && senderId != _currentUserId) {
                _partnerId = senderId;
                _partnerName = senderName;
                _partnerRole = senderRole;
                _partnerTracksCycle = senderTracksCycle;
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

              if (senderId != null && senderId != _currentUserId) {
                _partnerId = senderId;
                _partnerName = senderName;
                _partnerRole = senderRole;
                _partnerTracksCycle = senderTracksCycle;
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

              if (senderId != null && senderId != _currentUserId) {
                if (_partnerId.isEmpty || _partnerName.isEmpty) {
                  _partnerId = senderId;
                  _partnerName = senderName;
                  _partnerRole = senderRole;
                  _partnerTracksCycle = senderTracksCycle;
                  _isPaired = true;
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
                if (_partnerId.isEmpty || _partnerName.isEmpty) {
                  _partnerId = senderId;
                  _partnerName = senderName;
                  _partnerRole = senderRole;
                  _partnerTracksCycle = senderTracksCycle;
                  _isPaired = true;
                  _saveToStorage();
                  notifyListeners();
                }
                _sendPartnerAck();
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
                _safetyBufferDays = payload['buffer_days'] as int? ?? _safetyBufferDays;
                _saveToStorage();
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
              final memoryJson = payload['memory'] as Map<String, dynamic>?;

              if (dateKey != null && senderId != null && senderId != _currentUserId) {
                _moodSignals.putIfAbsent(dateKey, () => {});
                _moodSignals[dateKey]![senderId] = false;
                _moodSignals[dateKey]![_currentUserId] = false;

                if (memoryJson != null) {
                  final partnerMem = CoupleMemory.fromJson(memoryJson);
                  _memories.removeWhere((m) => m.id == partnerMem.id || (m.windowKey == dateKey && m.type == 'spark_celebrated'));
                  _memories.insert(0, partnerMem);
                } else {
                  final celMem = CoupleMemory(
                    id: _uuid.v4(),
                    coupleId: _coupleId,
                    createdBy: senderId,
                    type: 'spark_celebrated',
                    title: 'Spark Celebrated! 🎉',
                    description: '${payload['sender_name'] ?? 'Your partner'} celebrated the spark.',
                    windowKey: dateKey,
                    createdAt: DateTime.now(),
                  );
                  _memories.removeWhere((m) => m.windowKey == dateKey && m.type == 'spark_celebrated');
                  _memories.insert(0, celMem);
                }

                NotificationService().showNotification(
                  id: 4,
                  title: 'Spark Celebrated! 🎉',
                  body: '${payload['sender_name'] ?? 'Your partner'} celebrated the spark and turned it off.',
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
                _scheduledDates.removeWhere((e) => e.id == newDate.id);
                _scheduledDates.insert(0, newDate);
                await _saveToStorage();

                NotificationService().showNotification(
                  id: 2,
                  title: 'New Date Night Proposal 💕',
                  body: 'Your partner proposed an intimate rendezvous!',
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
                          ? DateTime.tryParse(payload['counter_scheduled_at'] as String)
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
                  title: isAccepted ? 'Date Night Accepted! 🥂' : 'Date Night Update ✨',
                  body: isAccepted
                      ? '$senderName accepted your date proposal!'
                      : '$senderName responded: $statusStr',
                );

                notifyListeners();
              }
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
        _partnerTracksCycle = data['partnerTracksCycle'] ?? false;
        _isPaired = data['isPaired'] ?? _isPaired;
        _inviteCode = data['inviteCode'] ?? _inviteCode;
        _coupleId = data['coupleId'] ?? _coupleId;
        if (data['lastPeriodStartDate'] != null) {
          _lastPeriodStartDate = DateTime.parse(data['lastPeriodStartDate']);
        }
        _cycleLength = data['cycleLength'] ?? _cycleLength;
        _periodLength = data['periodLength'] ?? _periodLength;
        _safetyBufferDays = data['safetyBufferDays'] ?? _safetyBufferDays;

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
        _ensureDateMemoriesExist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  void _ensureDateMemoriesExist() {
    for (final date in _scheduledDates) {
      if (date.status == IntimacyStatus.accepted) {
        final formattedDate = DateFormat('EEEE, MMM d @ h:mm a').format(date.scheduledAt);
        final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'Your partner';
        final windowKey = DateFormat('EEE, MMM d').format(date.scheduledAt);
        if (!_memories.any((m) => m.type == 'date_night' && m.windowKey == windowKey)) {
          final mem = CoupleMemory(
            id: _uuid.v4(),
            coupleId: _coupleId,
            createdBy: date.proposedBy,
            type: 'date_night',
            title: 'Date Night Confirmed! 🥂',
            description: 'Date scheduled with $partnerDisplay for $formattedDate.',
            windowKey: windowKey,
            createdAt: date.createdAt,
          );
          _memories.insert(0, mem);
        }
      }
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
        'currentUserId': _currentUserId,
        'currentUserName': _currentUserName,
        'currentUserRole': _currentUserRole,
        'tracksCycle': _tracksCycle,
        'partnerId': _partnerId,
        'partnerName': _partnerName,
        'partnerRole': _partnerRole,
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
        'readMemoryIds': _readMemoryIds.toList(),
        'lastViewedMemoriesAt': _lastViewedMemoriesAt?.toIso8601String(),
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
      );
    }

    notifyListeners();
    return getDailyMoodStatus(targetDate);
  }

  Future<MoodStatus> turnOffSparkMatch([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final key = _dateKey(targetDate);
    _moodSignals.putIfAbsent(key, () => {});

    // Reset mood for both partners
    _moodSignals[key]![_currentUserId] = false;
    if (_partnerId.isNotEmpty) {
      _moodSignals[key]![_partnerId] = false;
    }

    final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'Your partner';
    final celMem = CoupleMemory(
      id: _uuid.v4(),
      coupleId: _coupleId,
      createdBy: _currentUserId,
      type: 'spark_celebrated',
      title: 'Spark Celebrated! 🎉',
      description: 'You and $partnerDisplay celebrated this spark!',
      windowKey: key,
      createdAt: DateTime.now(),
    );
    _memories.removeWhere((m) => m.windowKey == key && m.type == 'spark_celebrated');
    _memories.insert(0, celMem);

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
            'memory': celMem.toJson(),
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
    }

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
    if (bufferDays != null) _safetyBufferDays = bufferDays;
    await _saveToStorage();

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
    _partnerTracksCycle = false;
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
          'scheduled_at': item.scheduledAt.toIso8601String(),
          'status': item.status.name,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
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
        final formattedDate = DateFormat('EEEE, MMM d @ h:mm a').format(updated.scheduledAt);
        final partnerDisplay = _partnerName.isNotEmpty ? _partnerName : 'Your partner';
        final windowKey = DateFormat('EEE, MMM d').format(updated.scheduledAt);
        dateMem = CoupleMemory(
          id: _uuid.v4(),
          coupleId: _coupleId,
          createdBy: _currentUserId,
          type: 'date_night',
          title: 'Date Night Confirmed! 🥂',
          description: 'Date scheduled with $partnerDisplay for $formattedDate.',
          windowKey: windowKey,
          createdAt: DateTime.now(),
        );
        _memories.removeWhere((m) => m.type == 'date_night' && m.windowKey == windowKey);
        _memories.insert(0, dateMem);
      }

      await _saveToStorage();

      if (SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null) {
        try {
          final client = Supabase.instance.client;
          await client.from('scheduled_intimacy').upsert({
            'id': updated.id,
            'couple_id': updated.coupleId.isNotEmpty ? updated.coupleId : _coupleId,
            'proposed_by': updated.proposedBy.isNotEmpty ? updated.proposedBy : _currentUserId,
            'scheduled_at': updated.scheduledAt.toIso8601String(),
            'status': updated.status.name,
            'counter_scheduled_at': updated.counterScheduledAt?.toIso8601String(),
            'response_note': updated.responseNote,
            'vibe_check_status': updated.vibeCheckStatus.name,
            'created_at': updated.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
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
              'created_at': dateMem.createdAt.toIso8601String(),
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
              'counter_scheduled_at': counterTime?.toIso8601String(),
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
      _userAvatarUrl = _extractAvatarUrl(user);
      if (_currentUserName.isEmpty) {
        _currentUserName = _extractDisplayName(user);
      }
      notifyListeners();

      // 1. Fetch user's profile from Supabase
      final profileRes = await client.from('profiles').select().eq('id', uid).maybeSingle();

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
          _safetyBufferDays = coupleRes['safety_buffer_days'] ?? _safetyBufferDays;

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
        try {
          final datesRes = await client
              .from('scheduled_intimacy')
              .select()
              .eq('couple_id', _coupleId)
              .order('scheduled_at', ascending: false);
          if (datesRes.isNotEmpty) {
            final serverDates = datesRes.map((d) => ScheduledIntimacy.fromJson(d)).toList();
            for (final local in _scheduledDates) {
              if (local.status == IntimacyStatus.accepted) {
                final sIndex = serverDates.indexWhere((s) => s.id == local.id);
                if (sIndex != -1 && serverDates[sIndex].status != IntimacyStatus.accepted) {
                  try {
                    await client.from('scheduled_intimacy').update({
                      'status': 'accepted',
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', local.id);
                    serverDates[sIndex] = serverDates[sIndex].copyWith(status: IntimacyStatus.accepted);
                  } catch (e) {
                    debugPrint('Notice updating server date to accepted: $e');
                  }
                }
              }
            }
            _scheduledDates.clear();
            _scheduledDates.addAll(serverDates);
          } else if (_scheduledDates.isNotEmpty) {
            for (final d in _scheduledDates) {
              try {
                await client.from('scheduled_intimacy').upsert({
                  'id': d.id,
                  'couple_id': _coupleId,
                  'proposed_by': d.proposedBy.isNotEmpty ? d.proposedBy : uid,
                  'scheduled_at': d.scheduledAt.toIso8601String(),
                  'status': d.status.name,
                  'counter_scheduled_at': d.counterScheduledAt?.toIso8601String(),
                  'response_note': d.responseNote,
                  'vibe_check_status': d.vibeCheckStatus.name,
                  'created_at': d.createdAt.toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
              } catch (e) {
                debugPrint('Notice upserting local date: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Notice fetching scheduled dates: $e');
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
          if (memoriesRes.isNotEmpty) {
            _memories.clear();
            for (final m in memoriesRes) {
              _memories.add(CoupleMemory.fromJson(m));
            }
          }
          _ensureDateMemoriesExist();
          for (final m in _memories) {
            if (!memoriesRes.any((row) => row['id'] == m.id)) {
              try {
                await client.from('couple_memories').upsert({
                  'id': m.id,
                  'couple_id': _coupleId,
                  'created_by': m.createdBy ?? uid,
                  'type': m.type,
                  'title': m.title,
                  'description': m.description,
                  'window_key': m.windowKey,
                  'created_at': m.createdAt.toIso8601String(),
                });
              } catch (e) {
                debugPrint('Notice upserting memory to Supabase: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Notice fetching couple memories: $e');
        }

        if (_isPaired) {
          _hasCreatedProfile = true;
          _hasCompletedOnboarding = true;
        }
        await _saveToStorage();
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

  @visibleForTesting
  void setPartnerForTesting({
    required bool isPaired,
    String partnerName = '',
    String partnerRole = 'Partner',
    bool partnerTracksCycle = true,
    String? inviteCode,
  }) {
    _isPaired = isPaired;
    _partnerName = partnerName;
    _partnerRole = partnerRole;
    _partnerTracksCycle = partnerTracksCycle;
    if (inviteCode != null) _inviteCode = inviteCode;
    notifyListeners();
  }

  @visibleForTesting
  void setUserEmailForTesting(String email) {
    _userEmail = email;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _beaconTimer?.cancel();
    super.dispose();
  }
}
