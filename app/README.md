# 订阅星轨 · SubOrbit

跨平台（手机 + 电脑）会员订阅记账。毛玻璃 UI，以时间线分摊统计月/季/年支出，
人民币⇄美元双框联动，支持云同步。

## 技术栈
- **Flutter**（一套代码 → Android / iOS / Windows / macOS / Linux / Web）
- **Riverpod** 响应式状态：改数值，统计实时刷新
- **Hive** 本地优先存储（纯 Dart，全平台通用）
- **fl_chart** 图表 · **Supabase** 云同步

## 目录
```
lib/
  models/      数据模型（分类 / 平台 / 订阅 / 设置 / 枚举）
  data/        本地存储 + 预置 38 平台种子数据
  services/    统计引擎 · 汇率换算 · 云同步
  providers/   Riverpod 状态
  theme/       毛玻璃设计系统
  widgets/     双币种联动输入
  screens/     首页 / 分类详情 / 订阅编辑 / 设置
```

## 运行
本仓库只含 `lib/` 与 `pubspec.yaml`。首次构建需生成各平台工程：

```bash
cd app
flutter create .          # 生成 android/ ios/ windows/ macos/ linux/ web 工程（保留 lib 与 pubspec）
flutter pub get
flutter run               # 手机/桌面调试
# 打包示例
flutter build apk         # Android
flutter build windows     # Windows 桌面
flutter build macos       # macOS 桌面
flutter build web         # 网页版（电脑浏览器“安装到桌面”即 PWA）
```

## 核心统计口径
每条订阅「月均成本 = 折算 CNY 金额 ÷ 周期月数」（年付÷12、季付÷3、月付÷1），
分摊到订阅期覆盖的每个自然月；月度→季度→年度逐级汇总，天然支持非连续订阅。

## 云同步（Supabase）
1. 在 [supabase.com](https://supabase.com) 建项目，拿到 `URL` 和 `anon key`；
2. 在 SQL Editor 执行下方建表语句；
3. App「设置 → 云同步」填入 URL/key 并开启，多端同账号即互通。

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

> 注：当前为 M1–M3 基础版（本地优先 + 单向 upsert 推送 + 启动拉取合并）。
> 字段级冲突合并、Auth 多用户隔离、到期提醒为后续里程碑。
