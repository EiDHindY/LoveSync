enum IntimacyStatus {
  pending,
  accepted,
  counterOffered,
  rainchecked,
  completed,
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
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: _parseStatus(json['status'] as String?),
      counterScheduledAt: json['counter_scheduled_at'] != null
          ? DateTime.parse(json['counter_scheduled_at'] as String)
          : null,
      responseNote: json['response_note'] as String?,
      vibeCheckStatus: _parseVibeStatus(json['vibe_check_status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'proposed_by': proposedBy,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.name,
      'counter_scheduled_at': counterScheduledAt?.toIso8601String(),
      'response_note': responseNote,
      'vibe_check_status': vibeCheckStatus.name,
      'created_at': createdAt.toIso8601String(),
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
}
