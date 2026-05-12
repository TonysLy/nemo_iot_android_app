import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nimoble/routes/app_route.dart';

import '../../r.dart';
import '../alarm/controller.dart';
import '../settings/controller.dart';
import 'index.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  // [TEMP-DEBUG-ALARM-PREVIEW]
  // Keep this block for future alarm flashing preview tests.
  // static const bool debugForceAlarmPreview = true;
  // static const int debugAlarmPreviewIndex = 0;
  // static const bool debugPreviewLowBattery = true;
  // static const bool debugPreviewLowVacuum = false;

  void _showAddDeviceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      builder: (ctx) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF1A3A5C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Add Device',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Make sure your device is turned on and in range.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: 160.w,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Get.toNamed(AppRoutes.BLE_MODULE, arguments: "open");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.h),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return Obx(() {
      final allDevices = controller.displayDevices;

      if (allDevices.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 48.w,
                color: Colors.grey,
              ),
              SizedBox(height: 16.h),
              Text(
                'No devices found',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tap + to add devices',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.onRefresh,
        color: const Color(0xFF00B4D8),
        backgroundColor: const Color(0xFF2D2D3A),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: allDevices.length,
          itemBuilder: (context, index) {
            final device = allDevices[index];
            final isSelected = controller.state.selectedIndex.value == index;
            return GestureDetector(
              onTap: () {
                Get.toNamed(
                  AppRoutes.DEVICE_DETAILS,
                  arguments: {ParamKeys.BLE_MSG: device},
                );
              },
              child: _buildDeviceCard(device, index, isSelected),
            );
          },
        ),
      );
    });
  }

  Widget _buildDeviceCard(DeviceInfo device, int index, bool isSelected) {
    final settingsController = Get.find<SettingsController>();
    final bool isConnected = device.isConnected;
    final Color cardColor = isConnected
        ? const Color(0xFF1A3A5C)
        : const Color(0xFF2D2D3A);
    const Color textColor = Colors.white;
    final borderRadius = BorderRadius.circular(16.w);

    final realLowBattery = device.isConnected &&
        device.hasBatteryReading &&
        device.battery < AlarmController.lowBatteryThresholdPercent;
    final realLowVacuum = device.isConnected &&
        device.hasPressureReading &&
        device.pressure < AlarmController.lowVacuumThresholdBar;

    // [TEMP-DEBUG-ALARM-PREVIEW] Forces one card to show the alarm style
    // without relying on live BLE values. Uncomment with the constants above
    // when the alarm flashing style needs to be tested again.
    // final debugPreviewActive =
    //     debugForceAlarmPreview && index == debugAlarmPreviewIndex;
    // final lowBattery =
    //     debugPreviewActive ? debugPreviewLowBattery : realLowBattery;
    // final lowVacuum =
    //     debugPreviewActive ? debugPreviewLowVacuum : realLowVacuum;
    final lowBattery = realLowBattery;
    final lowVacuum = realLowVacuum;
    final hasAlarm = lowBattery || lowVacuum;
    final batteryIconColor = isConnected
        ? _getBatteryColor(device.battery)
        : const Color(0xFFCCCCCC);
    final pressureIconColor = isConnected
        ? _getPressureColor(device.pressure)
        : const Color(0xFFCCCCCC);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius,
        border: isSelected
            ? Border.all(color: const Color(0xFFE53935), width: 2.w)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.w),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            R.imagesDevicefirst,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.bluetooth,
                                color: textColor.withValues(alpha: 0.5),
                                size: 30.w,
                              );
                            },
                          ),
                          if (!isConnected)
                            ColoredBox(
                              color: const Color(0xFF8A8A8A)
                                  .withValues(alpha: 0.42),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            _buildStatusLabel(
                              icon: _getBatteryIcon(device.battery),
                              iconColor: batteryIconColor,
                              text: '${device.battery}%',
                              backgroundColor: isConnected
                                  ? const Color(0xFF0D47A1)
                                  : const Color(0xFF3D3D4A),
                              iconQuarterTurns: 3,
                            ),
                            SizedBox(width: 8.w),
                            Obx(() => _buildStatusLabel(
                                  icon: Icons.speed_outlined,
                                  iconColor: pressureIconColor,
                                  text: settingsController
                                      .formatPressure(device.pressure),
                                  backgroundColor: isConnected
                                      ? const Color(0xFF0D47A1)
                                      : const Color(0xFF3D3D4A),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? const Color(0xFF00D9FF)
                          : const Color(0xFF666666),
                      boxShadow: isConnected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00D9FF)
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAlarm)
              Positioned.fill(
                child: IgnorePointer(
                  child: _AlarmInnerGlow(borderRadius: borderRadius),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color backgroundColor,
    int iconQuarterTurns = 0,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotatedBox(
            quarterTurns: iconQuarterTurns,
            child: Icon(icon, color: iconColor, size: 14.w),
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon(int battery) {
    if (battery >= 80) return Icons.battery_full;
    if (battery >= 60) return Icons.battery_6_bar;
    if (battery >= 40) return Icons.battery_4_bar;
    if (battery >= 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int battery) {
    if (battery < 20) return const Color(0xFFFE0000);
    return const Color(0xFF00E737);
  }

  Color _getPressureColor(double pressure) {
    if (pressure <= 0.48) return const Color(0xFFFE0000);
    return const Color(0xFF00E737);
  }

  Widget _buildHomeBottomBar() {
    const barBg = Color(0xFF002B5B);
    const homeAccent = Color(0xFF00D9FF);
    return Container(
      height: 100.h,
      color: const Color(0xFF242424),
      alignment: Alignment.center,
      child: Container(
        width: 180.w,
        height: 52.h,
        decoration: BoxDecoration(
          color: barBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, color: homeAccent, size: 28.w),
            SizedBox(width: 54.w),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.SETTINGS),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: Center(
                  child: Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 28.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (_) {
        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFF191919),
          navigationBar: CupertinoNavigationBar(
            border: null,
            backgroundColor: const Color(0xFF242424),
            middle: Text(
              'My Devices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: const SizedBox.shrink(),
            trailing: GestureDetector(
              onTap: () => _showAddDeviceBottomSheet(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44.w,
                height: 44.w,
                alignment: Alignment.center,
                child: Icon(Icons.add, color: Colors.white, size: 32.w),
              ),
            ),
          ),
          child: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 100.h),
                    child: _buildDeviceList(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildHomeBottomBar(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlarmInnerGlow extends StatefulWidget {
  const _AlarmInnerGlow({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  State<_AlarmInnerGlow> createState() => _AlarmInnerGlowState();
}

class _AlarmInnerGlowState extends State<_AlarmInnerGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return CustomPaint(
          painter: _AlarmInnerGlowPainter(
            opacity: _opacity.value,
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

class _AlarmInnerGlowPainter extends CustomPainter {
  const _AlarmInnerGlowPainter({
    required this.opacity,
    required this.borderRadius,
  });

  final double opacity;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    const red = Color(0xFFFF3030);
    const shadowWidth = 20.0;
    const shadowSteps = 20;

    for (var i = 0; i < shadowSteps; i++) {
      final progress = i / (shadowSteps - 1);
      final alpha = opacity * 0.28 * (1 - progress) * (1 - progress);

      canvas.drawRRect(
        borderRadius.toRRect(rect.deflate(1 + shadowWidth * progress)),
        Paint()
          ..color = red.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..color = red.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _AlarmInnerGlowPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.borderRadius != borderRadius;
  }
}
