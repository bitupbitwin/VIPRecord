/// 计费周期：决定金额折算到「每月」时的分母。
enum BillingCycle {
  monthly(1, '月付'),
  quarterly(3, '季付'),
  yearly(12, '年付');

  const BillingCycle(this.months, this.label);

  /// 该周期覆盖的月数，用于「月均成本 = 金额 / months」。
  final int months;
  final String label;

  static BillingCycle fromName(String name) =>
      BillingCycle.values.firstWhere((e) => e.name == name,
          orElse: () => BillingCycle.monthly);
}

/// 币种：订阅金额可用人民币或美元填写，二者按固定汇率联动。
enum Currency {
  cny('CNY', '¥', '人民币'),
  usd('USD', '\$', '美元');

  const Currency(this.code, this.symbol, this.label);

  final String code;
  final String symbol;
  final String label;

  static Currency fromName(String name) =>
      Currency.values.firstWhere((e) => e.name == name,
          orElse: () => Currency.cny);
}

/// 统计口径切换。
enum StatScope { month, quarter, year }
