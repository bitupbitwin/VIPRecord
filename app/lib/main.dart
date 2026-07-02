import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local_store.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'theme/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = LocalStore();
  await store.init();

  final sync = SyncService();
  await sync.init(store.settings()); // 留空配置则仅本地

  final notif = NotificationService();
  await notif.init();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        syncServiceProvider.overrideWithValue(sync),
        notificationServiceProvider.overrideWithValue(notif),
      ],
      child: const SubOrbitApp(),
    ),
  );
}

class SubOrbitApp extends ConsumerStatefulWidget {
  const SubOrbitApp({super.key});

  @override
  ConsumerState<SubOrbitApp> createState() => _SubOrbitAppState();
}

class _SubOrbitAppState extends ConsumerState<SubOrbitApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(appProvider.notifier);
      // 启动后按现有订阅重排到期提醒。
      await notifier.rescheduleReminders();

      // 后台执行云端双向同步（拉取->合并->回推），不阻塞启动；
      // 若合并进了远端更新，刷新内存状态并重排提醒。
      final sync = ref.read(syncServiceProvider);
      final store = ref.read(localStoreProvider);
      final changed = await sync.fullSync(store);
      if (changed && mounted) {
        notifier.reloadFromStore();
        await notifier.rescheduleReminders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '订阅星轨 SubOrbit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // 中文本地化：日期选择器等系统组件显示中文。
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      locale: const Locale('zh'),
      home: const GlassBackground(child: HomeScreen()),
    );
  }
}
