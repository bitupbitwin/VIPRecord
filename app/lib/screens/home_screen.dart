import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/subscription.dart';
import '../providers/providers.dart';
import '../services/stats_engine.dart';
import '../theme/glass.dart';
import 'category_detail_screen.dart';
import 'settings_screen.dart';

final selectedYearProvider = StateProvider<int>((_) => DateTime.now().year);
// 柱状图中被选中查看的月份（默认当前月），点击柱子可切换查看任意月金额。
final selectedMonthProvider = StateProvider<int>((_) => DateTime.now().month);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final _money = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final engine = ref.watch(statsEngineProvider);
    final year = ref.watch(selectedYearProvider);
    final now = DateTime.now();
    final subs = data.subscriptions;

    final curMonth = now.month;
    final curQuarter = ((now.month - 1) ~/ 3) + 1;
    final monthTotal = engine.totalForMonth(subs, year, curMonth);
    final quarterTotal = engine.totalForQuarter(subs, year, curQuarter);
    final yearTotal = engine.totalForYear(subs, year);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('订阅星轨 · SubOrbit',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Windows / 平板等宽屏 -> 双栏仪表盘；手机窄屏 -> 单列。
            final wide = constraints.maxWidth >= 900;

            final statsRow = Row(
              children: [
                Expanded(child: _statCard('本月 · $curMonth月', monthTotal, const Color(0xFF7C9CFF))),
                const SizedBox(width: 10),
                Expanded(child: _statCard('本季度 · Q$curQuarter', quarterTotal, const Color(0xFF4DD0E1))),
                if (wide) ...[
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard('全年 $year', yearTotal,
                          const Color(0xFFF06292), big: true)),
                ],
              ],
            );

            final emptyHint = subs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: GlassCard(
                      child: Row(
                        children: [
                          const Text('🛰️', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '还没有订阅记录。点开下方任意分类，进入后点「添加订阅」即可记账，统计会实时更新。',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();

            if (wide) {
              // 左栏：年份 + 统计 + 柱状图 + 即将到期；右栏：分类占比与清单。
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _yearSwitcher(ref, year),
                          const SizedBox(height: 16),
                          statsRow,
                          const SizedBox(height: 18),
                          emptyHint,
                          _monthlyChart(ref, engine, subs, year),
                          const SizedBox(height: 18),
                          _upcomingExpiries(context, ref, data),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _categoryBreakdown(context, ref, engine, year),
                    ),
                  ],
                ),
              );
            }

            // 手机单列。
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _yearSwitcher(ref, year),
                const SizedBox(height: 16),
                statsRow,
                const SizedBox(height: 10),
                _statCard('全年 $year', yearTotal, const Color(0xFFF06292),
                    big: true),
                const SizedBox(height: 18),
                emptyHint,
                _upcomingExpiries(context, ref, data),
                _monthlyChart(engine, subs, year),
                const SizedBox(height: 18),
                _categoryBreakdown(context, ref, engine, year),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 即将到期清单（默认未来 30 天内），与到期提醒联动。
  Widget _upcomingExpiries(BuildContext context, WidgetRef ref, AppData data) {
    final now = DateTime.now();
    final lead = data.settings.reminderLeadDays as int;
    final nameById = {for (final p in data.platforms) p.id: p.name};
    final emojiById = {for (final p in data.platforms) p.id: p.emoji};
    final upcoming = [
      for (final s in data.subscriptions)
        if (!s.endDate.isBefore(now) &&
            s.endDate.difference(now).inDays <= 30)
          s
    ]..sort((a, b) => a.endDate.compareTo(b.endDate));
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final df = DateFormat('MM/dd');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: Color(0xFFFFD54F), size: 18),
                SizedBox(width: 8),
                Text('即将到期',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            for (final s in upcoming.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(emojiById[s.platformId] ?? '🔹'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(nameById[s.platformId] ?? '订阅',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    Text('${df.format(s.endDate)} 到期',
                        style: TextStyle(
                            color: s.endDate.difference(now).inDays <= lead
                                ? const Color(0xFFFF8A65)
                                : Colors.white60,
                            fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _yearSwitcher(WidgetRef ref, int year) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () =>
                  ref.read(selectedYearProvider.notifier).state = year - 1,
            ),
            Text('$year 年',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () =>
                  ref.read(selectedYearProvider.notifier).state = year + 1,
            ),
          ],
        ),
      );

  Widget _statCard(String label, double value, Color color, {bool big = false}) =>
      GlassCard(
        padding: EdgeInsets.all(big ? 22 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.6), blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            // 数值变化时平滑滚动到新值（实时统计的动画反馈）。
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: value),
              builder: (_, v, __) => Text(
                _money.format(v),
                style: TextStyle(
                    color: color,
                    fontSize: big ? 36 : 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  Widget _monthlyChart(
      WidgetRef ref, StatsEngine engine, List<Subscription> subs, int year) {
    final List<double> series = engine.monthlySeries(subs, year);
    final double maxV =
        series.isEmpty ? 0 : series.reduce((a, b) => a > b ? a : b);
    final sel = ref.watch(selectedMonthProvider); // 1..12
    final double selTotal = series[sel - 1];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('每月支出（平摊视图）',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              // 选中月份的金额（点柱子切换）
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C9CFF).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7C9CFF).withOpacity(0.5)),
                ),
                child: Text('$sel月 · ${HomeScreen._money.format(selTotal)}',
                    style: const TextStyle(
                        color: Color(0xFFBFD0FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('点柱子可查看该月金额',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxV == 0 ? 10 : maxV * 1.2,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${group.x + 1}月\n${HomeScreen._money.format(rod.toY)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  touchCallback: (event, resp) {
                    final spot = resp?.spot;
                    if (spot != null) {
                      ref.read(selectedMonthProvider.notifier).state =
                          spot.touchedBarGroupIndex + 1;
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('${v.toInt() + 1}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10)),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 12; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: series[i],
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        // 选中的月份高亮（更亮/暖色），其余用主色渐变。
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: i == sel - 1
                              ? const [Color(0xFFFFB36B), Color(0xFFF06292)]
                              : const [Color(0xFF7C9CFF), Color(0xFF4DD0E1)],
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdown(
      BuildContext context, WidgetRef ref, StatsEngine engine, int year) {
    final data = ref.read(appProvider);
    final breakdown = engine.categoryBreakdownForYear(
        data.subscriptions, data.platformToCategory, year);
    final cats = data.categories;
    final total = breakdown.values.fold<double>(0, (a, b) => a + b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('分类支出占比',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (total > 0)
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    for (final c in cats)
                      if ((breakdown[c.id] ?? 0) > 0)
                        PieChartSectionData(
                          value: breakdown[c.id]!,
                          color: Color(c.colorValue),
                          radius: 40,
                          title:
                              '${((breakdown[c.id]! / total) * 100).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Text('点击分类可管理/配置其中的每个 App',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 4),
          // 分类列表，点击进入详情可配置每个 App
          for (final c in cats)
            ListTile(
              contentPadding: EdgeInsets.zero,
              // 分类名本身已含 emoji，不再额外加前置图标，避免重复显示两个。
              title: Text(c.name,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    HomeScreen._money.format(breakdown[c.id] ?? 0),
                    style: TextStyle(color: Color(c.colorValue), fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: Colors.white38, size: 20),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(categoryId: c.id)),
              ),
            ),
        ],
      ),
    );
  }
}
