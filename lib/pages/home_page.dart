import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            onPressed: () => auth.doLogout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
          ),
        ],
      ),
      body: const Center(
        child: Text('Hoş geldin! (Buraya rezervasyon ekranları gelecek)'),
      ),
    );
  }
}
