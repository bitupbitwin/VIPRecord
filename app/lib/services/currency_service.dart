import '../models/enums.dart';

/// 固定汇率换算：1 USD = [usdToCny] CNY。
/// 用于「双框联动输入」和统计折算。汇率可在设置中修改。
class CurrencyConverter {
  const CurrencyConverter(this.usdToCny);

  /// 1 美元 = 多少人民币（默认值在 settings 中给出）。
  final double usdToCny;

  /// 把任意币种金额折算为本币 CNY，用于统计汇总。
  double toCny(double amount, Currency from) =>
      from == Currency.cny ? amount : amount * usdToCny;

  /// 人民币 -> 美元（双框联动：填人民币时更新美元框）。
  double cnyToUsd(double cny) => usdToCny == 0 ? 0 : cny / usdToCny;

  /// 美元 -> 人民币（双框联动：填美元时更新人民币框）。
  double usdToCnyAmount(double usd) => usd * usdToCny;

  /// 把 [from] 币种金额换算为 [to] 币种。
  double convert(double amount, Currency from, Currency to) {
    if (from == to) return amount;
    return from == Currency.cny ? cnyToUsd(amount) : usdToCnyAmount(amount);
  }
}
