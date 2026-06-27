import '../models/subscription.dart';
import 'currency_service.dart';

/// 年-月键，用于在时间线上定位一个自然月。
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);
  final int year;
  final int month; // 1..12

  int get quarter => ((month - 1) ~/ 3) + 1;

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => year * 100 + month;

  @override
  int compareTo(YearMonth o) =>
      year != o.year ? year.compareTo(o.year) : month.compareTo(o.month);
}

/// 核心统计引擎：以时间线为根本，把年付/季付平摊到每个自然月，
/// 再逐级汇总成月度 / 季度 / 年度支出（全部以 CNY 为本币）。
class StatsEngine {
  StatsEngine(this.converter);
  final CurrencyConverter converter;

  /// 单条订阅的「月均成本（CNY）」= 折算后金额 / 周期月数。
  double monthlyEquivalentCny(Subscription s) {
    final cny = converter.toCny(s.amount, s.currency);
    return cny / s.cycle.months;
  }

  /// 该订阅期覆盖的所有自然月（含起止月）。
  List<YearMonth> coveredMonths(Subscription s) {
    final start = YearMonth(s.startDate.year, s.startDate.month);
    final end = YearMonth(s.endDate.year, s.endDate.month);
    final result = <YearMonth>[];
    var y = start.year, m = start.month;
    while (YearMonth(y, m).compareTo(end) <= 0) {
      result.add(YearMonth(y, m));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return result;
  }

  bool _active(Subscription s) => !s.deleted;

  /// 指定自然月的总支出（CNY）。
  double totalForMonth(Iterable<Subscription> subs, int year, int month) {
    final target = YearMonth(year, month);
    double sum = 0;
    for (final s in subs) {
      if (!_active(s)) continue;
      if (coveredMonths(s).contains(target)) sum += monthlyEquivalentCny(s);
    }
    return sum;
  }

  /// 指定季度（1..4）的总支出 = 该季度 3 个月之和。
  double totalForQuarter(Iterable<Subscription> subs, int year, int quarter) {
    final first = (quarter - 1) * 3 + 1;
    double sum = 0;
    for (var m = first; m < first + 3; m++) {
      sum += totalForMonth(subs, year, m);
    }
    return sum;
  }

  /// 指定年度的总支出 = 12 个月之和。
  double totalForYear(Iterable<Subscription> subs, int year) {
    double sum = 0;
    for (var m = 1; m <= 12; m++) {
      sum += totalForMonth(subs, year, m);
    }
    return sum;
  }

  /// 某年 12 个月的支出序列，用于柱状图。
  List<double> monthlySeries(Iterable<Subscription> subs, int year) =>
      List.generate(12, (i) => totalForMonth(subs, year, i + 1));

  /// 把订阅按 platformId -> categoryId 映射后，统计某月各分类占比。
  /// [platformCategory] 提供 platformId -> categoryId。
  Map<String, double> categoryBreakdownForMonth(
    Iterable<Subscription> subs,
    Map<String, String> platformCategory,
    int year,
    int month,
  ) {
    final target = YearMonth(year, month);
    final map = <String, double>{};
    for (final s in subs) {
      if (!_active(s)) continue;
      if (!coveredMonths(s).contains(target)) continue;
      final cat = platformCategory[s.platformId];
      if (cat == null) continue;
      map[cat] = (map[cat] ?? 0) + monthlyEquivalentCny(s);
    }
    return map;
  }

  /// 某年各分类合计（用于年度占比）。
  Map<String, double> categoryBreakdownForYear(
    Iterable<Subscription> subs,
    Map<String, String> platformCategory,
    int year,
  ) {
    final map = <String, double>{};
    for (var m = 1; m <= 12; m++) {
      final part = categoryBreakdownForMonth(subs, platformCategory, year, m);
      part.forEach((k, v) => map[k] = (map[k] ?? 0) + v);
    }
    return map;
  }
}
