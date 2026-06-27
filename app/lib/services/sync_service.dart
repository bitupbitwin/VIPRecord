import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/platform.dart';
import '../models/subscription.dart';

/// 云同步（Supabase）。手机/电脑用同一账号互通。
///
/// 本地优先：所有改动先落本地，再后台推送到云端；
/// 拉取时按记录的 updatedAt 做 last-write-wins 合并。
///
/// 云端需建三张表 categories / platforms / subscriptions，
/// 字段与各模型 toJson 一致，主键 id（详见 README 的建表 SQL）。
class SyncService {
  SupabaseClient? _client;
  bool get isReady => _client != null;

  /// 用设置中的 url / anonKey 初始化（留空则不启用）。
  Future<void> init(AppSettings s) async {
    if (!s.syncEnabled || s.supabaseUrl.isEmpty || s.supabaseAnonKey.isEmpty) {
      _client = null;
      return;
    }
    await Supabase.initialize(
      url: s.supabaseUrl,
      anonKey: s.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// 推送单条（upsert）。失败静默（保持本地优先、离线可用）。
  Future<void> pushCategory(Category c) async =>
      _safe(() => _client!.from('categories').upsert(c.toJson()));
  Future<void> pushPlatform(Platform p) async =>
      _safe(() => _client!.from('platforms').upsert(p.toJson()));
  Future<void> pushSubscription(Subscription s) async =>
      _safe(() => _client!.from('subscriptions').upsert(s.toJson()));

  /// 全量拉取（用于启动时合并）。
  Future<List<Map<String, dynamic>>> pull(String table) async {
    if (_client == null) return const [];
    try {
      final res = await _client!.from(table).select();
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _safe(Future<dynamic> Function() op) async {
    if (_client == null) return;
    try {
      await op();
    } catch (_) {
      // 离线或失败时忽略，下一次同步再补。
    }
  }
}
