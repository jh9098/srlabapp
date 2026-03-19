import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'features/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SrLabApp(config: AppConfig.fromEnvironment()));
}
