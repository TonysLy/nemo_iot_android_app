import 'package:get/get.dart';

import 'controller.dart';

class DeviceDetailsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeviceDetailsController>(() => DeviceDetailsController());
  }
}
