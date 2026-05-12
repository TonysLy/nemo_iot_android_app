import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'controller.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    // 使用 put 而非 lazyPut，确保页面加载时 Controller 已准备好
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
      debugPrint("HomeController registered");
    }
  }
}
