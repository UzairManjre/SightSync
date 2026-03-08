import 'package:flutter/material.dart';

/// A utility class that provides screen-relative scaling for fonts,
/// heights, and widths. Must be initialized once with a BuildContext.
class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;

  // These are the "design" dimensions (based on iPhone 14 / typical mockup)
  static const double _designWidth = 390.0;
  static const double _designHeight = 844.0;

  static void init(BuildContext context) {
    final media = MediaQuery.of(context);
    screenWidth = media.size.width;
    screenHeight = media.size.height;
  }

  /// Scale a width value relative to the design width
  static double w(double width) => (width / _designWidth) * screenWidth;

  /// Scale a height value relative to the design height
  static double h(double height) => (height / _designHeight) * screenHeight;

  /// Scale a font size relative to the design width
  static double sp(double fontSize) => (fontSize / _designWidth) * screenWidth;
}
