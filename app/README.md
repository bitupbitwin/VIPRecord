# 订阅星轨 · SubOrbit

> 一套代码，手机 + 电脑都能用的会员订阅记账。毛玻璃界面，按时间线把每笔会员
> 自动平摊统计到月 / 季 / 年；人民币⇄美元双框联动；到期本地提醒；可选云同步。

---

## ✨ 功能一览
- **11 个分类 + 38 个平台**出厂预置（京东、ChatGPT、Claude、网易云音乐……可自定义增删）。
- **时间线分摊统计**：年付÷12、季付÷3 平摊到每个自然月，再逐级汇总成月/季/年支出；天然支持「只订其中某几个月」的非连续订阅。
- **双币种联动**：金额可填人民币或美元，填一个另一个按固定汇率自动更新。
- **实时刷新**：任意数值一改，统计与图表立即重算（Riverpod 响应式）。
- **到期提醒**：订阅期结束前 N 天（可设 1/3/7/14 天）发本地通知；首页有「即将到期」清单。
- **毛玻璃 UI**：深空渐变背景 + 磨砂卡片 + 数值滚动动画。
- **本地优先 + 云同步**：数据先存本地、离线可用；填入 Supabase 配置后手机/电脑同账号互通。

---

## 🧱 技术栈
| 用途 | 选型 |
|---|---|
| 跨端框架 | **Flutter**（Android / iOS / Windows / macOS / Linux / Web 一套代码）|
| 状态管理 | **Riverpod**（改数值统计实时刷新）|
| 本地存储 | **Hive**（纯 Dart，全平台通用）|
| 图表 | **fl_chart**（柱状 / 环形）|
| 到期提醒 | **flutter_local_notifications** + timezone |
| 云同步 | **Supabase**（HTTP，桌面/网页通用，规避 Firebase 桌面短板）|

---

## 📁 目录结构
```
app/
├─ pubspec.yaml              依赖与元信息
├─ lib/
│  ├─ main.dart              入口：初始化存储/同步/通知
│  ├─ models/                数据模型（分类·平台·订阅期·设置·枚举）
│  ├─ data/
│  │  ├─ seed_data.dart      预置 11 分类 + 38 平台
│  │  └─ local_store.dart    Hive 本地存储
│  ├─ services/
│  │  ├─ stats_engine.dart   核心统计引擎（平摊/汇总）
│  │  ├─ currency_service.dart 汇率换算
│  │  ├─ notification_service.dart 到期提醒
│  │  └─ sync_service.dart   Supabase 云同步
│  ├─ providers/providers.dart Riverpod 状态
│  ├─ theme/glass.dart       毛玻璃设计系统
│  ├─ widgets/currency_dual_input.dart 双币种联动输入
│  └─ screens/               首页/分类详情/订阅编辑/设置
└─ test/stats_engine_test.dart 统计算法单元测试
```

---

## 🚀 快速开始
本仓库只含 `lib/`、`pubspec.yaml`、`test/`。首次构建需生成各平台工程：

```bash
cd app
flutter create .          # 生成 android/ ios/ windows/ macos/ linux/ web（保留已有 lib 与 pubspec）
flutter pub get
flutter test              # 运行统计算法单元测试
flutter run               # 连接手机或选择桌面设备调试
```

打包发布：
```bash
flutter build apk         # Android 安装包
flutter build ipa         # iOS（需 Mac + 开发者账号）
flutter build windows     # Windows 桌面
flutter build macos       # macOS 桌面
flutter build linux       # Linux 桌面
flutter build web         # 网页版（浏览器可“安装到桌面”当 PWA）
```

> 详细图文步骤见 `../docs/安装说明书.md`，日常使用见 `../docs/使用指导说明书.md`。

---

## 📐 核心统计口径
每条订阅的「**月均成本（CNY）= 折算后金额 ÷ 周期月数**」（年付÷12、季付÷3、月付÷1），
分摊到订阅期 `[起始, 结束]` 覆盖的每个自然月；月度→季度→年度逐级求和。

示例：年付 ¥120、2026-03~2027-02 → 每月 ¥10；2026 年（3~12 月）计 ¥100，2027 年（1~2 月）计 ¥20。

单元测试 `test/stats_engine_test.dart` 覆盖了年付平摊、季度合计、美元折算等场景，`flutter test` 可验证。

---

## 🔔 到期提醒说明
- 在「设置 → 到期提醒」开启，并选择提前天数（1/3/7/14 天）。
- 提醒在到期日前 N 天上午 10:00 触发本地通知。
- 采用 `inexactAllowWhileIdle` 排程，**无需 Android 精确闹钟权限**；iOS/macOS 首次运行会请求通知授权。
- 桌面平台若不支持定时通知会自动跳过，不影响其它功能。

---

## ☁️ 云同步（Supabase）
1. 在 [supabase.com](https://supabase.com) 新建项目，记下 `Project URL` 与 `anon public key`。
2. 在 SQL Editor 执行下方建表语句。
3. App「设置 → 云同步」填入 URL/key 并开启，重启后多端同账号互通。

```sql
create table categories (
  id text primary key, name text, emoji text,
  "colorValue" int8, "sortOrder" int8,
  "updatedAt" timestamptz, deleted bool
);
create table platforms (
  id text primary key, "categoryId" text, name text, emoji text,
  notes text, "updatedAt" timestamptz, deleted bool
);
create table subscriptions (
  id text primary key, "platformId" text, cycle text,
  amount float8, currency text,
  "startDate" timestamptz, "endDate" timestamptz,
  "autoRenew" bool, notes text, "updatedAt" timestamptz, deleted bool
);
```

> 当前为本地优先 + upsert 推送 + 启动拉取合并（last-write-wins）。字段级冲突合并与多用户 Auth 隔离为后续里程碑。

---

## 🗺️ 后续里程碑
- 数据导入/导出（JSON·CSV 备份）
- Supabase 多用户登录与端到端同步增强
- 实付视图（年付按付款月一次性计入）
- 浅色主题
