import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/subscription.dart';
import '../providers/providers.dart';
import '../services/stats_engine.dart';
import '../theme/glass.dart';
import 'home_screen.dart';
import 'subscription_edit_screen.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});
  final String categoryId;

  static final _money = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
  static final _df = DateFormat('yyyy/MM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final engine = ref.watch(statsEngineProvider);
    final year = ref.watch(selectedYearProvider);
    // 分类可能被（其它设备/后续版本）删除，安全兜底避免崩溃。
    final cat = data.categories.firstWhereOrNull((c) => c.id == categoryId);
    if (cat == null) {
      return const GlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text('该分类不存在或已被删除',
                style: TextStyle(color: Colors.white70)),
          ),
        ),
      );
    }
    final platforms =
        data.platforms.where((p) => p.categoryId == categoryId).toList();

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(cat.name),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF7C9CFF),
          icon: const Icon(Icons.add),
          label: const Text('添加订阅'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    SubscriptionEditScreen(categoryId: categoryId)),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final p in platforms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(p.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...data.subscriptions
                            .where((s) => s.platformId == p.id)
                            .map((s) => _subRow(context, ref, engine, s)),
                        if (!data.subscriptions.any((s) => s.platformId == p.id))
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('暂无订阅记录',
                                style: TextStyle(color: Colors.white38)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subRow(
      BuildContext context, WidgetRef ref, StatsEngine engine, Subscription s) {
    final double monthly = engine.monthlyEquivalentCny(s);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        '${s.cycle.label} · ${s.currency.symbol}${s.amount.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        '${_df.format(s.startDate)} ~ ${_df.format(s.endDate)} · 月均 ${_money.format(monthly)}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white54, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SubscriptionEditScreen(
                      categoryId: categoryId, existing: s)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white54, size: 18),
            onPressed: () =>
                ref.read(appProvider.notifier).deleteSubscription(s),
          ),
        ],
      ),
    );
  }
}
