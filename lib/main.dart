import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SrLabApp(config: AppConfig.fromEnvironment()));
}
