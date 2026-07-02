import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local_store.dart';
import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/platform.dart';
import '../models/subscription.dart';

/// 云同步（Supabase）。手机/电脑用同一账号互通。
///
/// 本地优先：所有改动先落本地，再后台推送到云端；
/// 启动时执行 [fullSync]：拉取远端 → 按 updatedAt last-write-wins 合并进本地
/// → 把合并后的全量回推远端，实现双向同步。
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

  /// 全量拉取一张表。失败返回空表。
  Future<List<Map<String, dynamic>>> pull(String table) async {
    if (_client == null) return const [];
    try {
      final res = await _client!.from(table).select();
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  /// 启动时的双向同步：拉取远端 → LWW 合并进本地 → 全量回推。
  /// 返回本地是否因合并发生了变更（true 则调用方应刷新内存状态）。
  Future<bool> fullSync(LocalStore store) async {
    if (_client == null) return false;

    final cats = await pull('categories');
    final plats = await pull('platforms');
    final subs = await pull('subscriptions');
    final changed = store.mergeRemote(
      categories: cats,
      platforms: plats,
      subscriptions: subs,
    );

    // 合并后本地即最新版本，全量回推让远端补齐缺失/过期记录（upsert 幂等）。
    await _pushAll('categories', store.dumpCategories());
    await _pushAll('platforms', store.dumpPlatforms());
    await _pushAll('subscriptions', store.dumpSubscriptions());
    return changed;
  }

  Future<void> _pushAll(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _safe(() => _client!.from(table).upsert(rows));
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
