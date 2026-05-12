import 'package:get/get.dart';

class DeviceInfo {
  String name;
  String description;
  String macAddress;
  int battery;
  double pressure;
  int runtime;
  bool hasBatteryReading;
  bool hasPressureReading;
  bool isConnected;
  String? lastConnectedTime;

  DeviceInfo({
    required this.name,
    this.description = '',
    required this.macAddress,
    this.battery = 0,
    this.pressure = 0.0,
    this.runtime = 0,
    this.hasBatteryReading = false,
    this.hasPressureReading = false,
    this.isConnected = false,
    this.lastConnectedTime,
  });
}

class HomeState {
  final _title = "My Devices".obs;
  set title(value) => _title.value = value;
  get title => _title.value;

  final RxList<DeviceInfo> connectedDevices = <DeviceInfo>[].obs;
  final RxList<DeviceInfo> historyDevices = <DeviceInfo>[].obs;
  final RxInt selectedIndex = (-1).obs;
}
