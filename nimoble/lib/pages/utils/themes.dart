import 'package:flutter/cupertino.dart';

class Themes {
  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xFF191919),
    barBackgroundColor: Color(0xFF191919),
    primaryColor: Color(0xFF7776FF),
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF202124),
      ),
      actionTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  /// 默认分割线的宽度0.5
  static const double defaultLineWidth05 = 0.5;

  /// 默认分割线的宽度1.0
  static const double defaultLineWidth10 = 1.0;

  /// 默认分割线的颜色
  static const Color defaultLineColor = ThemeColors.FFB7BDCB;

  /// 默认圆角半径
  static const double defaultRadius = 4;

  /// 默认警示红色
  static const Color defaultRedColor = Color(0xFFFF2500);

  /// 超链接颜色
  static const Color linkColor = Color(0xFF7776FF);

  /// 按钮禁用颜色
  static const Color filledButtonDisabledColor = Color(0xFFA5B2FF);

  static const TextStyle fontSize10FontWeight400 =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w400);

  static const TextStyle fontSize11FontWeight400 =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400);

  static const TextStyle fontSize12FontWeight400 =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400);

  static const TextStyle fontSize12FontWeight500 =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  static const TextStyle fontSize15FontWeightNormal =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

  static const TextStyle fontSize12FontWeightNormal =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  static const TextStyle fontSize14FontWeight400 =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  static const TextStyle fontSize14FontWeight500 =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

  static const TextStyle fontSize14FontWeightMedium =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w800);

  static const TextStyle fontSize24FontWeight500 =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w500);

  static const TextStyle fontSize24FontWeight800 =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w800);

  static const TextStyle fontSize15FontWeightMedium =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w800);

  static const TextStyle fontSize16FontWeight400 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  static const TextStyle fontSize16FontWeight500 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

  static const TextStyle fontSize16FontWeight600 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  static const TextStyle fontSize16FontWeight800 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

  static const TextStyle fontSize18FontWeightMedium =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w800);

  static const TextStyle fontSize20FontWeightMedium =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w800);

  static const TextStyle fontSize22FontWeightMedium =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800);

  static const TextStyle fontSize30FontWeightMedium =
      TextStyle(fontSize: 30, fontWeight: FontWeight.w800);

  static const TextStyle fontSize32FontWeight500 =
      TextStyle(fontSize: 32, fontWeight: FontWeight.w500);

  static const TextStyle fontSize36FontWeightMedium =
      TextStyle(fontSize: 36, fontWeight: FontWeight.w800);

  static const BorderRadius buttonBorderRadius =
      BorderRadius.all(Radius.circular(defaultRadius));
}

class ThemeColors {
  static const Color FFB7BDCB = Color(0xFFB7BDCB);
  static const Color FF727985 = Color(0xFF727985);
}
