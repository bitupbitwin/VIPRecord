import 'enums.dart';

/// 订阅记录 / 订阅期：某平台的一段订阅（最关键的模型）。
///
/// 金额以「原始币种」原值保存（amount + currency），
/// 统计时再按汇率统一折算到本币（CNY）。
/// 起止日期决定该订阅在时间线上覆盖哪些自然月。
class Subscription {
  Subscription({
    required this.id,
    required this.platformId,
    required this.cycle,
    required this.amount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    this.autoRenew = false,
    this.notes = '',
    DateTime? updatedAt,
    this.deleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String platformId;
  BillingCycle cycle;
  double amount; // 原始币种金额（单个周期价格）
  Currency currency;
  DateTime startDate;
  DateTime endDate;
  bool autoRenew;
  String notes;
  DateTime updatedAt;
  bool deleted;

  Subscription copyWith({
    String? platformId,
    BillingCycle? cycle,
    double? amount,
    Currency? currency,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    String? notes,
    bool? deleted,
  }) =>
      Subscription(
        id: id,
        platformId: platformId ?? this.platformId,
        cycle: cycle ?? this.cycle,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        autoRenew: autoRenew ?? this.autoRenew,
        notes: notes ?? this.notes,
        updatedAt: DateTime.now(),
        deleted: deleted ?? this.deleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'platformId': platformId,
        'cycle': cycle.name,
        'amount': amount,
        'currency': currency.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'autoRenew': autoRenew,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
        'deleted': deleted,
      };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        platformId: j['platformId'] as String,
        cycle: BillingCycle.fromName((j['cycle'] ?? 'monthly') as String),
        amount: (j['amount'] as num).toDouble(),
        currency: Currency.fromName((j['currency'] ?? 'cny') as String),
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        autoRenew: (j['autoRenew'] ?? false) as bool,
        notes: (j['notes'] ?? '') as String,
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
        deleted: (j['deleted'] ?? false) as bool,
      );
}
