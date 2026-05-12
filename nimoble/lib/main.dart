import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nimoble/routes/app_route.dart';

import 'pages/alarm/controller.dart';
import 'pages/settings/controller.dart';
import 'pages/utils/themes.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // 初始化 GetStorage
  Get.put(SettingsController(), permanent: true);
  await Get.put(AlarmController(), permanent: true).initNotifications();
  await ScreenUtil.ensureScreenSize();
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ScreenUtilInit 包装，确保 ScreenUtil 正确初始化
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetCupertinoApp(
      initialRoute: AppRoutes.HOME,
      locale: const Locale('en'),
      getPages: AppPages.pages,
      theme: Themes.lightTheme,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
      color: const Color(0xFF191919),
      title: "Avica",
      builder: (context, child) {
        final app = EasyLoading.init()(context, child);
        return ColoredBox(
          color: const Color(0xFF191919),
          child: app,
        );
      },
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      onDispose: () {},
      onReady: () async {},
        );
      },
    );
  }
}
