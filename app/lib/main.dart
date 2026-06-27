import 'package:flutter/material.dart';
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
    // 启动后按现有订阅重排到期提醒。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appProvider.notifier).rescheduleReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '订阅星轨 SubOrbit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const GlassBackground(child: HomeScreen()),
    );
  }
}
