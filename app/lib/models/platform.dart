/// 平台（如「网易云音乐」「ChatGPT」）。归属某个分类，可有多条订阅记录。
class Platform {
  Platform({
    required this.id,
    required this.categoryId,
    required this.name,
    this.emoji = '🔹',
    this.notes = '',
    DateTime? updatedAt,
    this.deleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String categoryId;
  String name;
  String emoji;
  String notes;
  DateTime updatedAt;
  bool deleted;

  Platform copyWith({
    String? categoryId,
    String? name,
    String? emoji,
    String? notes,
    bool? deleted,
  }) =>
      Platform(
        id: id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        notes: notes ?? this.notes,
        updatedAt: DateTime.now(),
        deleted: deleted ?? this.deleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'emoji': emoji,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
        'deleted': deleted,
      };

  factory Platform.fromJson(Map<String, dynamic> j) => Platform(
        id: j['id'] as String,
        categoryId: j['categoryId'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] ?? '🔹') as String,
        notes: (j['notes'] ?? '') as String,
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
        deleted: (j['deleted'] ?? false) as bool,
      );
}
