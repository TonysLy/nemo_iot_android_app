import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../r.dart';
import '../settings/controller.dart';
import 'index.dart';

class DeviceDetailsPage extends GetView<DeviceDetailsController> {
  const DeviceDetailsPage({super.key});

  Widget _buildAppBar() {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Center(
                    child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 28.w),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    controller.state.deviceName.value.isEmpty
                        ? (controller.deviceInfo?.name ?? 'OTTORACK')
                        : controller.state.deviceName.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    controller.state.description.value.isEmpty
                        ? 'Car'
                        : controller.state.description.value,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                  ),
                ],
              ),
              _buildMenuButton(),
            ],
          ),
        ));
  }
    //  右上角三点按钮的样式
  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: controller.toggleMenu,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44.w,
        height: 44.w,
        child: Center(
          child: Icon(Icons.more_horiz, color: Colors.white, size: 28.w),
        ),
      ),
    );
  }

  Widget _buildDeviceImage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Image.asset(
          R.imagesDeviceDetail,
          fit: BoxFit.contain,
          width: 270.w,
          height: 270.w,
        ),
      ),
    );
  }

  Widget _buildGaugeSection() {
    return Obx(() {
      final settingsController = Get.find<SettingsController>();
      final pressure = controller.state.pressure.value;
      final statusColor = controller.getPressureColor();
      final statusText = controller.getPressureStatus();
      final progress = (pressure / 0.65).clamp(0.0, 1.0);
      final gaugeWidth = 150.w;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(0, 30.h),
            child: SizedBox(
              width: gaugeWidth,
              height: gaugeWidth * 0.55,
              child: AnimatedSemiCircleGauge(
                progress: progress,
                statusColor: statusColor,
              ),
            ),
          ),
          
          Transform.translate(
            offset: Offset(0, -10.h),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -12.h), 
            child: Text(
            settingsController.formatPressure(pressure),
            style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInfoCards() {
    return Obx(() => Transform.translate(
          offset: Offset(0, -10.h),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                'Runtime',
                '${controller.state.runtime.value} min',
                labelStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
                valueStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildInfoItem(
                'Battery',
                '${controller.state.battery.value}%',
                labelStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
                valueStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle ?? TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (controller.state.isMenuOpen.value) controller.hideMenu();
              },
              child: Column(
                children: [
                  _buildAppBar(),
                  Flexible(
                    flex: 3,
                    child: _buildDeviceImage(),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF12202D),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          SizedBox(height: 30.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Obx(() {
                                final connected = controller.state.isConnected.value;
                                return Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    color: connected ? Colors.white : const Color(0xFF666666),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 24.w,
                                      height: 24.w,
                                      decoration: BoxDecoration(
                                        color: connected ? const Color(0xFF00B4D8) : const Color(0xFF444444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Obx(() {
                            final connected = controller.state.isConnected.value;
                            final statusColor = connected ? const Color(0xFF00C853) : const Color(0xFF888888);
                            return Row(
                              children: [
                                Icon(Icons.bluetooth, color: statusColor, size: 20.w),
                                SizedBox(width: 4.w),
                                Text(
                                  connected ? 'Connected' : 'Disconnected',
                                  style: TextStyle(color: statusColor, fontSize: 12.sp),
                                ),
                              ],
                            );
                          }),
                          const Spacer(flex: 1),
                          _buildGaugeSection(),
                          const Spacer(flex: 1),
                          _buildInfoCards(),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() => controller.state.isMenuOpen.value
                ? Positioned(
                    top: 48.h,
                    right: 22.w,
                    child: Container(
                      width: 130.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A5C),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => controller.onMenuItemTap(0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.h, horizontal: 10.w),
                              alignment: Alignment.centerLeft,
                              child: Text('Rename',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Divider(
                              color: Colors.grey[700],
                              height: 1.h,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.onMenuItemTap(1),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.h, horizontal: 10.w),
                              alignment: Alignment.centerLeft,
                              child: Text('Remove Device',
                                  style: TextStyle(
                                     color: Colors.white, 
                                     fontSize: 14.sp,
                                     fontWeight: FontWeight.w600
                                    )
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
            /* [TEMP-DEBUG-HW] 临时调试浮层（打包关闭）
            Positioned(
              right: 8.w,
              bottom: 8.h,
              child: Obx(() {
                final p = controller.state.pressure.value;
                return IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      'DBG ${p.toStringAsFixed(3)} bar',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            */
          ],
        ),
      ),
    );
  }
}

class AnimatedSemiCircleGauge extends StatelessWidget {
  const AnimatedSemiCircleGauge({
    super.key,
    required this.progress,
    required this.statusColor,
  });

  final double progress;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return CustomPaint(
          painter: SemiCircleGaugePainter(
            progress: animatedProgress,
            statusColor: statusColor,
          ),
        );
      },
    );
  }
}

/// 180度半圆弧形指示器 —— 开口向下（彩虹形）
class SemiCircleGaugePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final Color statusColor;

  SemiCircleGaugePainter({required this.progress, required this.statusColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    const strokeWidth = 12.0;
    const dotRadius = (strokeWidth + 12) / 2;
    final radius = size.width / 2 - dotRadius - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 全弧渐变（始终画满180度，绿→黄→橙→红）
    const segments = 60;
    const segAngle = pi / segments;

    for (int i = 0; i < segments; i++) {
      final t = i / (segments - 1);
      canvas.drawArc(
        rect,
        pi + segAngle * i,
        segAngle + 0.02,
        false,
        Paint()
          ..color = _lerpGradient(t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = (i == 0 || i == segments - 1)
              ? StrokeCap.round
              : StrokeCap.butt,
      );
    }

    // 动态指示器：外白环 + 内状态色圆，高值在左/绿，低值在右/红
    final angle = pi + pi * (1.0 - progress);
    final dotCenter = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = Colors.white);
    canvas.drawCircle(dotCenter, dotRadius - 3, Paint()..color = statusColor);
  }

  static Color _lerpGradient(double t) {
    const colors = [
      Color(0xFF00C853), Color(0xFFCCCC00),
      Color(0xFFFF8800), Color(0xFFFF4444),
    ];
    const stops = [0.0, 0.35, 0.65, 1.0];
    for (int i = 0; i < stops.length - 1; i++) {
      if (t <= stops[i + 1]) {
        final lt = (t - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(colors[i], colors[i + 1], lt)!;
      }
    }
    return colors.last;
  }

  @override
  bool shouldRepaint(covariant SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.statusColor != statusColor;
  }
}
