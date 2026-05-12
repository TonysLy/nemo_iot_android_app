import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../alarm/controller.dart';
import 'state.dart';

class SettingsController extends GetxController {
  SettingsController();

  final state = SettingsState();
  final _storage = GetStorage();

  static const String pressureUnitIsBarKey = 'pressure_unit_is_bar';
  static const String autoConnectEnabledKey = 'auto_connect_enabled';
  static const String alarmAlertsEnabledKey = 'alarm_alerts_enabled';
  static const double psiPerBar = 14.5;

  bool get isBarUnit => state.unitIsBar.value;
  bool get autoConnectEnabled => state.autoConnectEnabled.value;
  bool get alarmAlertsEnabled => state.alarmAlertsEnabled.value;
  String get pressureUnitLabel => isBarUnit ? 'Bar' : 'psi';

  double convertPressure(double pressureBar) {
    return isBarUnit ? pressureBar : pressureBar * psiPerBar;
  }

  String formatPressure(double pressureBar) {
    return '${convertPressure(pressureBar).toStringAsFixed(2)} $pressureUnitLabel';
  }

  void updateUnit(bool isBar) {
    state.unitIsBar.value = isBar;
    _storage.write(pressureUnitIsBarKey, isBar);
  }

  void toggleAlarmAlerts(bool enabled) {
    state.alarmAlertsEnabled.value = enabled;
    _storage.write(alarmAlertsEnabledKey, enabled);
    if (enabled && Get.isRegistered<AlarmController>()) {
      Get.find<AlarmController>().requestNotificationPermission();
    }
  }

  void toggleAutoConnect(bool enabled) {
    state.autoConnectEnabled.value = enabled;
    _storage.write(autoConnectEnabledKey, enabled);
  }

  @override
  void onInit() {
    super.onInit();
    state.unitIsBar.value = _storage.read<bool>(pressureUnitIsBarKey) ?? true;
    state.alarmAlertsEnabled.value =
        _storage.read<bool>(alarmAlertsEnabledKey) ?? true;
    state.autoConnectEnabled.value =
        _storage.read<bool>(autoConnectEnabledKey) ?? true;
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
