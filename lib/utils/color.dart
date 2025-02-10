import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Colors.white;
  static const MaterialColor grey = Colors.grey;
  static const Color black = Colors.black;
  static const MaterialColor green = Colors.green;
  static const MaterialColor red = Colors.red;
  static const MaterialColor blue = Colors.blue;
  static const Color transparent = Colors.transparent;

  /// 根据主题返回对应的颜色
  static Color getThemeColor(BuildContext context,
      {Color? lightColor, Color? darkColor}) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? (lightColor ?? black)
        : (darkColor ?? white);
  }

  /// 获取主题相关的背景色
  static Color getThemeBackgroundColor(BuildContext context) {
    return getThemeColor(
      context,
      lightColor: grey[200],
      darkColor: grey[800],
    );
  }

  /// 获取主题相关的文本颜色
  static Color getThemeTextColor(BuildContext context) {
    return getThemeColor(
      context,
      lightColor: black,
      darkColor: white,
    );
  }
}
