import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pages/home/index.dart';
import '../../routes/app_route.dart';
import 'index.dart';

class DeviceDetailsController extends GetxController {
  DeviceDetailsController();

  final state = DeviceDetailsState();
  DeviceInfo? deviceInfo;
  Worker? _dataWorker;

  // 菜单显示/隐藏切换
  void toggleMenu() {
    state.isMenuOpen.value = !state.isMenuOpen.value;
    state.selectedMenuIndex.value = -1; // 重置选中状态
  }

  // 隐藏菜单
  void hideMenu() {
    state.isMenuOpen.value = false;
    state.selectedMenuIndex.value = -1;
  }

  // 菜单项点击
  void onMenuItemTap(int index) {
    state.selectedMenuIndex.value = index;
    if (index == 0) {
      // Rename
      showRenameDialog();
    } else if (index == 1) {
      // Remove Device
      showRemoveDialog();
    }
    hideMenu();
  }

  // 显示重命名对话框
  void showRenameDialog() {
    final nameController = TextEditingController(text: deviceInfo?.name ?? '');
    final descriptionController =
        TextEditingController(text: deviceInfo?.description ?? state.description.value);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2A4F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  const Text(
                    'Rename Device',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Device Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Description', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              _buildDialogButton(
                text: 'Save',
                onTap: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final description = descriptionController.text.trim();
                  final macAddress = deviceInfo?.macAddress;
                  if (macAddress != null && macAddress.isNotEmpty) {
                    final homeController = Get.find<HomeController>();
                    await homeController.renameDevice(macAddress, name, description);
                  }
                  deviceInfo?.name = name;
                  deviceInfo?.description = description;
                  state.deviceName.value = name;
                  state.description.value = description;
                  Get.back();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogButton(
                text: 'Cancel',
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示移除设备对话框
  void showRemoveDialog() {
    final deviceName = deviceInfo?.name ?? 'Device';
    final macAddress = deviceInfo?.macAddress;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D4E8B), Color(0xFF0A3D6B)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Remove this device?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '"$deviceName" will be removed from your devices. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 22),
              _buildDialogButton(
                text: 'Remove',
                onTap: () async {
                  if (macAddress != null && macAddress.isNotEmpty) {
                    final homeController = Get.find<HomeController>();
                    await homeController.removeDevice(macAddress);
                  }
                  if (Get.isBottomSheetOpen ?? false) {
                    Get.back();
                  }
                  if (Get.currentRoute == AppRoutes.DEVICE_DETAILS) {
                    Get.back();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildDialogButton(
                text: 'Cancel',
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// 获取真空值状态颜色（0-0.48红色，0.48以上绿色）
  Color getPressureColor() {
    final pressure = state.pressure.value;
    if (pressure <= 0.48) return const Color(0xFFFF4444); // 红色 Bad
    return const Color(0xFF00C853); // 绿色 Good
  }

  /// 获取真空值状态文字
  String getPressureStatus() {
    final pressure = state.pressure.value;
    if (pressure <= 0.48) return 'Bad';
    return 'Good';
  }

  /// 获取弧形指示器进度（0-0.65bar映射到0.0-1.0）
  double getIndicatorProgress() {
    final pressure = state.pressure.value;
    return (pressure / 0.65).clamp(0.0, 1.0);
  }

  @override
  void onInit() {
    super.onInit();
    var params = Get.arguments;
    if (params != null && params[ParamKeys.BLE_MSG] is DeviceInfo) {
      deviceInfo = params[ParamKeys.BLE_MSG] as DeviceInfo;
      _syncFromDeviceInfo(deviceInfo!);
      _listenToRealtimeUpdates();
    }
  }

  /// 从 DeviceInfo 同步数据到 state
  void _syncFromDeviceInfo(DeviceInfo info) {
    state.deviceName.value = info.name;
    state.pressure.value = info.pressure;
    state.battery.value = info.battery;
    state.runtime.value = info.runtime;
    state.description.value = info.description;
    state.isConnected.value = info.isConnected;
  }

  /// 监听 HomeController 的实时 BLE 数据更新
  void _listenToRealtimeUpdates() {
    if (deviceInfo == null) return;
    final mac = deviceInfo!.macAddress;

    try {
      final homeController = Get.find<HomeController>();
      _dataWorker = interval(homeController.connectedDevices, (devices) {
        final updated = devices.firstWhereOrNull((d) => d.macAddress == mac);
        if (updated != null) {
          _syncFromDeviceInfo(updated);
        }
      }, time: const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint("DeviceDetails: 无法监听 HomeController - $e");
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF16456E),
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildDialogButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: 180,
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B4D8),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  void onClose() {
    _dataWorker?.dispose();
    super.onClose();
  }
}
