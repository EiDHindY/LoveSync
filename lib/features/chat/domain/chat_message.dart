class ChatMessage {
  final String id;
  final String coupleId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final bool isViewOnce;
  final bool isViewed;
  final Map<String, String> reactions;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.coupleId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.isViewOnce = false,
    this.isViewed = false,
    this.reactions = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool isMine(String currentUserId) => senderId == currentUserId;
  bool get isRead => readAt != null;
  bool get isBurned => isViewOnce && isViewed;

  ChatMessage copyWith({
    String? id,
    String? coupleId,
    String? senderId,
    String? text,
    String? imageUrl,
    bool clearImage = false,
    bool? isViewOnce,
    bool? isViewed,
    Map<String, String>? reactions,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      isViewOnce: isViewOnce ?? this.isViewOnce,
      isViewed: isViewed ?? this.isViewed,
      reactions: reactions ?? this.reactions,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsedReactions = {};
    if (json['reactions'] != null && json['reactions'] is Map) {
      final raw = json['reactions'] as Map;
      raw.forEach((k, v) {
        parsedReactions[k.toString()] = v.toString();
      });
    }

    return ChatMessage(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String? ?? json['coupleId'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      isViewOnce: json['is_view_once'] as bool? ?? json['isViewOnce'] as bool? ?? false,
      isViewed: json['is_viewed'] as bool? ?? json['isViewed'] as bool? ?? false,
      reactions: parsedReactions,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : (json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
      'is_view_once': isViewOnce,
      'is_viewed': isViewed,
      'reactions': reactions,
      'read_at': readAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'coupleId': coupleId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'isViewOnce': isViewOnce,
      'isViewed': isViewed,
      'reactions': reactions,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
