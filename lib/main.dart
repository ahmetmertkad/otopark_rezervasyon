import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Emülatör için DRF varsayılanı (Android: 10.0.2.2, iOS sim: localhost)
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final config = await AppConfig.init(baseUrl: baseUrl);

  runApp(AppRoot(config: config));
}
