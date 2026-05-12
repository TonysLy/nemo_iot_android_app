import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';


import 'index.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  static const Color _bg = Color(0xFF1D2023);
  static const Color _line = Color(0xFF4A4D50);
  static const Color _title = Colors.white;
  static const Color _sub = Color(0xFFA8AAAD);
  static const Color _blue = Color(0xFF00B8F0);
  static const Color _grayToggle = Color(0xFFB6B7BA);

  static const String _privacyPlaceholder = '''
[请在这里粘贴隐私政策正文]

1. 信息收集
[填写内容]

2. 信息使用
[填写内容]

3. 信息共享
[填写内容]

4. 数据安全
[填写内容]

5. 联系我们
[填写内容]
''';

  static const String _termsPlaceholder = '''
[请在这里粘贴服务条款正文]

1. 条款接受
[填写内容]

2. 服务说明
[填写内容]

3. 用户义务
[填写内容]

4. 免责声明
[填写内容]

5. 条款更新
[填写内容]
''';

  Widget _buildUnitToggle() {
    return Obx(() {
      final isBar = controller.state.unitIsBar.value;
      return _SegmentToggle(
        leftText: 'bar',
        rightText: 'psi',
        leftSelected: isBar,
        onLeftTap: () => controller.updateUnit(true),
        onRightTap: () => controller.updateUnit(false),
      );
    });
  }

  Widget _buildSwitchToggle({
    required bool leftSelected,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
  }) {
    return _SegmentToggle(
      leftText: 'ON',
      rightText: 'OFF',
      leftSelected: leftSelected,
      onLeftTap: onLeftTap,
      onRightTap: onRightTap,
    );
  }

  Widget _buildSectionLine() {
    return const Divider(height: 1, thickness: 1, color: _line);
  }

  Widget _buildToggleRow({
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _title,
                    fontSize: 36 / 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _sub,
                      fontSize: 22 / 2,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _title,
                  fontSize: 40 / 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _title, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildView() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20),
              children: [
                _buildToggleRow(
                    title: 'Toggle units', trailing: _buildUnitToggle()),
                _buildSectionLine(),
                Obx(() => _buildToggleRow(
                      title: 'Get alarm alerts',
                      trailing: _buildSwitchToggle(
                        leftSelected: controller.state.alarmAlertsEnabled.value,
                        onLeftTap: () => controller.toggleAlarmAlerts(true),
                        onRightTap: () => controller.toggleAlarmAlerts(false),
                      ),
                    )),
                _buildSectionLine(),
                Obx(() => _buildToggleRow(
                      title: 'Auto-Connect',
                      subtitle:
                          'Automatically connect when the device is in range.',
                      trailing: _buildSwitchToggle(
                        leftSelected: controller.state.autoConnectEnabled.value,
                        onLeftTap: () => controller.toggleAutoConnect(true),
                        onRightTap: () => controller.toggleAutoConnect(false),
                      ),
                    )),
                _buildSectionLine(),
                _buildNavRow(
                  title: 'About us',
                  onTap: () => Get.to(() => const SettingsDocumentPage(
                        title: 'About us',
                        content: 'GRABO App\n\n[请在这里粘贴公司介绍内容]',
                      )),
                ),
                _buildSectionLine(),
                _buildNavRow(
                  title: 'Privacy Policy',
                  onTap: () => Get.to(() => const SettingsDocumentPage(
                        title: 'Privacy Policy',
                        content: _privacyPlaceholder,
                      )),
                ),
                _buildSectionLine(),
                _buildNavRow(
                  title: 'Terms of Service',
                  onTap: () => Get.to(() => const SettingsDocumentPage(
                        title: 'Terms of Service',
                        content: _termsPlaceholder,
                      )),
                ),
                _buildSectionLine(),
                _buildNavRow(
                  title: 'Support',
                  onTap: () => Get.to(() => const SettingsDocumentPage(
                        title: 'Support',
                        content: '[请在这里粘贴支持联系方式和支持流程]',
                      )),
                ),
                _buildSectionLine(),
                _buildNavRow(
                  title: 'Permission Explanation',
                  onTap: () => Get.to(() => const SettingsDocumentPage(
                        title: 'Permission Explanation',
                        content: '[请在这里粘贴权限用途说明]',
                      )),
                ),
                _buildSectionLine(),
                _buildNavRow(
                  title: 'About',
                  onTap: () => Get.to(() => const SettingsDocumentPage(
                        title: 'About',
                        content: 'APP version: V1.0.1\n\n[请在这里粘贴其他应用信息]',
                      )),
                ),
                _buildSectionLine(),
                const SizedBox(height: 80),
                const Center(
                  child: Text(
                    'GRABO®',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      
                    ),
                  ),
                ),
                const SizedBox(height: 38),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(builder: (_) {
      return KeyboardDismissOnTap(
          child: CupertinoPageScaffold(
        backgroundColor: _bg,
        navigationBar: CupertinoNavigationBar(
          border: null,
          backgroundColor: _bg,
          leading: CupertinoButton(
            onPressed: Get.back,
            padding: EdgeInsets.zero,
            minSize: 44,
            child: const Icon(
              CupertinoIcons.back,
              color: Colors.white,
              size: 34,
            ),
          ),
          middle: const Text(
            'Setting',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: _buildView(),
      ));
    });
  }
}

class SettingsDocumentPage extends StatelessWidget {
  final String title;
  final String content;

  const SettingsDocumentPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: SettingsPage._bg,
      navigationBar: CupertinoNavigationBar(
        border: null,
        backgroundColor: SettingsPage._bg,
        leading: CupertinoButton(
          onPressed: Get.back,
          padding: EdgeInsets.zero,
          minSize: 44,
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 26,
          ),
        ),
        middle: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  final String leftText;
  final String rightText;
  final bool leftSelected;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  const _SegmentToggle({
    required this.leftText,
    required this.rightText,
    required this.leftSelected,
    required this.onLeftTap,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: SettingsPage._grayToggle,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            text: leftText,
            selected: leftSelected,
            onTap: onLeftTap,
          ),
          _ToggleBtn(
            text: rightText,
            selected: !leftSelected,
            onTap: onRightTap,
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? SettingsPage._blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF5A5B5E),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
