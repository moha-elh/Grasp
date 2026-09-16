import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/notification_service.dart';

class NotifSettings {
  final bool enabled;
  final int hour;
  final int minute;
  const NotifSettings({this.enabled = false, this.hour = 20, this.minute = 0});

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  NotifSettings copyWith({bool? enabled, int? hour, int? minute}) => NotifSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

/// Daily-reminder settings, persisted and mirrored into the OS scheduler.
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotifSettings>(
        (_) => NotificationController());

class NotificationController extends StateNotifier<NotifSettings> {
  NotificationController() : super(const NotifSettings()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = NotifSettings(
      enabled: p.getBool(NotificationService.kEnabled) ?? false,
      hour: p.getInt(NotificationService.kHour) ?? 20,
      minute: p.getInt(NotificationService.kMinute) ?? 0,
    );
  }

  /// Turn the reminder on/off. Returns false if the OS permission was denied.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) return false;
      await NotificationService.scheduleDaily(state.time);
    } else {
      await NotificationService.cancel();
    }
    state = state.copyWith(enabled: value);
    await _persist();
    return true;
  }

  Future<void> setTime(TimeOfDay time) async {
    state = state.copyWith(hour: time.hour, minute: time.minute);
    await _persist();
    if (state.enabled) await NotificationService.scheduleDaily(time);
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(NotificationService.kEnabled, state.enabled);
    await p.setInt(NotificationService.kHour, state.hour);
    await p.setInt(NotificationService.kMinute, state.minute);
  }
}
