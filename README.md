# Avica / Nimoble

Avica 是一个基于 Flutter 开发的 BLE IoT 设备管理 App。项目工程名为
`nimoble`，主要用于扫描、连接和管理符合协议的蓝牙设备，并在 Home
设备列表和设备详情页实时展示设备电量、真空值和连接状态。

## 核心功能

- BLE 设备扫描：扫描页只展示未添加的新设备，并完成新设备首次连接。
- Home 设备管理：管理已添加设备的在线/离线状态、自动重连和实时数据。
- 实时数据展示：通过 BLE notify/indicate 接收电量和真空值，Home 列表与详情页同步刷新。
- 报警提示：低电量、低真空值触发报警样式和系统通知。
- 设备详情：展示设备主图、真空值仪表、电量、运行时间和设备信息。
- 设置页：支持压力单位、自动连接、报警通知等开关配置。

## 技术栈

- Flutter / Dart
- GetX：路由、依赖注入和状态管理
- GetStorage：本地轻量持久化
- flutter_blue_plus：BLE 扫描、连接、GATT 服务和 notify 数据接收
- flutter_local_notifications：本地系统通知
- flutter_screenutil：屏幕适配
- flutter_easyloading：Toast / Loading 提示

## 项目结构

```text
nimoble/
  lib/
    main.dart                  # App 入口
    r.dart                     # 图片资源路径常量
    routes/                    # GetX 路由配置
    pages/
      home/                    # Home 设备列表、已添加设备状态和 BLE 管理核心
      ble_module/              # 蓝牙扫描、新设备首次连接流程
      device_details/          # 设备详情页和真空值仪表
      alarm/                   # 报警判断和系统通知
      settings/                # 单位、自动连接、报警通知开关
      widgets/                 # 通用 BLE/GATT 展示组件
      utils/                   # 工具类、主题和扩展
  images/                      # App 图片资源
  android/                     # Android 平台配置
  ios/                         # iOS 平台配置
  pubspec.yaml                 # Flutter 依赖和资源声明
```

## 运行环境

- Dart SDK: `>=3.3.1 <4.0.0`
- Flutter: 使用项目当前 Flutter SDK 环境
- Android 真机优先：BLE 扫描、连接、通知和权限行为需要真机验证
- Android 权限：项目已声明蓝牙扫描、蓝牙连接、通知和震动权限

## 常用命令

进入项目目录：

```powershell
cd 项目根目录
```

安装依赖：

```powershell
flutter pub get
```

运行项目：

```powershell
flutter run
```

构建 Debug APK：

```powershell
flutter build apk --debug
```

构建 Release APK：

```powershell
flutter build apk --release
```

Release APK 默认输出位置：

```text
build\app\outputs\flutter-apk\app-release.apk
```

## BLE 业务约定

- 扫描页只负责扫描符合通信协议的新设备，并完成新设备首次连接。
- 已添加到 Home 的设备不再展示在扫描页。
- Home 是已添加设备的状态管理中心，负责在线/离线、自动重连和实时数据刷新。
- 电量和真空值只要通过 BLE notify 收到，就应尽快更新 Home 卡片和设备详情页。
- 连接状态以 BLE 连接事件和轻量链路探测为准，不使用电量/真空值是否变化来判断在线状态。

## 报警规则

- 低电量阈值：电量 `< 20%`。
- 低真空阈值：真空值 `< 0.48 Bar`。
- 设备在线且读到对应数据后，才参与报警判断。
- 报警状态会影响 Home 卡片样式和图标颜色。
- 系统通知支持 App 前台、后台和锁屏场景；前提是通知权限开启，且设置页 `Get alarm alerts` 未关闭。
- 同一设备同一报警类型持续存在时，不重复刷通知；恢复正常后再次进入报警状态才会再次通知。

## 开发注意事项

- 不要随意改动扫描页首次连接流程；扫描页和 Home 的职责要保持分离。
- 不要把业务数据是否变化当作连接状态判断依据。
- BLE 断开、重连、notify 订阅和 GATT 操作需要保持轻量，避免并发任务互相干扰。
- BLE 相关改动必须真机验证，模拟器无法覆盖真实蓝牙行为。
- UI 调整应尽量局部修改，避免影响报警样式、连接状态和数据展示链路。
- 临时测试代码如报警闪烁预览，应优先注释保留，确认不再需要后再删除。
