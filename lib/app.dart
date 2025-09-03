import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'state/auth_state.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

class AppRoot extends StatefulWidget {
  final AppConfig config;
  const AppRoot({super.key, required this.config});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    // bootstrap, provider yaratıldıktan hemen sonra çağrılacak
    // (addPostFrameCallback içinde)
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(
          create:
              (_) => AuthState(widget.config.authApi, widget.config.storage),
        ),
      ],
      child: Builder(
        builder: (context) {
          // bootstrap'i ilk frame'de tetikle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final auth = context.read<AuthState>();
            if (auth.loading) auth.bootstrap();
          });

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Otopark Rezervasyon',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const _RootSwitcher(),
          );
        },
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
    return const AirportParkingLoginPage();
  }
}
