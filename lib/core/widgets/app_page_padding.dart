import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

class AppPagePadding extends StatelessWidget {
  const AppPagePadding({
    super.key,
    required this.child,
    this.top = 16,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        top,
        AppSpacing.pageHorizontal,
        bottom,
      ),
      child: child,
    );
  }
}
