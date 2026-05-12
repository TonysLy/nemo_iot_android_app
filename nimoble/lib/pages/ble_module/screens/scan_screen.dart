import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../home/controller.dart';
import '../../home/state.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  // 可识别的设备名称列表
  static const List<String> _recognizedDeviceNames = [
    'Roof_Rack', 'OTTORACK', 'GRABO',
  ];

  // 60秒进度条相关
  static const int _totalScanSeconds = 60;
  double _progress = 0.0;
  Timer? _progressTimer;
  Timer? _scanTimeoutTimer;
  double _connectProgress = 0.0;
  Timer? _connectTimer;
  bool _showConnectProgress = false;
  bool _isScanStarting = false;
  bool _isConnecting = false;
  bool _hasScanStarted = false;
  bool _hasShownScanTimeoutSheet = false;

  // 获取HomeController引用
  HomeController? get _homeController {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>();
    }
    return null;
  }

  /// 判断扫描结果是否为可识别的目标设备
  bool _isRecognizedDevice(ScanResult result) {
    final name = result.device.platformName.toUpperCase();
    final advName = result.advertisementData.advName.toUpperCase();
    final mergedName = '$name $advName';
    if (mergedName.trim().isEmpty) return false;
    return _recognizedDeviceNames.any(
      (recognized) => mergedName.contains(recognized.toUpperCase()),
    );
  }

  bool _isUnaddedDevice(ScanResult result) {
    final homeController = _homeController;
    if (homeController == null) return true;
    final macAddress = result.device.remoteId.toString();
    final inHistory = homeController.state.historyDevices
        .any((d) => d.macAddress == macAddress);
    final inConnected = homeController.connectedDevices
        .any((d) => d.macAddress == macAddress);
    return !inHistory && !inConnected;
  }

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results
          .where((result) => _isRecognizedDevice(result) && _isUnaddedDevice(result))
          .toList();
      if (mounted) {
        setState(() {});
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (!state) {
        _stopProgressTimer();
      }
      if (mounted) {
        setState(() {
          if (!state && _hasScanStarted) _progress = 1.0;
        });
      }
    });

    // 自动开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    // 停止蓝牙扫描
    try {
      FlutterBluePlus.stopScan();
      debugPrint("📡 离开扫描页面，停止蓝牙搜索");
    } catch (e) {
      debugPrint("停止扫描失败: $e");
    }
    
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _stopProgressTimer();
    _stopScanTimeoutTimer();
    _stopConnectProgressTimer();
    _homeController?.requestReconnectPass();
    super.dispose();
  }

  /// 开始扫描并启动进度条
  void _startScan() async {
    if (_isScanStarting) return;
    _isScanStarting = true;
    try {
      _hasScanStarted = false;
      _hasShownScanTimeoutSheet = false;
      if (await FlutterBluePlus.isScanning.first) {
        await FlutterBluePlus.stopScan();
      }
      await Future.delayed(const Duration(milliseconds: 200));
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: _totalScanSeconds));
      _hasScanStarted = true;
      _startProgressTimer();
      _startScanTimeoutTimer();
    } catch (e) {
      debugPrint("Start Scan Error: $e");
    } finally {
      _isScanStarting = false;
    }
  }

  /// 启动进度条计时器
  void _startProgressTimer() {
    _stopProgressTimer();
    _progress = 0.0;
    
    // 每600ms更新一次，60秒共100次更新
    _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _progress += 1 / 100; // 每次增加1%
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  /// 停止进度条计时器
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _startScanTimeoutTimer() {
    _stopScanTimeoutTimer();
    _scanTimeoutTimer = Timer(const Duration(seconds: _totalScanSeconds), () {
      if (!mounted || !_hasScanStarted || _hasShownScanTimeoutSheet) return;
      if (_scanResults.isEmpty) {
        _hasShownScanTimeoutSheet = true;
        _showScanErrorBottomSheet();
      }
    });
  }

  void _stopScanTimeoutTimer() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
  }

  void _startConnectProgressTimer() {
    _stopConnectProgressTimer();
    if (!mounted) return;
    setState(() {
      _showConnectProgress = true;
      _connectProgress = 0.0;
    });
    _connectTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _connectProgress += 1 / 100;
        if (_connectProgress >= 1.0) {
          _connectProgress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  void _stopConnectProgressTimer() {
    _connectTimer?.cancel();
    _connectTimer = null;
  }

  bool _isBleConnected(String macAddress) {
    final homeController = _homeController;
    if (homeController == null) return false;
    return homeController.isDeviceConnected(macAddress);
  }

  void _onConnectButtonPressed(ScanResult device) {
    _performConnect(device.device);
  }

  /// 执行连接操作
  void _performConnect(BluetoothDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _startConnectProgressTimer();
    bool success = false;

    try {
      await device
          .connect(timeout: const Duration(seconds: 15))
          .timeout(const Duration(seconds: 18));
      _homeController?.addDevice(device);
      success = true;
    } catch (e) {
      debugPrint("连接失败: $e");
    } finally {
      _isConnecting = false;
      _stopConnectProgressTimer();
      if (mounted) {
        setState(() {
          _connectProgress = 1.0;
        });
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted) {
        _showResultBottomSheet(success: success);
        setState(() {
          _showConnectProgress = false;
          _connectProgress = 0.0;
        });
      }
    }
  }

  /// 显示连接结果底部弹窗
  void _showResultBottomSheet({required bool success}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D4E8B), Color(0xFF0A3D6B)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: success
                        ? const Color(0xFF00B4D8)
                        : const Color(0xFFE53935),
                    size: 40.w,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    success
                        ? 'Successfully added device!'
                        : 'It is recommended that the user\nreconnect or check the device.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),
                  SizedBox(
                    width: 180.w,
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (success) {
                          Get.back();
                        } else {
                          _onRefresh();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22.h),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      body: Column(
        children: [
          // 顶部蓝色区域 - 包含标题和进度条
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D2A4F), // 深蓝色背景
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.w)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 标题栏
                  Container(
                    height: 56.h,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        // 返回按钮
                        Positioned(
                          left: 16.w,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 44.w,
                              height: 44.w,
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 28.w,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 居中标题
                        Center(
                          child: Text(
                            'Add Device',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 进度条区域
                  _buildProgressBars(),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Get.isRegistered<HomeController>()
                ? StreamBuilder<List<DeviceInfo>>(
                    stream: Get.find<HomeController>().connectedDevices.stream,
                    builder: (context, _) => _buildScanList(),
                  )
                : _buildScanList(),
          ),
        ],
      ),
    );
  }

  /// 下拉刷新 - 重置蓝牙搜索和进度条
  Future<void> _onRefresh() async {
    // 停止当前扫描
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("停止扫描失败: $e");
    }
    
    // 清空扫描结果
    setState(() {
      _scanResults = [];
      _progress = 0.0;
      _hasScanStarted = false;
      _hasShownScanTimeoutSheet = false;
    });
    _stopScanTimeoutTimer();
    
    // 重新开始扫描
    await Future.delayed(const Duration(milliseconds: 300));
    _startScan();
    
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget _buildProgressBars() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Stack(
        children: [
          ScanProgressBar(progress: _progress),
          if (_showConnectProgress)
            Positioned.fill(
              child: ScanProgressBar(progress: _connectProgress),
            ),
        ],
      ),
    );
  }

  void _showScanErrorBottomSheet() {
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
              Icon(
                Icons.cancel_outlined,
                color: const Color(0xFFE53935),
                size: 30.w,
              ),
              SizedBox(height: 16.h),
              Text(
                'Please ensure the device is turned on and search again',
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
                    _onRefresh();
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
                    'Continue',
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

  Widget _buildScanList() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF00B4D8),
      backgroundColor: const Color(0xFF2D2D3A),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          return _buildDeviceCard(_scanResults[index]);
        },
      ),
    );
  }

  /// 构建设备卡片
  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final macAddress = device.remoteId.toString();
    final bool isButtonDisabled = _isBleConnected(macAddress);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        children: [
          // 设备图片
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.w),
              child: Image.asset(
                'images/devicefirst.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.bluetooth,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 30.w,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          // 设备信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.platformName.isEmpty ? 'Unknown Device' : device.platformName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Connect按钮
          GestureDetector(
            onTap: isButtonDisabled ? null : () => _onConnectButtonPressed(result),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isButtonDisabled 
                    ? const Color(0xFF666666)  // 置灰
                    : const Color(0xFF00B4D8), // 蓝色
                borderRadius: BorderRadius.circular(16.w),
              ),
              child: Text(
                'Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanProgressBar extends StatelessWidget {
  final double progress;

  const ScanProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final int percentage = (progress * 100).toInt();
    return SizedBox(
      height: 12.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.h),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF1A3A5C),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B4D8)),
              minHeight: 12.h,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
