class Conversation {
  Conversation({
    required this.id,
    required this.createdAt,
    this.title,
  });

  final String id;
  final String? title;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static Conversation fromMap(Map<String, Object?> map) {
    final rawCreatedAt = map['created_at'];
    DateTime createdAt;
    if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return Conversation(
      id: map['id'] as String,
      title: map['title'] as String?,
      createdAt: createdAt,
    );
  }
}
