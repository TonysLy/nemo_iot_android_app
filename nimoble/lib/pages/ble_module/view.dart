import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../../routes/app_route.dart';
import 'screens/bluetooth_off_screen.dart';
import 'screens/scan_screen.dart';

class BleModulePage extends StatefulWidget {
  const BleModulePage({Key? key}) : super(key: key);

  @override
  State<BleModulePage> createState() => _BleModulePageState();
}

class _BleModulePageState extends State<BleModulePage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
    var params = Get.arguments;
    if (params != null) {
    } else {
      Get.offNamed(AppRoutes.HOME);
    }
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const ScanScreen()
        : BluetoothOffScreen(adapterState: _adapterState);

    return screen;
  }
}
