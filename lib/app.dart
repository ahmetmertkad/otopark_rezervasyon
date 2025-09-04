import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'state/auth_state.dart';

// pages
import 'pages/splash_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

// services
import 'services/parking/parking_api.dart';

class AppRoot extends StatelessWidget {
  final AppConfig config;
  const AppRoot({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(
          // <<< bootstrap'ı burada tetikliyoruz
          create: (_) => AuthState(config.authApi, config.storage)..bootstrap(),
        ),
        Provider<ParkingApi>.value(value: config.parkingApi),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Otopark Rezervasyon',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const _RootSwitcher(),
      ),
    );
  }
}

class _RootSwitcher extends StatelessWidget {
  const _RootSwitcher();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.loading) return const SplashPage();
    if (auth.authed) return const HomePage();

    return AirportParkingLoginPage(
      busy: auth.busy,
      errorText: auth.errorText,
      onLogin: (u, p) => auth.login(u, p),
    );
  }
}
