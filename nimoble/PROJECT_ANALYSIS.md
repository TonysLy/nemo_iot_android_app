# Nimoble Flutter 项目分析报告

## 一、项目概述

这是一个 **Flutter BLE（低功耗蓝牙）IoT 设备管理应用**，应用名为 **"Avica"**，主要功能是通过蓝牙连接和管理 IoT 设备（看起来是车载真空设备），实时展示设备的 **电量** 和 **真空压力值**。

- **Dart SDK**: `>=3.3.1 <4.0.0`
- **版本**: `1.0.0+1`
- **Android minSdk**: 24（Android 7.0）
- **包名**: `com.example.nimoble`
- **竖屏锁定**: 是

---

## 二、目录结构

```
nimoble/
├── lib/
│   ├── main.dart                      # 应用入口
│   ├── ble.dart                       # BLE 数据模型（JSON 序列化）
│   ├── r.dart                         # 图片资源路径常量（自动生成）
│   ├── routes/
│   │   ├── app_route.dart             # 路由名称 + 参数键常量
│   │   └── app_pages.dart             # GetX 路由注册表
│   └── pages/
│       ├── home/                      # 首页（设备列表）
│       │   ├── index.dart             # barrel export
│       │   ├── controller.dart        # HomeController（核心 BLE 管理逻辑）
│       │   ├── view.dart              # 设备列表 UI
│       │   ├── state.dart             # HomeState + DeviceInfo 模型
│       │   ├── bindings.dart          # GetX 依赖注入
│       │   └── widgets/              
│       ├── device_details/            # 设备详情页（真空仪表盘）
│       │   ├── controller.dart        # 压力/电量状态 + 菜单交互
│       │   ├── view.dart              # 半圆弧仪表盘 UI（CustomPaint）
│       │   ├── state.dart             # DeviceDetailsState
│       │   └── bindings.dart
│       ├── ble_module/                # 蓝牙扫描模块
│       │   ├── view.dart              # 根据蓝牙开关状态切换页面
│       │   ├── controller.dart        # BLE 模块控制器（有遗留问题）
│       │   └── screens/
│       │       ├── scan_screen.dart    # 扫描页面（核心扫描+连接逻辑）
│       │       ├── device_screen.dart  # GATT 调试页（来自官方示例）
│       │       └── bluetooth_off_screen.dart
│       ├── settings/                  # 设置页
│       ├── utils/
│       │   ├── themes.dart            # Cupertino 主题 + TextStyle 常量
│       │   ├── utils.dart             # StreamControllerReemit + 服务UUID常量
│       │   ├── snackbar.dart          # SnackBar 工具
│       │   └── extra.dart             # BluetoothDevice 扩展方法
│       └── widgets/                   # 通用 Widget
│           ├── scan_result_tile.dart   # 扫描结果卡片
│           ├── service_tile.dart       # GATT 服务展示
│           ├── characteristic_tile.dart
│           ├── descriptor_tile.dart
│           ├── input_widget.dart       # 输入组件
│           └── line_widget.dart        # 分割线
├── images/                            # 图片资源（PNG）
├── android/                           # Android 平台配置
├── ios/                               # iOS 平台配置
└── pubspec.yaml                       # 依赖管理
```

---

## 三、技术栈与依赖

| 依赖 | 用途 |
|------|------|
| `get` | 状态管理 + 路由 + 依赖注入 |
| `get_storage` | 本地轻量持久化（历史设备记录） |
| `flutter_blue_plus` ^1.31.15 | BLE 蓝牙通信核心库 |
| `flutter_screenutil` ^5.9.0 | 屏幕适配（设计稿 360x690） |
| `flutter_easyloading` | 全局 Toast / Loading 提示 |
| `flutter_keyboard_visibility` ^6.0.0 | 键盘可见性监听 |
| `fluttertoast` ^8.0.7 | Toast 提示（声明但未在代码中使用） |
| `flutter_draggable_gridview` ^0.0.11 | 可拖拽网格（声明但未在代码中使用） |
| `json_annotation` / `json_serializable` | JSON 序列化 |

---

## 四、架构设计

### 4.1 整体架构模式

采用 **GetX MVC 分层架构**，每个页面模块遵循统一结构：

```
页面模块/
├── index.dart        # barrel export（统一导出）
├── controller.dart   # GetxController（业务逻辑）
├── view.dart         # GetView<Controller>（UI 视图）
├── state.dart        # 响应式状态（.obs / RxList 等）
├── bindings.dart     # 依赖注入绑定
└── widgets/          # 页面级子组件
```

### 4.2 应用启动流程

```
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
GetStorage.init()
  ↓
ScreenUtil.ensureScreenSize()
  ↓
FlutterBluePlus.setLogLevel(verbose)
  ↓
runApp(MyApp)
  ↓
ScreenUtilInit(360x690)
  ↓
GetCupertinoApp
  ↓
initialRoute: /home
  ↓
HomeBinding -> HomeController
```

应用使用 **`GetCupertinoApp`**（而非 `GetMaterialApp`），整体风格偏 iOS Cupertino 设计。

### 4.3 路由系统

在 `lib/routes/app_route.dart` 中定义了 4 条路由：

| 路由 | 页面 | Binding | 说明 |
|------|------|---------|------|
| `/home` | `HomePage` | `HomeBinding` | 首页设备列表 |
| `/ble_module` | `BleModulePage` | 无 | 蓝牙扫描模块 |
| `/device_details` | `DeviceDetailsPage` | `DeviceDetailsBinding` | 设备详情仪表盘 |
| `/settings` | `SettingsPage` | `SettingsBinding` | 设置页（尚未接入入口） |

页面间通过 `Get.arguments` 传递参数，参数键在 `ParamKeys` 类中定义。

---

## 五、核心模块详解

### 5.1 首页 - HomeController（业务核心，约 920 行）

这是整个应用最核心的文件 `lib/pages/home/controller.dart`，包含：

**DeviceConnectionManager 类**（第 14-200 行）-- 管理单个 BLE 设备的完整生命周期：

- 监听 `connectionState`（连接/断开状态）
- 连接后自动 `discoverServices()` 发现 GATT 服务
- 查找第一个支持 notify/indicate 的特征值并订阅
- 解析 UTF-8 数据（支持 JSON 格式和逗号分隔键值对格式）
- 请求 MTU 223
- **断开防抖机制**：3 秒防抖避免信号波动导致频繁断开
- `_isDisposed` 标志防止已销毁的 Manager 继续处理事件

**HomeController 类**（第 202-923 行）-- 设备列表管理：

- **持续扫描机制**：30 分钟超时扫描，每 3 秒检查是否需要继续
- **自动重连**：启动时自动扫描并连接历史设备
- **连接冷却**：5 秒内不重复连接同一设备
- **RSSI 检查**：信号强度低于 -80dBm 不自动连接
- **displayDevices**：合并已连接设备 + 历史设备去重后展示
- **GetStorage 持久化**：保存历史设备和已连接设备 MAC 列表

### 5.2 设备详情 - DeviceDetailsPage

在 `lib/pages/device_details/view.dart` 中实现了：

- **半圆弧形真空仪表盘**：使用 `CustomPaint` + `SemiCircleGaugePainter` 绘制 180 度弧形指示器
- 压力值 0-0.65 bar 映射到进度 0.0-1.0
- 低于 0.48 bar 显示红色 "Bad"，高于显示绿色 "Good"
- 渐变色弧线（红色到绿色）+ 指示器圆点
- 菜单弹窗支持 Rename / Remove Device（目前为 TODO 状态）

### 5.3 扫描页 - ScanScreen

在 `lib/pages/ble_module/screens/scan_screen.dart` 中：

- **StatefulWidget**（非 GetX 模式），直接使用 `flutter_blue_plus` API
- 60 秒扫描超时 + 进度条动画
- 已连接/历史设备的 Connect 按钮置灰
- 连接成功后调用 `HomeController.addDevice()` 并跳转回首页
- 支持下拉刷新重新扫描

### 5.4 数据模型 - DeviceInfo

在 `lib/pages/home/state.dart` 中定义：

```dart
class DeviceInfo {
  String name;           // 设备名称
  String macAddress;     // MAC 地址（唯一标识）
  int battery;           // 电量 0-100
  double pressure;       // 真空压力值（bar）
  bool isConnected;      // 连接状态
  String? lastConnectedTime;  // 上次连接时间
}
```

---

## 六、BLE 数据流

```
BLE 设备
  ↓
GATT Notify
  ↓
DeviceConnectionManager
  ↓
UTF-8 解码
  ↓
┌─────────────────┐
│  JSON 解析      │───成功──→ 提取 battery/pressure
│                │───失败──→ 键值对格式解析
└─────────────────┘
  ↓
onDataUpdate 回调
  ↓
更新 connectedDevices RxList
  ↓
Obx 自动刷新 UI
```

设备发送的数据格式支持两种：
- **JSON**: `{"battery": 85, "pressure": 0.52}`
- **键值对**: `battery:85,pressure:0.52`

---

## 七、Android 配置要点

- **BLE 权限分版本声明**：Android 12+ 使用 `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`，Android 11 及以下使用传统权限
- **硬件特性**：要求设备必须支持 BLE（`android.hardware.bluetooth_le` required=true）
- **Gradle 插件**：AGP 8.2.2，Kotlin 1.8.22
- **仓库镜像**：配置了阿里云 Maven 镜像加速

---

## 八、发现的潜在问题

### 8.1 BleModuleController 遗留代码
`lib/pages/ble_module/controller.dart` 中引入了 `dart:js`，这个库在纯移动端（Android/iOS）上不可用，且 `onInit` 中直接 `Get.toNamed(AppRoutes.HOME)` 可能导致意外跳转。实际上 `BleModulePage` 是 StatefulWidget，并未使用该 Controller。

### 8.2 设备详情页数据不同步
`DeviceDetailsController.onInit()` 仅在进入页面时从 `Get.arguments` 读取一次 pressure/battery，之后**不会**与 `HomeController` 的实时 BLE 数据同步。如果用户停留在详情页，数据不会更新。

### 8.3 BleModulePage 嵌套导航器
`BleModulePage` 内部嵌套了一个 `MaterialApp`，形成了与外层 `GetCupertinoApp` 独立的导航栈。这可能导致主题不一致和导航行为混乱。

### 8.4 Settings 页面无入口
`SettingsPage` 已在路由表注册，但 UI 中没有任何地方调用 `Get.toNamed(AppRoutes.SETTINGS)`，该页面实际无法访问。

### 8.5 未使用的依赖
`fluttertoast` 和 `flutter_draggable_gridview` 在 `pubspec.yaml` 中声明但代码中未引用。

### 8.6 图片资源可能缺失
`r.dart` 中引用了 `images/device_detail.png`，但 `pubspec.yaml` 的 assets 中未声明该文件，`images/` 目录下实际 PNG 文件也可能缺失（仓库中仅有 `files.txt`）。

---

## 九、代码质量评估

**优点：**
- GetX 分层结构清晰，每个模块职责明确
- BLE 连接管理考虑了防抖、冷却、RSSI 检查等边界情况
- 使用 `DeviceConnectionManager` 封装单设备管理，便于多设备扩展
- 半圆仪表盘使用 CustomPaint 绘制，性能较好

**改进空间：**
- `HomeController` 承担过多职责（约 920 行），建议拆分 BLE 扫描/连接/持久化 为独立 Service
- 详情页缺乏实时数据绑定机制
- `ScanScreen` 使用 StatefulWidget 而非 GetX 模式，与项目整体风格不统一
- 部分 TODO 功能（Rename / Remove Device）未实现

---

## 十、关键代码片段

### 10.1 路由定义（lib/routes/app_route.dart）

```dart
class AppRoutes {
  static const HOME = '/home';
  static const BLE_MODULE = '/ble_module';
  static const DEVICE_DETAILS = '/device_details';
  static const SETTINGS = '/settings';
}

class ParamKeys {
  static const BLE_DEVICE_ITEM = "BLE_DEVICE_ITEM";
  static const BLE_MSG = "BLE_MSG";
}
```

### 10.2 路由注册（lib/routes/app_pages.dart）

```dart
class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.BLE_MODULE,
      page: () => const BleModulePage(),
    ),
    GetPage(
      name: AppRoutes.DEVICE_DETAILS,
      page: () => const DeviceDetailsPage(),
      binding: DeviceDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
  ];
}
```

### 10.3 设备信息模型（lib/pages/home/state.dart）

```dart
class DeviceInfo {
  String name;
  String macAddress;
  int battery;           // 电量 0-100
  double pressure;     // 压力值
  bool isConnected;      // 是否已连接
  String? lastConnectedTime;

  DeviceInfo({
    required this.name,
    required this.macAddress,
    this.battery = 0,
    this.pressure = 0.0,
    this.isConnected = false,
    this.lastConnectedTime,
  });
}

class HomeState {
  final _title = "My Devices".obs;
  final RxList<DeviceInfo> connectedDevices = <DeviceInfo>[].obs;
  final RxList<DeviceInfo> historyDevices = <DeviceInfo>[].obs;
  final RxInt selectedIndex = (-1).obs;
}
```

### 10.4 设备卡片 UI（lib/pages/home/view.dart）

设备卡片根据连接状态显示不同颜色：
- 已连接：深蓝色背景 `#1A3A5C`
- 未连接：深灰色背景 `#2D2D3A`
- 真空值低于 0.48 bar 显示红色警告

### 10.5 服务 UUID 常量（lib/pages/utils/utils.dart）

```dart
class StaticData {
  static const SERVICE_UUID = "25AE1441-05D3-4C5B-8281-93D4E07420CF";
  static const SERVICE_UUID_LOWERCASE = "25ae1441-05d3-4c5b-8281-93d4e07420cf";
}
```

---

*报告生成时间：2026-04-08*
