import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../theme/glass.dart';
import 'category_detail_screen.dart';
import 'settings_screen.dart';

final selectedYearProvider = StateProvider<int>((_) => DateTime.now().year);

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

    final monthTotal =
        engine.totalForMonth(subs, year, year == now.year ? now.month : 1);
    final quarterTotal = engine.totalForQuarter(
        subs, year, year == now.year ? ((now.month - 1) ~/ 3) + 1 : 1);
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _yearSwitcher(ref, year),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statCard('本月', monthTotal, const Color(0xFF7C9CFF))),
                const SizedBox(width: 10),
                Expanded(child: _statCard('本季度', quarterTotal, const Color(0xFF4DD0E1))),
              ],
            ),
            const SizedBox(height: 10),
            _statCard('全年 $year', yearTotal, const Color(0xFFF06292), big: true),
            const SizedBox(height: 18),
            _monthlyChart(engine, subs, year),
            const SizedBox(height: 18),
            _categoryBreakdown(context, ref, engine, year),
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(_money.format(value),
                style: TextStyle(
                    color: color,
                    fontSize: big ? 36 : 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _monthlyChart(engine, subs, int year) {
    final series = engine.monthlySeries(subs, year);
    final maxV = (series.isEmpty ? 0 : series.reduce((a, b) => a > b ? a : b));
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('每月支出（平摊视图）',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxV == 0 ? 10 : maxV * 1.2,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
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
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF7C9CFF), Color(0xFF4DD0E1)],
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
      BuildContext context, WidgetRef ref, engine, int year) {
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
          const SizedBox(height: 12),
          // 分类列表，点击进入详情
          for (final c in cats)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(c.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(c.name,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              trailing: Text(
                HomeScreen._money.format(breakdown[c.id] ?? 0),
                style: TextStyle(color: Color(c.colorValue), fontSize: 14),
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
