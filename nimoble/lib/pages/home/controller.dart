import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_route.dart';
import '../alarm/controller.dart';
import '../settings/controller.dart';
import 'index.dart';

enum _BleManagerState {
  offline,
  connecting,
  online,
  disposed,
}

/// 设备连接管理器 - 管理单个设备的所有订阅和状态
class DeviceConnectionManager {
  final BluetoothDevice device;
  final DeviceInfo deviceInfo;
  final void Function(DeviceConnectionManager, DeviceInfo) onDataUpdate;
  final bool Function() shouldAutoReconnect;

  late StreamSubscription<BluetoothConnectionState> _connectionSub;
  late StreamSubscription<int> _mtuSub;
  final List<StreamSubscription<List<int>>> _notifySubs = [];

  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> services = [];
  BluetoothCharacteristic? notifyCharacteristic;
  int? mtuSize;
  bool isDiscoveringServices = false;

  _BleManagerState _state = _BleManagerState.offline;
  Timer? _runtimeTicker;
  Timer? _linkProbeTimer;
  Timer? _reconnectTimer;
  DateTime? _connectedAt;
  DateTime? _onlineSince;
  DateTime? _lastConnectedToastAt;
  DateTime? _lastDisconnectedToastAt;
  DateTime? _lastNotifyAt;
  int _lastRuntimeMinutes = -1;
  int _epoch = 0;
  int? _setupEpoch;
  bool _disposed = false;
  bool _setupRunning = false;
  bool _linkProbeRunning = false;
  bool _reconnectPassRunning = false;

  static const _linkProbeInterval = Duration(seconds: 1);
  static const _linkProbeTimeout = Duration(milliseconds: 800);
  static const _linkProbeSkipAfterNotify = Duration(milliseconds: 1500);
  static const _stableOnlineDelay = Duration(milliseconds: 1200);
  static const _cleanupTimeout = Duration(milliseconds: 800);
  static const _reconnectRetryDelay = Duration(seconds: 5);
  static const _toastThrottleWindow = Duration(seconds: 2);

  DeviceConnectionManager({
    required this.device,
    required this.deviceInfo,
    required this.onDataUpdate,
    required this.shouldAutoReconnect,
  }) {
    debugPrint('${deviceInfo.name}: DeviceConnectionManager created at ${_traceNow()}');
    _init();
  }

  void _init() {
    _connectionSub = device.connectionState.listen((state) {
      _handleConnectionState(state);
    });
    unawaited(device.connectionState.first.then((state) {
      _handleConnectionState(state);
    }));

    _mtuSub = device.mtu.listen((value) {
      if (_disposed) return;
      mtuSize = value;
    });
  }

  void requestReconnectPass() {
    if (_disposed || !shouldAutoReconnect()) return;
    if (_state == _BleManagerState.online ||
        connectionState == BluetoothConnectionState.connected) {
      return;
    }
    _scheduleReconnect(Duration.zero);
  }

  void _handleConnectionState(BluetoothConnectionState nextState) {
    if (_disposed) return;
    connectionState = nextState;
    debugPrint('${deviceInfo.name}: connectionState=$nextState at ${_traceNow()} state=$_state');

    if (nextState == BluetoothConnectionState.connected) {
      _markOnline('connectionState');
      return;
    }

    if (nextState == BluetoothConnectionState.disconnected) {
      _markOffline('connectionState');
    }
  }

  void _markOnline(String reason) {
    if (_disposed || _state == _BleManagerState.disposed) return;
    if (_state == _BleManagerState.online && deviceInfo.isConnected) return;

    final epoch = ++_epoch;
    _state = _BleManagerState.online;
    connectionState = BluetoothConnectionState.connected;
    _stopReconnectWork();

    final wasConnected = deviceInfo.isConnected;
    deviceInfo.isConnected = true;
    deviceInfo.lastConnectedTime = DateTime.now().toIso8601String();
    deviceInfo.hasBatteryReading = false;
    deviceInfo.hasPressureReading = false;
    _connectedAt = DateTime.now();
    _onlineSince = _connectedAt;
    _lastRuntimeMinutes = -1;
    _startRuntimeTicker();
    _startLinkProbe();
    onDataUpdate(this, deviceInfo);

    debugPrint('${deviceInfo.name}: UI online by $reason at ${_traceNow()}');
    if (!wasConnected) {
      _showConnectedToast();
    }

    services = [];
    unawaited(_setupServicesAsync(epoch));
  }

  void _markOffline(
    String reason, {
    bool cleanupBeforeReconnect = false,
    bool startReconnect = true,
  }) {
    if (_disposed || _state == _BleManagerState.disposed) return;

    final epoch = ++_epoch;
    _state = _BleManagerState.offline;
    connectionState = BluetoothConnectionState.disconnected;
    _stopLinkProbe();
    _stopRuntimeTicker();
    _setupRunning = false;
    _setupEpoch = null;
    _reconnectPassRunning = false;

    final wasConnected = deviceInfo.isConnected;
    deviceInfo.isConnected = false;
    deviceInfo.lastConnectedTime = DateTime.now().toIso8601String();
    if (wasConnected) {
      onDataUpdate(this, deviceInfo);
      debugPrint('${deviceInfo.name}: UI offline by $reason at ${_traceNow()}');
      _showDisconnectToast();
    }

    if (!startReconnect) return;

    if (cleanupBeforeReconnect) {
      unawaited(_cleanupThenReconnect(epoch, reason));
    } else {
      _scheduleReconnect(Duration.zero);
    }
  }

  Future<void> _cleanupThenReconnect(int epoch, String reason) async {
    debugPrint('${deviceInfo.name}: cleanup start by $reason at ${_traceNow()}');
    try {
      await device
          .disconnect(queue: false, androidDelay: 0)
          .timeout(_cleanupTimeout);
    } catch (e) {
      debugPrint('${deviceInfo.name}: cleanup ignored: $e');
    }
    if (_isStale(epoch)) return;
    debugPrint('${deviceInfo.name}: cleanup done at ${_traceNow()}');
    _scheduleReconnect(Duration.zero);
  }

  void _scheduleReconnect([Duration? delay]) {
    if (_disposed || !shouldAutoReconnect()) {
      _stopReconnectWork();
      return;
    }
    if (_state == _BleManagerState.online ||
        connectionState == BluetoothConnectionState.connected) {
      _stopReconnectWork();
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay ?? _reconnectRetryDelay, () {
      unawaited(_attemptAutoReconnect());
    });
  }

  Future<void> _attemptAutoReconnect() async {
    if (_disposed || !shouldAutoReconnect()) return;
    if (_reconnectPassRunning ||
        _state == _BleManagerState.online ||
        connectionState == BluetoothConnectionState.connected) {
      return;
    }

    final epoch = ++_epoch;
    _state = _BleManagerState.connecting;
    _reconnectPassRunning = true;
    debugPrint('${deviceInfo.name}: autoConnect request at ${_traceNow()}');
    try {
      await device.connect(autoConnect: true, mtu: null);
      if (_isStale(epoch)) return;
      if (connectionState != BluetoothConnectionState.connected) {
        _state = _BleManagerState.offline;
        _reconnectPassRunning = false;
        _scheduleReconnect();
      }
    } catch (e) {
      if (_isStale(epoch)) return;
      debugPrint('${deviceInfo.name}: autoConnect request failed: $e');
      _state = _BleManagerState.offline;
      _reconnectPassRunning = false;
      _scheduleReconnect(_reconnectRetryDelay);
    }
  }

  Future<void> _setupServicesAsync(int epoch) async {
    if (_setupRunning && _setupEpoch == epoch) return;
    _setupRunning = true;
    _setupEpoch = epoch;
    try {
      if (_isStale(epoch) ||
          connectionState != BluetoothConnectionState.connected) {
        return;
      }
      await discoverServices(epoch);
    } catch (e) {
      debugPrint('${deviceInfo.name}: init services failed: $e');
    } finally {
      if (_setupEpoch == epoch) {
        _setupRunning = false;
        _setupEpoch = null;
      }
    }
  }

  Future<void> discoverServices(int epoch) async {
    if (_isStale(epoch)) return;
    isDiscoveringServices = true;
    try {
      await _clearNotifySubscriptions();
      if (_isStale(epoch)) return;
      services = await device.discoverServices();
      if (_isStale(epoch)) return;
      debugPrint('${deviceInfo.name}: discovered ${services.length} services');

      for (final service in services) {
        for (final char in service.characteristics) {
          if (_isStale(epoch)) return;
          if (char.properties.notify || char.properties.indicate) {
            try {
              final sub = char.onValueReceived.listen((value) {
                if (_disposed) return;
                if (_isStale(epoch)) return;
                if (value.isNotEmpty) {
                  final receivedAt = DateTime.now();
                  _lastNotifyAt = receivedAt;
                  final charId = char.uuid.toString();
                  String? text;
                  try {
                    text = utf8.decode(value).trim();
                  } catch (_) {}
                  debugPrint(
                    '${deviceInfo.name}: BLE notify at ${receivedAt.toIso8601String()} '
                    'char=$charId bytes=${value.length} text=${text ?? '<binary>'}',
                  );
                  _parseDeviceData(value, charId, receivedAt: receivedAt);
                }
              });
              device.cancelWhenDisconnected(sub);
              _notifySubs.add(sub);
              await char.setNotifyValue(true);
            } catch (e) {
              debugPrint('${deviceInfo.name}: subscribe ${char.uuid} failed: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('${deviceInfo.name}: discover services error: $e');
    } finally {
      isDiscoveringServices = false;
    }
  }

  Future<void> _clearNotifySubscriptions() async {
    await Future.wait(_notifySubs.map((sub) => sub.cancel()));
    _notifySubs.clear();
  }

  void _parseDeviceData(
    List<int> value,
    String charUuid, {
    DateTime? receivedAt,
  }) {
    if (charUuid.toLowerCase().contains('2a19') && value.isNotEmpty) {
      deviceInfo.battery = value[0].clamp(0, 100);
      deviceInfo.hasBatteryReading = true;
      onDataUpdate(this, deviceInfo);
      return;
    }

    String? msg;
    try {
      msg = utf8.decode(value).trim();
    } catch (_) {}

    if (msg != null && msg.isNotEmpty) {
      if (_parseDeviceProtocol(msg, receivedAt: receivedAt)) return;

      try {
        final data = json.decode(msg) as Map<String, dynamic>?;
        if (data != null) {
          if (data.containsKey('battery')) {
            deviceInfo.battery = (data['battery'] ?? 0) as int;
            deviceInfo.hasBatteryReading = true;
          }
          if (data.containsKey('pressure')) {
            deviceInfo.pressure = (data['pressure'] ?? 0.0).toDouble();
            deviceInfo.hasPressureReading = true;
            _logPressureParsed(
              source: 'json',
              rawVac: data['pressure'],
              pressure: deviceInfo.pressure,
              receivedAt: receivedAt,
            );
          }
          onDataUpdate(this, deviceInfo);
          return;
        }
      } catch (_) {}
    }
  }

  bool _parseDeviceProtocol(String msg, {DateTime? receivedAt}) {
    final vacMatch = RegExp(
      r'Vac:([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(msg);
    final battMatch = RegExp(r'Batt:(\d+)', caseSensitive: false).firstMatch(msg);

    if (vacMatch == null && battMatch == null) return false;

    if (vacMatch != null) {
      final vacText = vacMatch.group(1)!;
      final vac = double.tryParse(vacText) ?? 0;
      deviceInfo.pressure = vacText.contains('.') ? vac : vac / 100.0;
      deviceInfo.hasPressureReading = true;
      _logPressureParsed(
        source: 'protocol',
        rawVac: vac,
        pressure: deviceInfo.pressure,
        receivedAt: receivedAt,
      );
    }

    if (battMatch != null) {
      final battMv = int.tryParse(battMatch.group(1)!) ?? 0;
      deviceInfo.battery = _batteryMvToPercent(battMv);
      deviceInfo.hasBatteryReading = true;
    }

    onDataUpdate(this, deviceInfo);
    return true;
  }

  void _logPressureParsed({
    required String source,
    required Object? rawVac,
    required double pressure,
    DateTime? receivedAt,
  }) {
    final now = DateTime.now();
    final latencyMs = receivedAt == null
        ? null
        : now.difference(receivedAt).inMilliseconds;
    debugPrint(
      '${deviceInfo.name}: pressure parsed at ${now.toIso8601String()} '
      'source=$source raw=$rawVac pressure=$pressure latencyMs=${latencyMs ?? '-'}',
    );
  }

  static int _batteryMvToPercent(int mV) {
    const minMv = 3000;
    const maxMv = 4200;
    return ((mV - minMv) / (maxMv - minMv) * 100).round().clamp(0, 100);
  }

  void _startRuntimeTicker() {
    _runtimeTicker?.cancel();
    _runtimeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || _state != _BleManagerState.online) return;
      final connectedAt = _connectedAt;
      if (connectedAt == null) return;
      final minutes = DateTime.now().difference(connectedAt).inMinutes;
      if (minutes != _lastRuntimeMinutes) {
        _lastRuntimeMinutes = minutes;
        deviceInfo.runtime = minutes;
        onDataUpdate(this, deviceInfo);
      }
    });
  }

  void _stopRuntimeTicker() {
    _runtimeTicker?.cancel();
    _runtimeTicker = null;
  }

  Future<void> requestMtu() async {
    try {
      await device.requestMtu(223, predelay: 0);
    } catch (e) {
      debugPrint('${deviceInfo.name}: request MTU error: $e');
    }
  }

  void _startLinkProbe() {
    _stopLinkProbe();
    _linkProbeTimer = Timer.periodic(_linkProbeInterval, (_) {
      unawaited(_runLinkProbe());
    });
  }

  void _stopLinkProbe() {
    _linkProbeTimer?.cancel();
    _linkProbeTimer = null;
    _linkProbeRunning = false;
  }

  Future<void> _runLinkProbe() async {
    if (_disposed || _linkProbeRunning) return;
    if (_state != _BleManagerState.online) return;
    if (!_isStableOnline) return;

    _linkProbeRunning = true;
    final epoch = _epoch;
    try {
      if (_isStale(epoch) || _state != _BleManagerState.online) return;
      final lastNotifyAt = _lastNotifyAt;
      if (lastNotifyAt != null &&
          DateTime.now().difference(lastNotifyAt) < _linkProbeSkipAfterNotify) {
        return;
      }
      await device.readRssi().timeout(_linkProbeTimeout);
    } catch (e) {
      if (!_isStale(epoch) && _state == _BleManagerState.online) {
        debugPrint('${deviceInfo.name}: probe stale at ${_traceNow()}: $e');
        _markOffline('linkProbe', cleanupBeforeReconnect: true);
      }
    } finally {
      _linkProbeRunning = false;
    }
  }

  bool get _isStableOnline {
    final onlineSince = _onlineSince;
    if (onlineSince == null) return false;
    return DateTime.now().difference(onlineSince) >= _stableOnlineDelay;
  }

  bool _isStale(int epoch) => _disposed || epoch != _epoch;

  void _stopReconnectWork() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectPassRunning = false;
  }

  void _showDisconnectToast() {
    final now = DateTime.now();
    final last = _lastDisconnectedToastAt;
    if (last != null && now.difference(last) < _toastThrottleWindow) return;
    _lastDisconnectedToastAt = now;
    EasyLoading.showToast('${deviceInfo.name} 已断开');
  }

  void _showConnectedToast() {
    final now = DateTime.now();
    final last = _lastConnectedToastAt;
    if (last != null && now.difference(last) < _toastThrottleWindow) return;
    _lastConnectedToastAt = now;
    EasyLoading.showToast('${deviceInfo.name} 已连接');
  }

  String _traceNow() => DateTime.now().toIso8601String();

  Future<void> disconnect() async {
    debugPrint('${deviceInfo.name}: DeviceConnectionManager disconnect at ${_traceNow()}');
    _disposed = true;
    _state = _BleManagerState.disposed;
    _epoch += 1;
    _stopReconnectWork();
    _stopRuntimeTicker();
    _stopLinkProbe();
    await _clearNotifySubscriptions();
    await _connectionSub.cancel();
    await _mtuSub.cancel();
    try {
      await device.disconnect(queue: false, androidDelay: 0).timeout(_cleanupTimeout);
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    _state = _BleManagerState.disposed;
    _epoch += 1;
    _stopReconnectWork();
    _stopRuntimeTicker();
    _stopLinkProbe();
    await _clearNotifySubscriptions();
    await _connectionSub.cancel();
    await _mtuSub.cancel();
    debugPrint('${deviceInfo.name}: DeviceConnectionManager disposed at ${_traceNow()}');
  }
}

class HomeController extends GetxController {
  HomeController();

  final state = HomeState();

  // 本地存储
  final _storage = GetStorage();
  static const String _historyKey = 'device_history';
  static const String _connectedDevicesKey = 'connected_devices';

  // 已连接设备管理器列表
  final Map<String, DeviceConnectionManager> _connectedManagers = {};
  final Set<String> _removedDevices = <String>{};

  // 当前已连接的设备列表（RxList用于响应式更新）
  final RxList<DeviceInfo> connectedDevices = <DeviceInfo>[].obs;

  // 蓝牙适配器状态监听
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

  // 用于UI显示的设备列表（响应式，合并已连接和历史记录）
  final RxList<DeviceInfo> displayDevices = <DeviceInfo>[].obs;

  bool get _autoConnectEnabled {
    if (!Get.isRegistered<SettingsController>()) {
      return true;
    }
    return Get.find<SettingsController>().autoConnectEnabled;
  }

  bool get _isHistoryReconnectRoute {
    final route = Get.currentRoute;
    return route == AppRoutes.HOME || route == AppRoutes.DEVICE_DETAILS;
  }

  bool get _allowHistoryReconnect {
    return _autoConnectEnabled && _isHistoryReconnectRoute;
  }

  @override
  void onInit() {
    super.onInit();
    try {
      _loadHistoryDevices();

      // 接收从扫描页面传来的设备
      var params = Get.arguments;
      if (params != null && params[ParamKeys.BLE_DEVICE_ITEM] != null) {
        final BluetoothDevice newDevice = params[ParamKeys.BLE_DEVICE_ITEM];
        _addNewDevice(newDevice);
      }

      // 监听connectedDevices变化，自动更新displayDevices
      ever(connectedDevices, (_) => _updateDisplayDevices());
      // 监听historyDevices变化，自动更新displayDevices
      ever(state.historyDevices, (_) => _updateDisplayDevices());

      // 初始更新一次displayDevices
      _updateDisplayDevices();

      // 自动检测并连接历史设备
      _autoConnectHistoryDevices();
    } catch (e, stackTrace) {
      debugPrint("HomeController onInit 错误: $e");
      debugPrint("StackTrace: $stackTrace");
    }
  }

  /// 更新displayDevices（合并已连接和历史记录，去重）
  void _updateDisplayDevices() {
    final List<DeviceInfo> result = [];
    result.addAll(connectedDevices);

    for (var historyDevice in state.historyDevices) {
      bool isDuplicate = result.any((d) => d.macAddress == historyDevice.macAddress);
      if (!isDuplicate) {
        result.add(historyDevice);
      }
    }

    result.sort((a, b) {
      if (a.isConnected == b.isConnected) return 0;
      return a.isConnected ? -1 : 1;
    });

    displayDevices.assignAll(result);
    debugPrint("displayDevices已更新: ${result.length}个设备");
  }

  @override
  void onClose() {
    super.onClose();
    debugPrint("HomeController onClose: 清理资源...");

    // 取消蓝牙适配器监听
    _adapterStateSub?.cancel();
    _adapterStateSub = null;

    // 断开所有设备并清理管理器
    for (final manager in _connectedManagers.values) {
      manager.disconnect();
    }
    _connectedManagers.clear();

    debugPrint("HomeController onClose: 资源已清理");
  }

  /// 自动检测并连接历史设备（使用 autoConnect，避免持续扫描）
  void _autoConnectHistoryDevices() async {
    debugPrint("开始 autoConnect 历史设备...");
    _adapterStateSub = FlutterBluePlus.adapterState.listen((adapterState) {
      if (adapterState == BluetoothAdapterState.on && _allowHistoryReconnect) {
        _connectAllHistoryDevicesWithAutoConnect();
      }
    });

    final currentState = await FlutterBluePlus.adapterState.first;
    if (currentState == BluetoothAdapterState.on && _allowHistoryReconnect) {
      _connectAllHistoryDevicesWithAutoConnect();
    }
  }

  Future<void> _connectAllHistoryDevicesWithAutoConnect({bool force = false}) async {
    if (!_autoConnectEnabled) return;
    if (!force && !_isHistoryReconnectRoute) return;
    final snapshot = List<DeviceInfo>.from(state.historyDevices);
    for (final historyDevice in snapshot) {
      if (!state.historyDevices.any((d) => d.macAddress == historyDevice.macAddress)) {
        continue;
      }
      await _ensureManagerAndAutoConnect(historyDevice);
    }
  }

  Future<void> _ensureManagerAndAutoConnect(DeviceInfo deviceInfo) async {
    final macAddress = deviceInfo.macAddress;
    if (macAddress.isEmpty) {
      return;
    }

    final existingManager = _connectedManagers[macAddress];
    if (existingManager != null) {
      if (_autoConnectEnabled) {
        existingManager.requestReconnectPass();
      }
      return;
    }

    final device = BluetoothDevice.fromId(macAddress);
    final manager = _createManager(device, deviceInfo);
    if (_autoConnectEnabled) {
      manager.requestReconnectPass();
    }
  }

  Future<void> requestReconnectPass() async {
    await _connectAllHistoryDevicesWithAutoConnect(force: true);
  }

  /// 下拉刷新 - 供View层调用（autoConnect 架构下仅重试历史设备连接请求）
  Future<void> onRefresh() async {
    await _connectAllHistoryDevicesWithAutoConnect();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  DeviceConnectionManager _createManager(BluetoothDevice device, DeviceInfo deviceInfo) {
    final macAddress = device.remoteId.toString();
    final oldManager = _connectedManagers.remove(macAddress);
    if (oldManager != null) {
      unawaited(oldManager.dispose());
    }
    final manager = DeviceConnectionManager(
      device: device,
      deviceInfo: deviceInfo,
      onDataUpdate: _handleDeviceDataUpdate,
      shouldAutoReconnect: () => _allowHistoryReconnect,
    );
    _connectedManagers[macAddress] = manager;
    return manager;
  }

  void _handleDeviceDataUpdate(
    DeviceConnectionManager manager,
    DeviceInfo updatedInfo,
  ) {
    if (_removedDevices.contains(updatedInfo.macAddress)) return;
    if (_connectedManagers[updatedInfo.macAddress] != manager) return;

    final index = connectedDevices.indexWhere((d) => d.macAddress == updatedInfo.macAddress);
    if (index < 0) {
      if (updatedInfo.hasPressureReading) {
        debugPrint(
          '${updatedInfo.name}: Home pressure insert at '
          '${DateTime.now().toIso8601String()} pressure=${updatedInfo.pressure}',
        );
      }
      connectedDevices.add(updatedInfo);
      connectedDevices.refresh();
      _saveToHistory(updatedInfo);
      if (Get.isRegistered<AlarmController>()) {
        Get.find<AlarmController>().evaluateDevice(updatedInfo);
      }
      return;
    }

    final device = connectedDevices[index];
    device.isConnected = updatedInfo.isConnected;
    device.name = updatedInfo.name;
    device.description = updatedInfo.description;
    device.battery = updatedInfo.battery;
    device.pressure = updatedInfo.pressure;
    device.runtime = updatedInfo.runtime;
    device.hasBatteryReading = updatedInfo.hasBatteryReading;
    device.hasPressureReading = updatedInfo.hasPressureReading;
    device.lastConnectedTime = updatedInfo.lastConnectedTime;
    connectedDevices[index] = device;
    connectedDevices.refresh();
    if (updatedInfo.hasPressureReading) {
      debugPrint(
        '${updatedInfo.name}: Home pressure update at '
        '${DateTime.now().toIso8601String()} pressure=${updatedInfo.pressure}',
      );
    }
    _saveToHistory(device);
    if (Get.isRegistered<AlarmController>()) {
      Get.find<AlarmController>().evaluateDevice(device);
    }
    debugPrint("数据更新: ${updatedInfo.name} - 电量:${updatedInfo.battery}%, 真空:${updatedInfo.pressure}Bar, 运行:${updatedInfo.runtime}min");
  }

  /// 更新设备连接状态（只改状态不移除）
  void _updateDeviceConnectionState(String macAddress, bool isConnected) {
    final index = connectedDevices.indexWhere((d) => d.macAddress == macAddress);
    if (index >= 0) {
      final device = connectedDevices[index];
      device.isConnected = isConnected;
      device.lastConnectedTime = DateTime.now().toIso8601String();
      connectedDevices[index] = device;
      connectedDevices.refresh();
      _saveToHistory(device);
      if (!isConnected && Get.isRegistered<AlarmController>()) {
        Get.find<AlarmController>().clearDevice(macAddress);
      }
    }
    final historyIndex = state.historyDevices.indexWhere((d) => d.macAddress == macAddress);
    if (historyIndex >= 0) {
      final historyDevice = state.historyDevices[historyIndex];
      historyDevice.isConnected = isConnected;
      historyDevice.lastConnectedTime = DateTime.now().toIso8601String();
      state.historyDevices[historyIndex] = historyDevice;
      state.historyDevices.refresh();
    }
    _saveConnectedDevices();
  }

  /// 添加新设备并连接
  void _addNewDevice(BluetoothDevice device) {
    final macAddress = device.remoteId.toString();
    _removedDevices.remove(macAddress);

    final existingManager = _connectedManagers[macAddress];
    if (existingManager != null &&
        existingManager.connectionState == BluetoothConnectionState.connected) {
      EasyLoading.showToast("该设备已连接");
      return;
    }
    if (existingManager != null) {
      _connectedManagers.remove(macAddress);
      unawaited(existingManager.dispose());
    }

    // 检查列表中是否已存在该设备
    final existingIndex = connectedDevices.indexWhere((d) => d.macAddress == macAddress);

    final deviceInfo = DeviceInfo(
      name: device.platformName.isEmpty ? 'Unknown Device' : device.platformName,
      description: existingIndex >= 0 ? connectedDevices[existingIndex].description : '',
      macAddress: macAddress,
      battery: existingIndex >= 0 ? connectedDevices[existingIndex].battery : 0,
      pressure: existingIndex >= 0 ? connectedDevices[existingIndex].pressure : 0.0,
      hasBatteryReading:
          existingIndex >= 0 ? connectedDevices[existingIndex].hasBatteryReading : false,
      hasPressureReading:
          existingIndex >= 0 ? connectedDevices[existingIndex].hasPressureReading : false,
      isConnected: false,
      lastConnectedTime: DateTime.now().toIso8601String(),
    );

    _createManager(device, deviceInfo);

    if (existingIndex >= 0) {
      // 已存在，更新现有项
      connectedDevices[existingIndex] = deviceInfo;
    } else {
      // 不存在，添加新项
      connectedDevices.add(deviceInfo);
    }
    // 强制刷新列表
    connectedDevices.refresh();

    // 保存到历史记录
    _saveToHistory(deviceInfo);
    _saveConnectedDevices();
  }

  /// 从外部添加设备（用于扫描页面的自动连接）
  void addDevice(BluetoothDevice device) {
    _addNewDevice(device);
  }

  /// 获取所有已连接设备的MAC地址列表
  List<String> getConnectedDeviceMacs() {
    return _connectedManagers.keys.toList();
  }

  /// 检查设备是否已连接
  bool isDeviceConnected(String macAddress) {
    final manager = _connectedManagers[macAddress];
    return manager != null && manager.connectionState == BluetoothConnectionState.connected;
  }

  /// 检查设备是否在当前连接列表中（无论是否已连接）
  bool isDeviceInConnections(String macAddress) {
    return _connectedManagers.containsKey(macAddress);
  }

  /// 断开指定设备的连接（手动断开时也保留在列表，只改状态）
  Future<void> disconnectDevice(String macAddress) async {
    final manager = _connectedManagers[macAddress];
    if (manager != null) {
      await manager.disconnect();
      _connectedManagers.remove(macAddress);
      _updateDeviceConnectionState(macAddress, false);
    }
  }

  Future<void> renameDevice(String macAddress, String name, String description) async {
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();
    if (trimmedName.isEmpty) return;

    final connectedIndex = connectedDevices.indexWhere((d) => d.macAddress == macAddress);
    if (connectedIndex >= 0) {
      connectedDevices[connectedIndex].name = trimmedName;
      connectedDevices[connectedIndex].description = trimmedDescription;
      connectedDevices[connectedIndex] = connectedDevices[connectedIndex];
    }

    final historyIndex = state.historyDevices.indexWhere((d) => d.macAddress == macAddress);
    if (historyIndex >= 0) {
      state.historyDevices[historyIndex].name = trimmedName;
      state.historyDevices[historyIndex].description = trimmedDescription;
      state.historyDevices[historyIndex] = state.historyDevices[historyIndex];
    }

    _saveConnectedDevices();
    _saveHistoryDevices();
  }

  Future<void> removeDevice(String macAddress) async {
    _removedDevices.add(macAddress);
    final manager = _connectedManagers[macAddress];
    if (manager != null) {
      await manager.disconnect();
      _connectedManagers.remove(macAddress);
    }

    connectedDevices.removeWhere((d) => d.macAddress == macAddress);
    state.historyDevices.removeWhere((d) => d.macAddress == macAddress);

    _saveConnectedDevices();
    _saveHistoryDevices();
  }

  /// 断开所有设备（只更新状态，不移除列表）
  Future<void> disconnectAll() async {
    final List<String> macList = _connectedManagers.keys.toList();
    for (var mac in macList) {
      final manager = _connectedManagers[mac];
      if (manager != null) {
        await manager.disconnect();
      }
      _connectedManagers.remove(mac);
    }
    // 只更新状态，不清空列表
    for (var mac in macList) {
      _updateDeviceConnectionState(mac, false);
    }
  }

  /// 加载历史设备记录
  void _loadHistoryDevices() {
    try {
      final List<dynamic>? stored = _storage.read(_historyKey);
      if (stored != null) {
        state.historyDevices.value = stored.map((item) {
          if (item is Map) {
            return DeviceInfo(
              name: item['name']?.toString() ?? 'Unknown',
              description: item['description']?.toString() ?? '',
              macAddress: item['macAddress']?.toString() ?? '',
              battery: (item['battery'] as num?)?.toInt() ?? 0,
              pressure: (item['pressure'] as num?)?.toDouble() ?? 0.0,
              runtime: (item['runtime'] as num?)?.toInt() ?? 0,
              isConnected: false,
              lastConnectedTime: item['lastConnectedTime']?.toString(),
            );
          }
          return DeviceInfo(name: 'Unknown', macAddress: '');
        }).toList();
      }
      debugPrint("加载历史记录: ${state.historyDevices.length} 个设备");
    } catch (e, stackTrace) {
      debugPrint("加载历史记录失败: $e");
      debugPrint("StackTrace: $stackTrace");
      // 出错时清空历史记录，避免影响页面显示
      state.historyDevices.clear();
    }
  }

  /// 保存已连接设备MAC列表
  void _saveConnectedDevices() {
    try {
      _storage.write(_connectedDevicesKey, _connectedManagers.keys.toList());
    } catch (e) {
      debugPrint("保存连接设备失败: $e");
    }
  }

  /// 保存设备到历史记录
  void _saveToHistory(DeviceInfo deviceInfo) {
    try {
      final existingIndex = state.historyDevices.indexWhere(
            (d) => d.macAddress == deviceInfo.macAddress,
      );

      if (existingIndex >= 0) {
        state.historyDevices[existingIndex] = deviceInfo;
      } else {
        state.historyDevices.add(deviceInfo);
      }

      _saveHistoryDevices();
    } catch (e) {
      debugPrint("保存历史记录失败: $e");
    }
  }

  void _saveHistoryDevices() {
    _storage.write(_historyKey, state.historyDevices.map((d) => {
      'name': d.name,
      'description': d.description,
      'macAddress': d.macAddress,
      'battery': d.battery,
      'pressure': d.pressure,
      'runtime': d.runtime,
      'lastConnectedTime': d.lastConnectedTime,
    }).toList());
  }

  /// 调试打印所有服务
  Future<void> debugPrintAllServices(String macAddress) async {
    final manager = _connectedManagers[macAddress];
    if (manager == null) return;

    debugPrint("========== 设备 ${manager.deviceInfo.name} 的服务和特征值 ==========");
    await manager.device.discoverServices();

    for (var service in manager.services) {
      debugPrint("\n📦 Service: ${service.uuid}");
      for (var char in service.characteristics) {
        debugPrint("  └── Characteristic: ${char.uuid}");
        debugPrint("      ├── 可读: ${char.properties.read}");
        debugPrint("      ├── 可写: ${char.properties.write}");
        debugPrint("      ├── 可通知: ${char.properties.notify}");
        debugPrint("      └── 可指示: ${char.properties.indicate}");
      }
    }
    debugPrint("========== 打印结束 ==========");
  }

  @override
  Future<void> dispose() async {
    await _adapterStateSub?.cancel();
    // 断开所有设备连接并释放GATT资源
    for (var manager in _connectedManagers.values) {
      await manager.disconnect(); // 使用disconnect()而非dispose()，确保释放GATT
    }
    _connectedManagers.clear();
    super.dispose();
  }
}
