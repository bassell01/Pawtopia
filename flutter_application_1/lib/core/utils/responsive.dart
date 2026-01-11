import 'package:flutter/material.dart';

class R {
  static Size size(BuildContext c) => MediaQuery.sizeOf(c);
  static double w(BuildContext c, double v) => size(c).width * v;
  static double h(BuildContext c, double v) => size(c).height * v;

  /// scale based on shortest side (good for font/padding)
  static double s(BuildContext c, double v) =>
      (size(c).shortestSide / 390.0) * v; // 390 reference width

  static bool isSmall(BuildContext c) => size(c).width < 360;
  static bool isTablet(BuildContext c) => size(c).shortestSide >= 600;
}
