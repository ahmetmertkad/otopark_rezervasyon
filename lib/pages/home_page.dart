// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'parking_list_page.dart';
import 'parking_lot_create_page.dart';
import 'rate_plan_list_page.dart'; // tarifeler için liste sayfası
import 'rate_plan_create_page.dart'; // tarifeler için ekleme sayfası
import 'package:provider/provider.dart';
import '../services/parking/parking_api.dart';
import '../state/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final api = context.read<ParkingApi>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            onPressed: auth.busy ? null : auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // --- OTOPARKLAR ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParkingListPage()),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Otoparkları Listele'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ParkingLotCreatePage(
                          api: api,
                          onCreated: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Otopark eklendi')),
                            );
                          },
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Otopark Ekle'),
            ),

            // --- TARİFELER ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => RatePlanListPage(api: api), // <-- düzeltildi
                  ),
                );
              },
              icon: const Icon(Icons.price_change),
              label: const Text('Tarifeleri Listele'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => RatePlanCreatePage(
                          api: api, // <-- düzeltildi
                          initialLotId: 1, // <-- parametre adı düzeltildi
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.add_card),
              label: const Text('Tarife Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
