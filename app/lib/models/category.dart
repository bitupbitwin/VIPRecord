/// 分类（如「AI 助手 & 大模型」）。可自定义增删改、排序。
class Category {
  Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.sortOrder,
    DateTime? updatedAt,
    this.deleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String emoji;
  int colorValue; // ARGB int
  int sortOrder;
  DateTime updatedAt;
  bool deleted;

  Category copyWith({
    String? name,
    String? emoji,
    int? colorValue,
    int? sortOrder,
    bool? deleted,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: DateTime.now(),
        deleted: deleted ?? this.deleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorValue': colorValue,
        'sortOrder': sortOrder,
        'updatedAt': updatedAt.toIso8601String(),
        'deleted': deleted,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] ?? '📦') as String,
        colorValue: (j['colorValue'] ?? 0xFF7C9CFF) as int,
        sortOrder: (j['sortOrder'] ?? 0) as int,
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
        deleted: (j['deleted'] ?? false) as bool,
      );
}
