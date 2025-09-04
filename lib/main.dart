// lib/main.dart
import 'package:flutter/material.dart';
import 'package:otopark_rezervasyon/app.dart'; // ✅ AppRoot burada
import 'package:otopark_rezervasyon/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Emülatör (Android) için 10.0.2.2, iOS sim için 127.0.0.1 kullan.
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final config = await AppConfig.init(baseUrl: baseUrl);
  runApp(AppRoot(config: config));
}
