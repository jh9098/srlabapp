import 'package:flutter/widgets.dart';

class AppSpacing {
  static const double pageHorizontal = 16;
  static const double sectionSmall = 12;
  static const double section = 16;
  static const double sectionLarge = 24;
  static const double bottomListPadding = 32;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: pageHorizontal);
  static const EdgeInsets pageWithTop = EdgeInsets.fromLTRB(pageHorizontal, 16, pageHorizontal, 0);
  static const EdgeInsets pageFull =
      EdgeInsets.fromLTRB(pageHorizontal, 16, pageHorizontal, bottomListPadding);
}
