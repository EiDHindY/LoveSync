class CoupleMemory {
  final String id;
  final String coupleId;
  final String? createdBy;
  final String type; // 'spark_match', 'spark_celebrated', 'date_night'
  final String title;
  final String description;
  final String? windowKey;
  final DateTime createdAt;

  const CoupleMemory({
    required this.id,
    required this.coupleId,
    this.createdBy,
    required this.type,
    required this.title,
    required this.description,
    this.windowKey,
    required this.createdAt,
  });

  factory CoupleMemory.fromJson(Map<String, dynamic> json) {
    return CoupleMemory(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String? ?? '',
      createdBy: json['created_by'] as String?,
      type: json['type'] as String? ?? 'spark_match',
      title: json['title'] as String? ?? 'Spark Memory',
      description: json['description'] as String? ?? '',
      windowKey: json['window_key'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'created_by': createdBy,
      'type': type,
      'title': title,
      'description': description,
      'window_key': windowKey,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
