import 'package:get/route_manager.dart';
import 'package:nimoble/pages/device_details/index.dart';
import 'package:nimoble/pages/home/index.dart';
import 'package:nimoble/pages/settings/index.dart';
import '../pages/ble_module/view.dart';
import 'app_route.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.BLE_MODULE,
      page: () => const BleModulePage(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.DEVICE_DETAILS,
      page: () => const DeviceDetailsPage(),
      binding: DeviceDetailsBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}
