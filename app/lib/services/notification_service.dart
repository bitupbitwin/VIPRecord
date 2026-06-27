import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/platform.dart';
import '../models/subscription.dart';

/// 到期本地提醒：在订阅期结束前 N 天发本地通知。
/// 桌面（Windows/macOS/Linux）与移动端均由 flutter_local_notifications 处理；
/// 不支持定时通知的平台会自动跳过，不影响其它功能。
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const linux =
          LinuxInitializationSettings(defaultActionName: '打开 SubOrbit');
      await _plugin.initialize(const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ));

      // 请求权限（iOS/macOS/Android 13+）。
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService 初始化失败（部分平台不支持定时通知）：$e');
      _ready = false;
    }
  }

  int _idFor(String subId) => subId.hashCode & 0x7fffffff;

  /// 按当前订阅列表重排所有提醒。
  Future<void> rescheduleAll({
    required List<Subscription> subs,
    required List<Platform> platforms,
    required bool enabled,
    required int leadDays,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    if (!enabled) return;

    final nameById = {for (final p in platforms) p.id: p.name};
    for (final s in subs) {
      if (s.deleted) continue;
      await _scheduleOne(s, nameById[s.platformId] ?? '订阅', leadDays);
    }
  }

  Future<void> _scheduleOne(
      Subscription s, String platformName, int leadDays) async {
    // 提醒时间 = 结束日期前 leadDays 天的上午 10:00。
    final fireDate = DateTime(
      s.endDate.year,
      s.endDate.month,
      s.endDate.day,
      10,
    ).subtract(Duration(days: leadDays));
    if (fireDate.isBefore(DateTime.now())) return; // 过期不再排

    final when = tz.TZDateTime.from(fireDate, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'suborbit_expiry',
        '订阅到期提醒',
        channelDescription: '会员订阅即将到期时提醒续费',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    final endStr =
        '${s.endDate.year}/${s.endDate.month}/${s.endDate.day}';
    try {
      await _plugin.zonedSchedule(
        _idFor(s.id),
        '「$platformName」会员即将到期',
        '$endStr 到期，记得确认是否续费（${s.cycle.label}）。',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('排程通知失败：$e');
    }
  }
}
