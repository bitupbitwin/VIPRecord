import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local_store.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'services/sync_service.dart';
import 'theme/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = LocalStore();
  await store.init();

  final sync = SyncService();
  await sync.init(store.settings()); // 留空配置则仅本地

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        syncServiceProvider.overrideWithValue(sync),
      ],
      child: const SubOrbitApp(),
    ),
  );
}

class SubOrbitApp extends StatelessWidget {
  const SubOrbitApp({super.key});

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
