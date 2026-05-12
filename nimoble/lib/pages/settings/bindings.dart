import 'package:get/get.dart';

import 'controller.dart';

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController(), permanent: true);
    }
  }
}
