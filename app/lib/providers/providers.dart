import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/platform.dart';
import '../models/subscription.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../services/stats_engine.dart';
import '../services/sync_service.dart';

/// 由 main() 注入（override）的单例。
final localStoreProvider = Provider<LocalStore>((ref) => throw UnimplementedError());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// 内存中的全量数据 + 设置。改动后通知 UI，实现统计实时刷新。
class AppData {
  AppData({
    required this.categories,
    required this.platforms,
    required this.subscriptions,
    required this.settings,
  });

  final List<Category> categories;
  final List<Platform> platforms;
  final List<Subscription> subscriptions;
  final AppSettings settings;

  Map<String, String> get platformToCategory =>
      {for (final p in platforms) p.id: p.categoryId};

  AppData copyWith({
    List<Category>? categories,
    List<Platform>? platforms,
    List<Subscription>? subscriptions,
    AppSettings? settings,
  }) =>
      AppData(
        categories: categories ?? this.categories,
        platforms: platforms ?? this.platforms,
        subscriptions: subscriptions ?? this.subscriptions,
        settings: settings ?? this.settings,
      );
}

class AppNotifier extends Notifier<AppData> {
  LocalStore get _store => ref.read(localStoreProvider);
  SyncService get _sync => ref.read(syncServiceProvider);
  NotificationService get _notif => ref.read(notificationServiceProvider);

  @override
  AppData build() => AppData(
        categories: _store.categories(),
        platforms: _store.platforms(),
        subscriptions: _store.subscriptions(),
        settings: _store.settings(),
      );

  /// 按当前订阅与设置重排到期提醒。
  Future<void> rescheduleReminders() => _notif.rescheduleAll(
        subs: state.subscriptions,
        platforms: state.platforms,
        enabled: state.settings.reminderEnabled,
        leadDays: state.settings.reminderLeadDays,
      );

  // ---- 订阅记录 ----
  Future<void> upsertSubscription(Subscription s) async {
    await _store.putSubscription(s);
    await _sync.pushSubscription(s);
    final list = [...state.subscriptions.where((e) => e.id != s.id), s];
    state = state.copyWith(subscriptions: list);
    await rescheduleReminders();
  }

  Future<void> deleteSubscription(Subscription s) async {
    final removed = s.copyWith(deleted: true);
    await _store.putSubscription(removed);
    await _sync.pushSubscription(removed);
    state = state.copyWith(
      subscriptions: state.subscriptions.where((e) => e.id != s.id).toList(),
    );
    await rescheduleReminders();
  }

  // ---- 平台 ----
  Future<void> upsertPlatform(Platform p) async {
    await _store.putPlatform(p);
    await _sync.pushPlatform(p);
    final list = [...state.platforms.where((e) => e.id != p.id), p];
    state = state.copyWith(platforms: list);
  }

  // ---- 分类 ----
  Future<void> upsertCategory(Category c) async {
    await _store.putCategory(c);
    await _sync.pushCategory(c);
    final list = [...state.categories.where((e) => e.id != c.id), c]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    state = state.copyWith(categories: list);
  }

  // ---- 设置（含汇率，改动后统计随之刷新）----
  Future<void> updateSettings(AppSettings s) async {
    await _store.saveSettings(s);
    state = state.copyWith(settings: s);
    await rescheduleReminders();
  }
}

final appProvider =
    NotifierProvider<AppNotifier, AppData>(AppNotifier.new);

/// 汇率换算器（随设置变化）。
final converterProvider = Provider<CurrencyConverter>((ref) {
  final rate = ref.watch(appProvider.select((s) => s.settings.usdToCny));
  return CurrencyConverter(rate);
});

/// 统计引擎（随汇率变化重建 -> 统计实时更新）。
final statsEngineProvider = Provider<StatsEngine>(
    (ref) => StatsEngine(ref.watch(converterProvider)));
