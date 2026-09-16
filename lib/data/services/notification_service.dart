import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A single local daily reminder to run the day's dose. Deliberately tiny: one
/// repeating notification, toggled and timed from Settings. Everything is
/// wrapped so a platform hiccup never takes the app down.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 100;
  static const _channel = 'daily_reminder';

  // Persisted settings keys (shared with NotificationController).
  static const kEnabled = 'notif_enabled';
  static const kHour = 'notif_hour';
  static const kMinute = 'notif_minute';

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to UTC; the reminder still fires, just at UTC-relative time.
    }
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
    } catch (_) {}
  }

  /// Ask for the Android 13+ notification permission. Returns whether granted.
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> scheduleDaily(TimeOfDay time) async {
    try {
      await cancel();
      await _plugin.zonedSchedule(
        _id,
        'Time for your daily dose',
        'A few minutes now keeps it in memory.',
        _nextInstance(time),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            'Daily reminder',
            channelDescription: 'Your daily review reminder',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancel() async {
    try {
      await _plugin.cancel(_id);
    } catch (_) {}
  }

  /// Re-arm the reminder from saved settings on app launch (Android clears
  /// alarms on reboot; opening the app rebuilds them).
  static Future<void> rescheduleFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(kEnabled) != true) return;
    await scheduleDaily(TimeOfDay(
      hour: p.getInt(kHour) ?? 20,
      minute: p.getInt(kMinute) ?? 0,
    ));
  }

  static tz.TZDateTime _nextInstance(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }
}
