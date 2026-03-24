class AppBreakpoints {
  static const double veryNarrow = 360;
  static const double narrow = 400;

  static bool isVeryNarrow(double width) => width < veryNarrow;
  static bool isNarrow(double width) => width < narrow;
}
