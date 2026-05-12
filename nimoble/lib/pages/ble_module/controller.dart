import 'dart:js';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_route.dart';

class BleModuleController extends GetxController {
  BleModuleController();

  _initData() {
    update(["ble_module"]);
  }

  void onTap() {}

  @override
  void onInit() {
    super.onInit();
    // var params = Get.arguments;
    // if (params != null && params[ParamKeys.BLE_MSG] != null) {
    // } else {
    Get.toNamed(AppRoutes.HOME);
    // }
  }

  @override
  void onReady() {
    super.onReady();
    _initData();
  }

  // @override
  // void onClose() {
  //   super.onClose();
  // }
}
