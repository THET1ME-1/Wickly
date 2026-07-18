import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_prefs.dart';
import '../l10n/strings.dart';

/// Напоминания писать и утренние воспоминания.
///
/// Всё локально: уведомления планирует сам телефон, сервера нет и быть не
/// может. Расписание живёт в настройках устройства ([AppPrefs]), а не в базе:
/// на ноутбуке и на телефоне человек хочет разное время.
class NotificationsService {
  const NotificationsService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Один канал на напоминания и один на воспоминания: так их можно отключать
  /// по отдельности в системных настройках Android.
  static const _dailyChannel = 'wickly_daily';
  static const _memoriesChannel = 'wickly_memories';

  static const _dailyIdBase = 100;
  static const _memoriesId = 200;

  static Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  /// Спрашивает разрешение на уведомления. Возвращает `false`, если человек
  /// отказал — тогда тумблер напоминаний надо вернуть обратно.
  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Перепланирует всё по текущим настройкам. Вызывается после любой правки
  /// расписания и на старте приложения.
  static Future<void> reschedule() async {
    await init();
    await cancelAll();

    final prefs = AppPrefs.instance;
    if (prefs.reminder) {
      for (final weekday in prefs.reminderDays) {
        await _scheduleWeekly(
          id: _dailyIdBase + weekday,
          weekday: weekday,
          time: prefs.reminderTime,
          channel: _dailyChannel,
          channelName: tr('reminder_daily'),
          title: tr('reminder_title'),
          body: tr('reminder_body'),
        );
      }
    }

    if (prefs.memories) {
      // Воспоминания приходят утром: вечером человек уже пишет сегодняшнее.
      await _scheduleDaily(
        id: _memoriesId,
        time: const TimeOfDay(hour: 9, minute: 0),
        channel: _memoriesChannel,
        channelName: tr('memories_morning'),
        title: tr('on_this_day'),
        body: tr('memories_push_body'),
      );
    }
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required TimeOfDay time,
    required String channel,
    required String channelName,
    required String title,
    required String body,
  }) async {
    var when = _nextInstanceOf(time);
    // Двигаем вперёд до нужного дня недели.
    while (when.weekday != weekday) {
      when = when.add(const Duration(days: 1));
    }
    await _schedule(
      id: id,
      when: when,
      channel: channel,
      channelName: channelName,
      title: title,
      body: body,
      match: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> _scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String channel,
    required String channelName,
    required String title,
    required String body,
  }) =>
      _schedule(
        id: id,
        when: _nextInstanceOf(time),
        channel: channel,
        channelName: channelName,
        title: title,
        body: body,
        match: DateTimeComponents.time,
      );

  static Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String channel,
    required String channelName,
    required String title,
    required String body,
    required DateTimeComponents match,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (_) {
      // Нет разрешения или системе не до нас — дневник работает и без
      // напоминаний, ронять приложение из-за них нельзя.
    }
  }

  static tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }
}
