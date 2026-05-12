import 'package:get/get.dart';

class DeviceDetailsState {
  // 弹窗显示状态
  final isMenuOpen = false.obs;

  // 选中的菜单项（0=Rename, 1=Remove Device）
  final selectedMenuIndex = (-1).obs;

  // 实时数据（从蓝牙更新）
  final deviceName = ''.obs; // 设备名称
  final pressure = 0.0.obs; // 真空值 0-0.65bar
  final battery = 0.obs; // 电量 0-100
  final runtime = 0.obs; // 运行时间（分钟）
  final description = ''.obs; // 设备描述
  final isConnected = false.obs; // 连接状态
}
