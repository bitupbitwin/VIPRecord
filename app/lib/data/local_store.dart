import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/platform.dart';
import '../models/subscription.dart';
import 'seed_data.dart';

/// 本地优先存储（Hive，纯 Dart，全平台通用）。
/// 每个实体以 JSON 字符串存入对应 box，key 为实体 id。
class LocalStore {
  static const _categoriesBox = 'categories';
  static const _platformsBox = 'platforms';
  static const _subscriptionsBox = 'subscriptions';
  static const _metaBox = 'meta';

  late Box<String> _categories;
  late Box<String> _platforms;
  late Box<String> _subscriptions;
  late Box<String> _meta;

  Future<void> init() async {
    await Hive.initFlutter();
    _categories = await Hive.openBox<String>(_categoriesBox);
    _platforms = await Hive.openBox<String>(_platformsBox);
    _subscriptions = await Hive.openBox<String>(_subscriptionsBox);
    _meta = await Hive.openBox<String>(_metaBox);

    // 首次启动写入预置分类/平台。
    if (_meta.get('seeded') != 'true') {
      for (final c in SeedData.categories()) {
        _categories.put(c.id, jsonEncode(c.toJson()));
      }
      for (final p in SeedData.platforms()) {
        _platforms.put(p.id, jsonEncode(p.toJson()));
      }
      _meta.put('seeded', 'true');
    }
  }

  // ---- 读取 ----
  List<Category> categories() => _categories.values
      .map((s) => Category.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .where((c) => !c.deleted)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Platform> platforms() => _platforms.values
      .map((s) => Platform.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .where((p) => !p.deleted)
      .toList();

  List<Subscription> subscriptions() => _subscriptions.values
      .map((s) => Subscription.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .where((s) => !s.deleted)
      .toList();

  // ---- 写入 ----
  Future<void> putCategory(Category c) async =>
      _categories.put(c.id, jsonEncode(c.toJson()));
  Future<void> putPlatform(Platform p) async =>
      _platforms.put(p.id, jsonEncode(p.toJson()));
  Future<void> putSubscription(Subscription s) async =>
      _subscriptions.put(s.id, jsonEncode(s.toJson()));

  // ---- 设置 ----
  AppSettings settings() {
    final raw = _meta.get('settings');
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings s) async =>
      _meta.put('settings', jsonEncode(s.toJson()));

  // ---- 导出 / 导入（备份兜底）----
  String exportJson() => jsonEncode({
        'categories': _categories.values.toList(),
        'platforms': _platforms.values.toList(),
        'subscriptions': _subscriptions.values.toList(),
      });
}
