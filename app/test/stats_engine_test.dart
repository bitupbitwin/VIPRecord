import 'package:flutter_test/flutter_test.dart';
import 'package:suborbit/models/enums.dart';
import 'package:suborbit/models/subscription.dart';
import 'package:suborbit/services/currency_service.dart';
import 'package:suborbit/services/stats_engine.dart';

void main() {
  final engine = StatsEngine(const CurrencyConverter(7.2));

  Subscription sub({
    required BillingCycle cycle,
    required double amount,
    Currency currency = Currency.cny,
    required DateTime start,
    required DateTime end,
  }) =>
      Subscription(
        id: 'x',
        platformId: 'p',
        cycle: cycle,
        amount: amount,
        currency: currency,
        startDate: start,
        endDate: end,
      );

  test('年付 ¥120 平摊到每月 ¥10，跨年正确归属', () {
    final s = sub(
      cycle: BillingCycle.yearly,
      amount: 120,
      start: DateTime(2026, 3, 1),
      end: DateTime(2027, 2, 28),
    );
    expect(engine.totalForMonth([s], 2026, 3), closeTo(10, 0.001));
    expect(engine.totalForYear([s], 2026), closeTo(100, 0.001)); // 3~12 月
    expect(engine.totalForYear([s], 2027), closeTo(20, 0.001)); // 1~2 月
  });

  test('月付 ¥15 仅订 1~3 月，季度合计 ¥45', () {
    final s = sub(
      cycle: BillingCycle.monthly,
      amount: 15,
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 3, 31),
    );
    expect(engine.totalForMonth([s], 2026, 2), closeTo(15, 0.001));
    expect(engine.totalForQuarter([s], 2026, 1), closeTo(45, 0.001));
    expect(engine.totalForMonth([s], 2026, 4), 0);
  });

  test('季付 ¥45 平摊到每月 ¥15', () {
    final s = sub(
      cycle: BillingCycle.quarterly,
      amount: 45,
      start: DateTime(2026, 4, 1),
      end: DateTime(2026, 6, 30),
    );
    expect(engine.totalForMonth([s], 2026, 5), closeTo(15, 0.001));
    expect(engine.totalForQuarter([s], 2026, 2), closeTo(45, 0.001));
  });

  test('美元订阅按固定汇率折算 CNY', () {
    final s = sub(
      cycle: BillingCycle.monthly,
      amount: 20,
      currency: Currency.usd,
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 1, 31),
    );
    // 20 USD * 7.2 = 144 CNY/月
    expect(engine.totalForMonth([s], 2026, 1), closeTo(144, 0.001));
  });
}
