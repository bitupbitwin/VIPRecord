/// 全局设置：固定汇率、Supabase 云同步配置等。
class AppSettings {
  AppSettings({
    this.usdToCny = 7.20,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.syncEnabled = false,
    this.amortized = true, // true=平摊视图（默认），false=实付视图
  });

  /// 1 USD = usdToCny CNY（双框联动 & 统计折算）。
  double usdToCny;

  /// 云同步配置（手机/电脑互通）。留空则仅本地。
  String supabaseUrl;
  String supabaseAnonKey;
  bool syncEnabled;

  bool amortized;

  Map<String, dynamic> toJson() => {
        'usdToCny': usdToCny,
        'supabaseUrl': supabaseUrl,
        'supabaseAnonKey': supabaseAnonKey,
        'syncEnabled': syncEnabled,
        'amortized': amortized,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        usdToCny: (j['usdToCny'] as num?)?.toDouble() ?? 7.20,
        supabaseUrl: (j['supabaseUrl'] ?? '') as String,
        supabaseAnonKey: (j['supabaseAnonKey'] ?? '') as String,
        syncEnabled: (j['syncEnabled'] ?? false) as bool,
        amortized: (j['amortized'] ?? true) as bool,
      );
}
