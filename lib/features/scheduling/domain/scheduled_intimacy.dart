enum IntimacyStatus {
  pending,
  accepted,
  counterOffered,
  rainchecked,
  completed,
  canceled,
}

enum VibeCheckStatus {
  pending,
  confirmed,
  convertedCuddle,
}

class ScheduledIntimacy {
  final String id;
  final String coupleId;
  final String proposedBy;
  final DateTime scheduledAt;
  final IntimacyStatus status;
  final DateTime? counterScheduledAt;
  final String? responseNote;
  final VibeCheckStatus vibeCheckStatus;
  final DateTime createdAt;

  const ScheduledIntimacy({
    required this.id,
    required this.coupleId,
    required this.proposedBy,
    required this.scheduledAt,
    required this.status,
    this.counterScheduledAt,
    this.responseNote,
    this.vibeCheckStatus = VibeCheckStatus.pending,
    required this.createdAt,
  });

  factory ScheduledIntimacy.fromJson(Map<String, dynamic> json) {
    return ScheduledIntimacy(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      proposedBy: json['proposed_by'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      status: _parseStatus(json['status'] as String?),
      counterScheduledAt: json['counter_scheduled_at'] != null
          ? DateTime.parse(json['counter_scheduled_at'] as String).toLocal()
          : null,
      responseNote: json['response_note'] as String?,
      vibeCheckStatus: _parseVibeStatus(json['vibe_check_status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'proposed_by': proposedBy,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': status.name,
      'counter_scheduled_at': counterScheduledAt?.toUtc().toIso8601String(),
      'response_note': responseNote,
      'vibe_check_status': vibeCheckStatus.name,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  static IntimacyStatus _parseStatus(String? str) {
    switch (str) {
      case 'accepted':
        return IntimacyStatus.accepted;
      case 'counter_offered':
      case 'counterOffered':
        return IntimacyStatus.counterOffered;
      case 'rainchecked':
        return IntimacyStatus.rainchecked;
      case 'completed':
        return IntimacyStatus.completed;
      case 'canceled':
        return IntimacyStatus.canceled;
      default:
        return IntimacyStatus.pending;
    }
  }

  static VibeCheckStatus _parseVibeStatus(String? str) {
    switch (str) {
      case 'confirmed':
        return VibeCheckStatus.confirmed;
      case 'converted_cuddle':
      case 'convertedCuddle':
        return VibeCheckStatus.convertedCuddle;
      default:
        return VibeCheckStatus.pending;
    }
  }

  ScheduledIntimacy copyWith({
    String? id,
    String? coupleId,
    String? proposedBy,
    DateTime? scheduledAt,
    IntimacyStatus? status,
    DateTime? counterScheduledAt,
    String? responseNote,
    VibeCheckStatus? vibeCheckStatus,
    DateTime? createdAt,
  }) {
    return ScheduledIntimacy(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      proposedBy: proposedBy ?? this.proposedBy,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      counterScheduledAt: counterScheduledAt ?? this.counterScheduledAt,
      responseNote: responseNote ?? this.responseNote,
      vibeCheckStatus: vibeCheckStatus ?? this.vibeCheckStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String formatCountdown({DateTime? from}) {
    return formatDurationUntil(scheduledAt, from: from);
  }

  static String formatDurationUntil(DateTime target, {DateTime? from}) {
    final now = (from ?? DateTime.now()).toLocal();
    final targetLocal = target.toLocal();
    final diff = targetLocal.difference(now);

    if (diff.isNegative) {
      final pastMinutes = (-diff.inMinutes);
      final pastHours = (-diff.inHours);
      final pastDays = (-diff.inDays);
      if (pastMinutes < 60) {
        return pastMinutes <= 1 ? 'Passed moments ago' : 'Passed ${pastMinutes}m ago';
      } else if (pastHours < 24) {
        return 'Passed ${pastHours}h ago';
      }
      return 'Passed ${pastDays}d ago';
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      if (hours > 0) {
        return '$days ${days == 1 ? "day" : "days"}, $hours ${hours == 1 ? "hr" : "hrs"} left';
      } else {
        return '$days ${days == 1 ? "day" : "days"} left';
      }
    } else if (hours > 0) {
      if (minutes > 0) {
        return '$hours ${hours == 1 ? "hr" : "hrs"}, $minutes min left';
      } else {
        return '$hours ${hours == 1 ? "hr" : "hrs"} left';
      }
    } else if (minutes > 0) {
      return '$minutes min left';
    } else {
      return 'Starting now';
    }
  }
}
