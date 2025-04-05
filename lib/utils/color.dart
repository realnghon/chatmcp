import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Colors.white;
  static const MaterialColor grey = Colors.grey;
  static const Color black = Colors.black;
  static const MaterialColor green = Colors.green;
  static const MaterialColor red = Colors.red;
  static const MaterialColor blue = Colors.blue;
  static const Color transparent = Colors.transparent;

  /// Returns the corresponding color based on the theme
  static Color getThemeColor(BuildContext context,
      {Color? lightColor, Color? darkColor}) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? (lightColor ?? black)
        : (darkColor ?? white);
  }

  /// Gets the background color related to the theme
  static Color getThemeBackgroundColor(BuildContext context) {
    return getThemeColor(
      context,
      lightColor: grey[200],
      darkColor: grey[800],
    );
  }

  /// Gets the text color related to the theme
  static Color getThemeTextColor(BuildContext context) {
    return getThemeColor(
      context,
      lightColor: black,
      darkColor: white,
    );
  }
}
