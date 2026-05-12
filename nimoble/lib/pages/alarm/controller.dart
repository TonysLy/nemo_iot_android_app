import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../routes/app_route.dart';
import '../home/state.dart';
import '../settings/controller.dart';

enum DeviceAlarmType {
  lowVacuum,
  lowBattery,
}

class AlarmController extends GetxController with WidgetsBindingObserver {
  static const double lowVacuumThresholdBar = 0.48;
  static const int lowBatteryThresholdPercent = 20;
  static const String lowVacuumMessage =
      'Low vacuum value, this is an unsafe state, please find the cause and resolve it before use.';
  static const String lowBatteryMessage =
      'The battery is low, please charge it as soon as possible.';

  static const String _channelId = 'device_alarm_channel_v2';
  static const String _channelName = 'Device alarms';
  static const String _channelDescription = 'Safety alerts for connected devices';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Map<String, Set<DeviceAlarmType>> _activeAlarms = {};
  final Random _random = Random();
  int _notificationId = 1000;
  bool _initialized = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  Future<void> _notificationQueue = Future.value();

  bool get _isForeground => _lifecycleState == AppLifecycleState.resumed;

  Future<void> initNotifications() async {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) => _openHome(),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<bool> requestNotificationPermission() async {
    await initNotifications();
    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return androidResult ?? true;
  }

  void evaluateDevice(DeviceInfo device) {
    if (!device.isConnected) {
      clearDevice(device.macAddress);
      return;
    }

    final lowVacuum =
        device.hasPressureReading && device.pressure < lowVacuumThresholdBar;
    final lowBattery = device.hasBatteryReading &&
        device.battery < lowBatteryThresholdPercent;
    debugPrint(
      'Alarm evaluate: ${device.name} connected=${device.isConnected} '
      'pressure=${device.pressure} hasPressure=${device.hasPressureReading} '
      'battery=${device.battery} hasBattery=${device.hasBatteryReading} '
      'lowVacuum=$lowVacuum lowBattery=$lowBattery',
    );
    final active = _activeAlarms.putIfAbsent(
      device.macAddress,
      () => <DeviceAlarmType>{},
    );

    if (!lowVacuum) active.remove(DeviceAlarmType.lowVacuum);
    if (!lowBattery) active.remove(DeviceAlarmType.lowBattery);

    final newlyTriggered = <DeviceAlarmType>[];
    if (lowVacuum && !active.contains(DeviceAlarmType.lowVacuum)) {
      newlyTriggered.add(DeviceAlarmType.lowVacuum);
    }
    if (lowBattery && !active.contains(DeviceAlarmType.lowBattery)) {
      newlyTriggered.add(DeviceAlarmType.lowBattery);
    }

    if (newlyTriggered.length > 1) {
      newlyTriggered.shuffle(_random);
    }

    for (final type in newlyTriggered) {
      active.add(type);
      _notificationQueue = _notificationQueue.then(
        (_) => _notify(device, type),
      );
    }

    if (active.isEmpty) {
      _activeAlarms.remove(device.macAddress);
    }
  }

  void clearDevice(String macAddress) {
    _activeAlarms.remove(macAddress);
  }

  Future<void> _notify(DeviceInfo device, DeviceAlarmType type) async {
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    if (settings?.alarmAlertsEnabled == false) {
      debugPrint('Alarm notify skipped: alerts disabled');
      return;
    }
    await initNotifications();
    final granted = await requestNotificationPermission();
    if (!granted) {
      debugPrint('Alarm notify skipped: permission denied');
      return;
    }

    final message = _messageFor(type);
    final title = device.name.isEmpty ? 'Device Alarm' : device.name;

    await _notifications.show(
      _notificationId++,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[0, 400, 200, 400]),
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: AppRoutes.HOME,
    );
    debugPrint('Alarm notify shown: $title $type');
  }

  String _messageFor(DeviceAlarmType type) {
    return type == DeviceAlarmType.lowVacuum
        ? lowVacuumMessage
        : lowBatteryMessage;
  }

  void _openHome() {
    if (Get.currentRoute == AppRoutes.HOME) return;
    Get.offAllNamed(AppRoutes.HOME);
  }
}
