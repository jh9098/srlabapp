import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppStickyBottomBar extends StatelessWidget {
  const AppStickyBottomBar({
    super.key,
    required this.child,
    this.elevation = 4,
  });

  final Widget child;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            10,
            AppSpacing.pageHorizontal,
            12,
          ),
          child: child,
        ),
      ),
    );
  }
}
