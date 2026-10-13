class MoodStatus {
  final bool userInTheMood;
  final bool isMatch;
  final DateTime signalDate;
  final bool hasCouple;
  final String? coupleId;

  const MoodStatus({
    required this.userInTheMood,
    required this.isMatch,
    required this.signalDate,
    required this.hasCouple,
    this.coupleId,
  });

  factory MoodStatus.empty([DateTime? date]) {
    return MoodStatus(
      userInTheMood: false,
      isMatch: false,
      signalDate: date ?? DateTime.now(),
      hasCouple: false,
    );
  }

  factory MoodStatus.fromJson(Map<String, dynamic> json) {
    return MoodStatus(
      userInTheMood: json['user_mood'] as bool? ?? false,
      isMatch: json['is_match'] as bool? ?? false,
      signalDate: json['signal_date'] != null
          ? DateTime.parse(json['signal_date'].toString())
          : DateTime.now(),
      hasCouple: json['has_couple'] as bool? ?? true,
      coupleId: json['couple_id'] as String?,
    );
  }

  MoodStatus copyWith({
    bool? userInTheMood,
    bool? isMatch,
    DateTime? signalDate,
    bool? hasCouple,
    String? coupleId,
  }) {
    return MoodStatus(
      userInTheMood: userInTheMood ?? this.userInTheMood,
      isMatch: isMatch ?? this.isMatch,
      signalDate: signalDate ?? this.signalDate,
      hasCouple: hasCouple ?? this.hasCouple,
      coupleId: coupleId ?? this.coupleId,
    );
  }
}
